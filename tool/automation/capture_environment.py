"""Windows capture-state observations and the user-authorized one-shot display wake."""
from __future__ import annotations
import ctypes
from ctypes import wintypes
import threading
import time
from datetime import datetime


class Guid(ctypes.Structure):
    _fields_ = [('data1', wintypes.DWORD), ('data2', wintypes.WORD),
        ('data3', wintypes.WORD), ('data4', ctypes.c_ubyte * 8)]

    @classmethod
    def parse(cls, value):
        import uuid
        return cls.from_buffer_copy(uuid.UUID(value).bytes_le)


class SessionLevel1(ctypes.Structure):
    _fields_ = [('session_id', wintypes.DWORD), ('connection_state', ctypes.c_int),
        ('session_flags', wintypes.LONG), ('station', wintypes.WCHAR * 33),
        ('user', wintypes.WCHAR * 21), ('domain', wintypes.WCHAR * 18),
        ('logon_time', ctypes.c_longlong), ('connect_time', ctypes.c_longlong),
        ('disconnect_time', ctypes.c_longlong), ('last_input_time', ctypes.c_longlong),
        ('current_time', ctypes.c_longlong), ('incoming_bytes', wintypes.DWORD),
        ('outgoing_bytes', wintypes.DWORD), ('incoming_frames', wintypes.DWORD),
        ('outgoing_frames', wintypes.DWORD), ('incoming_compressed', wintypes.DWORD),
        ('outgoing_compressed', wintypes.DWORD)]


class SessionInfoEx(ctypes.Structure):
    _fields_ = [('level', wintypes.DWORD), ('data', SessionLevel1)]


def session_snapshot():
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    wts = ctypes.WinDLL('wtsapi32', use_last_error=True)
    kernel.GetCurrentProcessId.restype = wintypes.DWORD
    kernel.ProcessIdToSessionId.argtypes = [wintypes.DWORD, ctypes.POINTER(wintypes.DWORD)]
    kernel.WTSGetActiveConsoleSessionId.restype = wintypes.DWORD
    wts.WTSQuerySessionInformationW.argtypes = [wintypes.HANDLE, wintypes.DWORD,
        ctypes.c_int, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(wintypes.DWORD)]
    wts.WTSQuerySessionInformationW.restype = wintypes.BOOL
    wts.WTSFreeMemory.argtypes = [ctypes.c_void_p]
    session_id = wintypes.DWORD()
    if not kernel.ProcessIdToSessionId(kernel.GetCurrentProcessId(), ctypes.byref(session_id)):
        raise ctypes.WinError(ctypes.get_last_error())
    data, size = ctypes.c_void_p(), wintypes.DWORD()
    # WTSSessionInfoEx = 25. The union is aligned to 8, not DWORD offset 4.
    if not wts.WTSQuerySessionInformationW(None, session_id, 25, ctypes.byref(data), ctypes.byref(size)):
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        if size.value < ctypes.sizeof(SessionInfoEx):
            raise RuntimeError('Incomplete WTSSessionInfoEx response')
        info = ctypes.cast(data, ctypes.POINTER(SessionInfoEx)).contents
        if info.level != 1:
            raise RuntimeError('Unexpected WTS session information level')
        return {'processSessionId': session_id.value,
            'activeConsoleSessionId': kernel.WTSGetActiveConsoleSessionId(),
            'connectionState': info.data.connection_state,
            'lockState': {0: 'locked', 1: 'unlocked'}.get(info.data.session_flags, 'unknown')}
    finally:
        wts.WTSFreeMemory(data)


