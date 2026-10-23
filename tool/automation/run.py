"""BooruFlow-only background Driver/WGC automation. Never sends desktop input."""
from __future__ import annotations
import argparse
import ctypes
from ctypes import wintypes
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
import time

from capture_environment import inspect_environment, run_native_capture
from bundle_guard import require_automation_bundle

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'build/ui-automation'
SESSION = WORK / 'session.json'  # Control state, never a screenshot manifest.
CONFIGURATION = os.environ.get('BOORUFLOW_AUTOMATION_CONFIGURATION', 'Debug')
if CONFIGURATION not in ('Debug', 'Profile'):
    raise ValueError('Automation configuration must be Debug or Profile')
EXE = ROOT / f'build/automation-windows/x64/runner/{CONFIGURATION}/booruflow.exe'
HELPER = ROOT / 'build/flutter-ui-automation/window-capture/Release/window_capture.exe'
SKILL = Path(os.environ.get('FLUTTER_UI_AUTOMATION_SKILL',
    str(Path.home() / '.codex/skills/flutter-ui-automation')))
DART = Path(os.environ.get('FLUTTER_ROOT', 'V:/SDK/flutter')) / 'bin/cache/dart-sdk/bin/dart.exe'
NO_WINDOW = 0x08000000


def run(args, timeout=45):
    result = subprocess.run([str(arg) for arg in args], cwd=ROOT, capture_output=True,
        text=True, encoding='utf-8', errors='replace', timeout=timeout,
        creationflags=NO_WINDOW)
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {result.stderr[-3000:]}\n{result.stdout[-3000:]}')
    return result.stdout


def session():
    data = json.loads(SESSION.read_text(encoding='utf-8'))
    # Check the exact executable before attaching, capturing or closing a PID.
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel.OpenProcess.restype = wintypes.HANDLE
    kernel.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD,
        wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)]
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    handle = kernel.OpenProcess(0x1000, False, data['pid'])
    if not handle:
        raise RuntimeError('Test process is no longer running')
    try:
        path, size = ctypes.create_unicode_buffer(32768), wintypes.DWORD(32768)
        if not kernel.QueryFullProcessImageNameW(handle, 0, path, ctypes.byref(size)):
            raise ctypes.WinError(ctypes.get_last_error())
        if Path(path.value).resolve() != EXE.resolve():
            raise RuntimeError('PID was reused by a different executable; refusing access')
    finally:
        kernel.CloseHandle(handle)
    return data


def drive(action, *args):
    result = run([DART, '--disable-dart-dev', '--packages='+str(ROOT/'.dart_tool/package_config.json'),
        'tool/automation/driver.dart', session()['vmUri'], action, *args],
        timeout=(int(args[1])/int(args[2])+25 if action=='app-record' else 45))
    if action in ('tree', 'semantics'):
        return result
    for line in reversed(result.splitlines()):
        try:
            return json.loads(line)
        except json.JSONDecodeError:
            pass
    raise RuntimeError(f'No Driver result: {result[-2000:]}')


def request(command, **args):
    return drive('request', json.dumps({'command': command, **args}))


def start(preview_board=None):
    if SESSION.exists():
        # A live but unresponsive owned process is an error, not permission to
        # launch a second owner. Only a dead or unrelated stale PID is ignored.
        try:
            session()
        except (OSError, RuntimeError):
            pass
        else:
            if session().get('previewBoard') != preview_board:
                raise RuntimeError('Close the current isolated session before changing preview board')
            return request('state')
    if not EXE.is_file() or not HELPER.is_file():
        raise RuntimeError('Build the dedicated app and native capture helper first')
    require_automation_bundle(EXE)
    WORK.mkdir(parents=True, exist_ok=True)
    profile = WORK / ('profile-' + str(time.time_ns()))
    profile.mkdir()
    env = os.environ.copy()
    env['BOORUFLOW_AUTOMATION_PROFILE'] = str(profile)
    env['BOORUFLOW_AUTOMATION_FIXTURES'] = str(ROOT / 'test' / 'fixtures' / 'media')
    if preview_board is not None:
        if not re.fullmatch(r'R17|R19|R19AA|R19SE|R19SC|R20MC|Main|[BQDLPFWM]\d{2}', preview_board):
            raise ValueError('Invalid preview board')
        env['BOORUFLOW_PREVIEW_BOARD'] = preview_board
    switches = ['enable-dart-profiling=true', 'enable-checked-mode=true', 'verify-entry-points=true', 'vm-service-port=0']
    env['FLUTTER_ENGINE_SWITCHES'] = str(len(switches))
    for index, value in enumerate(switches, 1):
        env[f'FLUTTER_ENGINE_SWITCH_{index}'] = value
    log_path = WORK / 'app.log'
    with log_path.open('wb') as log:
        process = subprocess.Popen([str(EXE)], cwd=EXE.parent, env=env,
            stdin=subprocess.DEVNULL, stdout=log, stderr=log, creationflags=NO_WINDOW)
    data = {'pid': process.pid, 'profile': str(profile), 'vmUri': None, 'previewBoard': preview_board}
    SESSION.write_text(json.dumps(data), encoding='utf-8')
    deadline = time.monotonic() + 50
    while time.monotonic() < deadline:
        log = log_path.read_text(encoding='utf-8', errors='replace')
        match = re.search(r'The Dart VM service is listening on (http://\S+)', log, re.I)
        if match:
            data['vmUri'] = match.group(1)
            SESSION.write_text(json.dumps(data), encoding='utf-8')
            try:
                state = request('state')
                if state['native']['pid'] != process.pid:
                    raise RuntimeError('Driver native identity does not match spawned process')
                return state
            except RuntimeError:
                if process.poll() is not None:
                    raise
        if process.poll() is not None:
            raise RuntimeError(f'Test app exited {process.returncode}: {log[-4000:]}')
        time.sleep(.25)
    raise TimeoutError(f'VM/Driver startup timed out: {log_path}')


