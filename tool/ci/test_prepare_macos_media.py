"""Exercise CI retry and failure handling without external downloads."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import json
import shutil
import subprocess
import tempfile
import threading
import unittest


SCRIPT = Path(__file__).with_name("prepare_macos_media.sh")
HEADERS = ("client.h", "render.h", "render_gl.h", "stream_cb.h")


class MediaPreparationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="macos media ci ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        script = self.root / "tool/ci/prepare_macos_media.sh"
        script.parent.mkdir(parents=True)
        shutil.copyfile(SCRIPT, script)
        self.script = script
        plugins = self.root / "pub cache"
        self.video = plugins / "media_kit_video"
        self.libraries = plugins / "media_kit_libs_macos_video/macos"
        (self.video / "common/darwin").mkdir(parents=True)
        self.libraries.mkdir(parents=True)
        config = self.root / ".dart_tool/package_config.json"
        config.parent.mkdir()
        config.write_text(json.dumps({"configVersion": 2, "packages": [
            {"name": "media_kit_video", "rootUri": self.video.as_uri() + "/"},
            {"name": "media_kit_libs_macos_video", "rootUri": self.libraries.parent.as_uri() + "/"},
        ]}))
        self.write_make(self.libraries, "mkdir -p Frameworks/Mpv.xcframework\n"
                        "printf framework > Frameworks/Mpv.xcframework/Info.plist")

    def write_make(self, directory, recipe):
        (directory / "Makefile").write_text(
            "all:\n" + "".join("\t" + line + "\n" for line in recipe.splitlines())
        )

    def run_preparation(self):
        environment = dict(os.environ, NO_PROXY="127.0.0.1", no_proxy="127.0.0.1")
        return subprocess.run(["bash", str(self.script)], env=environment,
                              capture_output=True, text=True, timeout=30)

    def write_headers(self):
        headers = self.video / "macos/Headers/mpv"
        headers.mkdir(parents=True)
        for name in HEADERS:
            (headers / name).write_text("header")
        self.write_make(self.video / "common/darwin", "true")

    def test_transient_http_failures_are_retried_inside_dependency_make(self):
        attempts = []

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                attempts.append(self.path)
                self.send_response(503 if len(attempts) < 3 else 200)
                self.end_headers()
                self.wfile.write(b"downloaded header fixture")

            def log_message(self, *args):
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        port = server.server_address[1]
        self.write_make(self.video / "common/darwin",
                        'mkdir -p "$(HEADERS_DESTDIR)/mpv"\n'
                        f'curl -L http://127.0.0.1:{port}/headers -o "$(HEADERS_DESTDIR)/download"\n'
                        'for header in client.h render.h render_gl.h stream_cb.h; do '
                        'cp "$(HEADERS_DESTDIR)/download" "$(HEADERS_DESTDIR)/mpv/$$header"; done')
        result = self.run_preparation()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(attempts), 3)
        self.assertTrue((self.libraries / "Frameworks/Mpv.xcframework/Info.plist").is_file())

    def test_failed_dependency_setup_stops_before_library_setup(self):
        self.write_make(self.video / "common/darwin", "exit 19")
        result = self.run_preparation()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.libraries / "Frameworks").exists())

    def test_silent_missing_headers_are_rejected(self):
        self.write_make(self.video / "common/darwin", "true")
        result = self.run_preparation()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not produce mpv/client.h", result.stderr)

    def test_silent_missing_framework_is_rejected(self):
        self.write_headers()
        self.write_make(self.libraries, "true")
        result = self.run_preparation()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not produce Mpv.xcframework", result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
