"""Preflight tests use temporary fake bundles; no process is launched."""
from pathlib import Path
import tempfile
import unittest
from bundle_guard import require_automation_bundle, DRIVER_MARKER, FILE_RPC_MARKER


class BundleGuardTest(unittest.TestCase):
    def test_missing_or_production_bundle_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            exe = Path(directory) / 'booruflow.exe'
            with self.assertRaises(RuntimeError):
                require_automation_bundle(exe)
            data = exe.parent / 'data'
            data.mkdir()
            (data / 'app.so').write_bytes(b'production entrypoint')
            with self.assertRaises(RuntimeError):
                require_automation_bundle(exe, file_rpc=True)

    def test_driver_and_file_rpc_targets_are_not_interchangeable(self):
        with tempfile.TemporaryDirectory() as directory:
            exe = Path(directory) / 'booruflow.exe'
            bundle = exe.parent / 'data/flutter_assets/kernel_blob.bin'
            bundle.parent.mkdir(parents=True)
            bundle.write_bytes(DRIVER_MARKER)
            self.assertEqual(require_automation_bundle(exe), bundle)
            with self.assertRaises(RuntimeError):
                require_automation_bundle(exe, file_rpc=True)
            bundle.write_bytes(FILE_RPC_MARKER)
            self.assertEqual(require_automation_bundle(exe, file_rpc=True), bundle)
            with self.assertRaises(RuntimeError):
                require_automation_bundle(exe)

    def test_debug_kernel_takes_precedence_over_stale_aot(self):
        with tempfile.TemporaryDirectory() as directory:
            exe = Path(directory) / 'booruflow.exe'
            kernel = exe.parent / 'data/flutter_assets/kernel_blob.bin'
            kernel.parent.mkdir(parents=True)
            kernel.write_bytes(b'production debug entrypoint')
            (exe.parent / 'data/app.so').write_bytes(FILE_RPC_MARKER)
            with self.assertRaises(RuntimeError):
                require_automation_bundle(exe, file_rpc=True)


if __name__ == '__main__':
    unittest.main()
