"""Native-capture readiness and Windows structure layout regression checks."""
import ctypes
import unittest
from capture_environment import CaptureEnvironment, SessionInfoEx, SessionLevel1


class CaptureEnvironmentTest(unittest.TestCase):
    def check_state(self, display, lock='unlocked', connection=0):
        environment = object.__new__(CaptureEnvironment)
        environment.snapshot = lambda: {'displayState': display, 'lockState': lock,
            'connectionState': connection}
        return environment.require_ready()

    def test_visible_unlocked_active_session_is_ready(self):
        for display in ('on', 'dim'):
            with self.subTest(display=display):
                self.assertEqual(self.check_state(display)['displayState'], display)

    def test_ineligible_session_does_not_attempt_native_capture(self):
        for display, lock, connection in (
            ('off', 'unlocked', 0), ('unknown', 'unlocked', 0),
            ('on', 'locked', 0), ('on', 'unknown', 0), ('on', 'unlocked', 4)):
            with self.subTest(display=display, lock=lock, connection=connection):
                with self.assertRaisesRegex(RuntimeError, 'environment is not ready'):
                    self.check_state(display, lock, connection)

    def test_wts_union_keeps_native_alignment(self):
        self.assertEqual(SessionInfoEx.data.offset, 8)
        self.assertEqual(SessionLevel1.session_flags.offset, 8)
        self.assertEqual(ctypes.sizeof(ctypes.c_wchar), 2)

class _Environment:
    def __init__(self, state='on', lock='unlocked'):
        self.state, self.lock, self.wakes = state, lock, 0
        self.transitions = []
    def __enter__(self): return self
    def __exit__(self, *args): pass
    def snapshot(self):
        return {'displayState': self.state, 'lockState': self.lock,
            'connectionState': 0, 'displayTransitions': list(self.transitions)}
    def require_ready(self):
        if self.state != 'on' or self.lock != 'unlocked':
            raise RuntimeError('environment not ready')
        return self.snapshot()
    def wake_display_once(self):
        self.wakes += 1
        self.state = 'on'
        return {'method': 'fake one-shot wake'}


class NativeCaptureRetryTest(unittest.TestCase):
    def test_success_does_not_wake(self):
        from unittest.mock import patch
        from capture_environment import run_native_capture
        environment = _Environment()
        with patch('capture_environment.CaptureEnvironment', return_value=environment):
            result = run_native_capture(lambda: {'probeMatched': True})
        self.assertTrue(result['probeMatched'])
        self.assertEqual(environment.wakes, 0)
        self.assertEqual(result['failedAttempts'], [])

    def test_off_preflight_wakes_once_then_captures(self):
        from unittest.mock import patch
        from capture_environment import run_native_capture
        environment = _Environment(state='off')
        captures = []
        with patch('capture_environment.CaptureEnvironment', return_value=environment):
            result = run_native_capture(lambda: captures.append('fresh probe') or {})
        self.assertEqual(environment.wakes, 1)
        self.assertEqual(captures, ['fresh probe'])
        self.assertEqual(len(result['failedAttempts']), 1)

    def test_native_failure_observing_off_retries_with_a_new_action(self):
        from unittest.mock import patch
        from capture_environment import run_native_capture
        environment = _Environment()
        captures = []
        def capture():
            captures.append('fresh probe')
            if len(captures) == 1:
                environment.state = 'off'
                raise RuntimeError('presented frame timed out')
            return {}
        with patch('capture_environment.CaptureEnvironment', return_value=environment):
            result = run_native_capture(capture)
        self.assertEqual(environment.wakes, 1)
        self.assertEqual(len(captures), 2)
        self.assertEqual(len(result['failedAttempts']), 1)

    def test_on_failure_and_locked_session_are_not_retried(self):
        from unittest.mock import patch
        from capture_environment import run_native_capture
        for environment in [_Environment(), _Environment(lock='locked')]:
            with self.subTest(lock=environment.lock):
                with patch('capture_environment.CaptureEnvironment', return_value=environment):
                    with self.assertRaisesRegex(RuntimeError, 'Native capture failed'):
                        run_native_capture(lambda: (_ for _ in ()).throw(RuntimeError('failure')))
                self.assertEqual(environment.wakes, 0)


if __name__ == '__main__':
    unittest.main()