def close():
    """Wait for the owned process to exit before allocating another profile."""
    result = request('close')
    deadline = time.monotonic() + 6
    while time.monotonic() < deadline:
        try:
            session()
        except (OSError, RuntimeError):
            return result
        time.sleep(.1)
    raise RuntimeError('Owned window did not finish closing; refusing a second instance')


def native_module():
    scripts = SKILL / 'scripts'
    if not scripts.is_dir():
        raise RuntimeError('Complete flutter-ui-automation skill package is missing')
    sys.path.insert(0, str(scripts))
    spec = importlib.util.spec_from_file_location('window_capture', scripts / 'window_capture.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def prepare():
    probe = request('prepareCapture')
    status = probe['native']
    if status['pid'] != session()['pid'] or status['isForeground'] or status['hasNativeFocus']:
        raise RuntimeError('Expected the owned background test window without native focus')
    if not status['visible'] or status['minimized']:
        raise RuntimeError('Capture requires visible, non-minimized HWND; it will not be raised')
    return probe


def pair(path):
    path = Path(path).resolve()
    def capture():
        # Every attempt, including a wake retry, receives a fresh native fence.
        probe = prepare()
        app = drive('app-shot', str(path.with_name(path.stem + '-app.png')))
        native = native_module().capture_png(path.with_name(path.stem + '-window.png'),
            hwnd=probe['native']['hwnd'], process_id=probe['native']['pid'],
            helper=HELPER, backend='wgc', probe=probe)
        if not native['probeMatched'] or native['isForeground']:
            raise RuntimeError('Native presentation fence or background requirement failed')
        return {'app': app, 'native': native}
    return run_native_capture(capture)


def ffmpeg(args, timeout=60):
    return run(['ffmpeg', '-hide_banner', '-v', 'error', *args], timeout=timeout)


def hashes(text):
    return [line.split(',')[-1].strip() for line in text.splitlines()
            if line and not line.startswith('#')]


def finalize(path, expected, width, height):
    master = path.with_suffix('.lossless.mkv')
    # Fidelity checking is in memory; no frame-hash/manifest files are created.
    actual = hashes(ffmpeg(['-i', master, '-c:v', 'rawvideo', '-pix_fmt', 'bgra', '-f', 'framemd5', '-']))
    if not expected or actual != expected:
        raise RuntimeError('Decoded FFV1 pixels differ from the original BGRA frames')
    ffmpeg(['-y', '-i', master, '-an', '-vf', 'pad=ceil(iw/2)*2:ceil(ih/2)*2',
        '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '18', '-pix_fmt', 'yuv420p',
        '-movflags', '+faststart', path])
    return {'master': str(master), 'preview': str(path), 'previewIsLossy': True,
        'width': width, 'height': height, 'verifiedFrames': len(actual)}


def record_window(path, seconds, fps):
    return run_native_capture(lambda: _record_window(path, seconds, fps))


def _record_window(path, seconds, fps):
    path = Path(path).resolve(); path.parent.mkdir(parents=True, exist_ok=True)
    probe = prepare(); module = native_module()
    module.validate_target(probe['native']['hwnd'], probe['native']['pid'])
    capture = subprocess.Popen([str(HELPER), '--hwnd', str(probe['native']['hwnd']),
        '--backend', 'wgc', '--stream', '--seconds', str(seconds), '--fps', str(fps),
        *module.probe_arguments(probe)], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        creationflags=NO_WINDOW)
    encoder = None
    timer = threading.Timer(seconds + 25, capture.kill); timer.start()
    try:
        first = capture.stderr.readline().decode('utf-8')
        ready = json.loads(first)
        if not ready.get('ready') or not ready.get('probeMatched'):
            raise RuntimeError(f'WGC did not present requested probe: {first}')
        width, height = ready['width'], ready['height']
        encoder = subprocess.Popen(['ffmpeg', '-hide_banner', '-v', 'error', '-y',
            '-f', 'rawvideo', '-pixel_format', 'bgra', '-video_size', f'{width}x{height}',
            '-framerate', str(fps), '-i', 'pipe:0', '-an', '-c:v', 'ffv1', '-level', '3',
            '-pix_fmt', 'bgra', str(path.with_suffix('.lossless.mkv'))],
            stdin=subprocess.PIPE, stderr=subprocess.PIPE, creationflags=NO_WINDOW)
        expected=[]; frame_size=width*height*4
        while True:
            frame = capture.stdout.read(frame_size)
            if not frame: break
            if len(frame) != frame_size: raise RuntimeError('Incomplete native frame')
            expected.append(hashlib.md5(frame).hexdigest())
            encoder.stdin.write(frame)
        encoder.stdin.close(); encoder.stdin=None
        _, error=encoder.communicate(timeout=20)
        notes=capture.stderr.read().decode('utf-8'); code=capture.wait(timeout=15)
        if code or encoder.returncode:
            raise RuntimeError(f'Capture/encode failed: {notes} {error.decode(errors="replace")}')
        complete=json.loads(notes.strip().splitlines()[-1])
        if complete['foregroundSamples'] or complete['frames'] != len(expected):
            raise RuntimeError(f'Recording foreground or frame count check failed: native={complete}, decodedInputFrames={len(expected)}')
        return {**ready, **complete, **finalize(path, expected, width, height)}
    finally:
        timer.cancel()
        for process in (capture,encoder):
            if process is not None and process.poll() is None:
                process.kill(); process.wait()


def record_app(path, seconds, fps):
    path=Path(path).resolve(); path.parent.mkdir(parents=True, exist_ok=True)
    frames=path.with_name(path.stem+'-frames'); frames.mkdir(exist_ok=False)
    prepare()
    sampled=drive('app-record', str(frames), str(seconds*fps), str(fps))
    elapsed=sampled['elapsedSeconds']
    source=hashes(ffmpeg(['-framerate', str(fps), '-i', frames/'%04d.png',
        '-c:v', 'rawvideo', '-pix_fmt', 'bgra', '-f', 'framemd5', '-']))
    ffmpeg(['-y', '-framerate', str(fps), '-i', frames/'%04d.png',
        '-c:v', 'ffv1', '-level', '3', '-pix_fmt', 'bgra', path.with_suffix('.lossless.mkv')])
    import struct
    with (frames/'0000.png').open('rb') as first:
        header=first.read(24)
    width,height=struct.unpack('>II',header[16:24])
    result = finalize(path,source,width,height)
    if elapsed > seconds * 1.1:
        raise RuntimeError(f'App recording missed requested cadence: {elapsed:.3f}s for {seconds}s; original frames retained')
    return {**result, 'originalFrames': str(frames),
        'samplingElapsedSeconds': elapsed, 'requestedFps': fps,
        'sampleTimesMicroseconds': sampled['sampleTimesMicroseconds'],
        'cadenceMet': elapsed <= seconds * 1.1}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['start','stop','state','environment','drive','request','pair','record-window','record-app'])
    parser.add_argument('args', nargs='*')
    args=parser.parse_args()
    if args.action=='start': result=start(args.args[0] if args.args else None)
    elif args.action=='drive': result=drive(*args.args)
    elif args.action=='state': result=request('state')
    elif args.action=='environment': result=inspect_environment()
    elif args.action=='request':
        data=json.loads(args.args[0]); result=request(**data)
    elif args.action=='pair': result=pair(args.args[0])
    elif args.action.startswith('record-'):
        seconds=int(args.args[1]); fps=int(args.args[2])
        if not 1<=seconds<=120 or not 1<=fps<=60: raise ValueError('Invalid duration/rate')
        result=(record_window if args.action=='record-window' else record_app)(args.args[0],seconds,fps)
    else:
        result=close()
    print(result if isinstance(result,str) else json.dumps(result,ensure_ascii=False))

if __name__=='__main__':
    try: main()
    except Exception as error:
        print(f'ERROR: {error}',file=sys.stderr); sys.exit(1)