class CaptureEnvironment:
    """Observe display state without waking, locking or activating anything.

    PowerSettingRegisterNotification immediately delivers the current value.
    Keep registration alive across capture so a display-off transition is retained.
    Observation makes no power request. The separate wake method is called only
    after a failed native operation observes display-off, as the user authorized.
    """
    def __init__(self):
        self._power = ctypes.WinDLL('powrprof', use_last_error=True)
        self._callback_type = ctypes.WINFUNCTYPE(wintypes.ULONG, ctypes.c_void_p,
            wintypes.ULONG, ctypes.c_void_p)
        class Subscribe(ctypes.Structure):
            _fields_ = [('callback', self._callback_type), ('context', ctypes.c_void_p)]
        self._subscribe_type = Subscribe
        self._power.PowerSettingRegisterNotification.argtypes = [ctypes.POINTER(Guid),
            wintypes.DWORD, ctypes.POINTER(Subscribe), ctypes.POINTER(wintypes.HANDLE)]
        self._power.PowerSettingRegisterNotification.restype = wintypes.DWORD
        self._power.PowerSettingUnregisterNotification.argtypes = [wintypes.HANDLE]
        self._power.PowerSettingUnregisterNotification.restype = wintypes.DWORD
        self._handle = wintypes.HANDLE()
        self._event = threading.Event()
        self._state = 'unknown'
        self.transitions = []
        self._wake_requested = False
        self._callback = self._callback_type(self._changed)
        self._subscription = Subscribe(self._callback, None)

    def _changed(self, context, kind, setting):
        if kind == 0x8013 and setting:  # PBT_POWERSETTINGCHANGE
            length = wintypes.DWORD.from_address(setting + 16).value
            if length == ctypes.sizeof(wintypes.DWORD):
                value = wintypes.DWORD.from_address(setting + 20).value
                self._state = {0: 'off', 1: 'on', 2: 'dim'}.get(value, 'unknown')
                self.transitions.append({'at': datetime.now().astimezone().isoformat(),
                    'display': self._state})
                self._event.set()
        return 0

    def __enter__(self):
        # User-mode apps observe their own session, not the global console alone.
        guid = Guid.parse('2B84C20E-AD23-4DDF-93DB-05FFBD7EFCA5')
        code = self._power.PowerSettingRegisterNotification(ctypes.byref(guid), 2,
            ctypes.byref(self._subscription), ctypes.byref(self._handle))
        if code:
            raise ctypes.WinError(code)
        self._event.wait(2)
        return self

    def snapshot(self):
        return {'at': datetime.now().astimezone().isoformat(),
            'displayState': self._state, **session_snapshot(),
            'displayTransitions': list(self.transitions)}

    def require_ready(self):
        value = self.snapshot()
        if value['displayState'] not in ('on', 'dim') or value['lockState'] != 'unlocked' or value['connectionState'] != 0:
            raise RuntimeError(f'Native capture environment is not ready: {value}')
        return value

    def wake_display_once(self):
        # The user authorized this only after failure with an observed off
        # display. Never unlock, inject input, activate a window or keep awake.
        before = self.snapshot()
        if before['displayState'] != 'off' or self._wake_requested:
            raise RuntimeError(f'Display wake requires one observed-off failure: {before}')
        self._wake_requested = True
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        kernel.SetThreadExecutionState.argtypes = [wintypes.DWORD]
        kernel.SetThreadExecutionState.restype = wintypes.DWORD
        # ES_DISPLAY_REQUIRED only. Without ES_CONTINUOUS this resets the idle
        # timer once; it creates no persistent sleep/display inhibition.
        if not kernel.SetThreadExecutionState(0x00000002):
            raise ctypes.WinError(ctypes.get_last_error())
        deadline = time.monotonic() + 3
        while self._state == 'off' and time.monotonic() < deadline:
            time.sleep(.05)
        return {'before': before, 'after': self.snapshot(), 'method': 'ES_DISPLAY_REQUIRED once'}

    def __exit__(self, kind, value, traceback):
        if self._handle:
            code = self._power.PowerSettingUnregisterNotification(self._handle)
            self._handle = wintypes.HANDLE()
            if code and kind is None:
                raise ctypes.WinError(code)


def inspect_environment():
    with CaptureEnvironment() as environment:
        return environment.snapshot()


def run_native_capture(action):
    """One normal attempt; wake/retry once only when failure observes off.

    The action must prepare a new presentation probe every time it is called.
    Unknown, disconnected or locked sessions are not bypassed. Native failure
    with an already-on display does not trigger any wake or blind retry.
    """
    with CaptureEnvironment() as environment:
        failures = []
        wake = None
        for attempt in range(2):
            before = environment.snapshot()
            transition_count = len(before['displayTransitions'])
            try:
                environment.require_ready()
                result = action()
                after = environment.require_ready()
                if any(item['display'] == 'off' for item in after['displayTransitions'][transition_count:]):
                    raise RuntimeError('Display turned off during native capture')
                return {**result, 'environmentBefore': before, 'environmentAfter': after,
                    'failedAttempts': failures, 'displayWake': wake}
            except Exception as error:
                after = environment.snapshot()
                failures.append({'error': str(error), 'environmentBefore': before,
                    'environmentAfter': after})
                if attempt == 0 and after['displayState'] == 'off':
                    try:
                        wake = environment.wake_display_once()
                    except Exception as wake_error:
                        raise RuntimeError(f'Native capture failed; attempts={failures}; one-shot display wake failed: {wake_error}') from wake_error
                    continue
                raise RuntimeError(f'Native capture failed; attempts={failures}; displayWake={wake}') from error
