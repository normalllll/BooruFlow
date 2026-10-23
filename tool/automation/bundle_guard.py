"""Reject production bundles before creating isolated profiles or processes."""
from pathlib import Path

DRIVER_MARKER = b'Set an explicit absolute BOORUFLOW_AUTOMATION_PROFILE'
FILE_RPC_MARKER = b'Explicit isolated profile required'


def require_automation_bundle(executable: Path, *, file_rpc: bool = False):
    data = executable.parent / 'data'
    kernel = data / 'flutter_assets/kernel_blob.bin'
    bundle = kernel if kernel.is_file() else data / 'app.so'
    marker = FILE_RPC_MARKER if file_rpc else DRIVER_MARKER
    if not bundle.is_file() or marker not in bundle.read_bytes():
        target = 'debug_window.dart (Debug) or release_video.dart (Release)' if file_rpc else 'main.dart'
        raise RuntimeError(
            f'Not an isolated automation bundle: {bundle}. '
            f'Reconfigure --target tool/automation/{target} before building.')
    return bundle
