#!/usr/bin/env bash
set -euo pipefail

project_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
# Resolve packages before pod install: CocoaPods plugin symlinks do not exist
# yet on a clean CI runner. Pub's package config is already available.
package_root() {
  python3 - "$project_directory/.dart_tool/package_config.json" "$1" <<'PY'
import json
from pathlib import Path
import sys
from urllib.parse import unquote, urljoin, urlparse

config = Path(sys.argv[1]).resolve()
if not config.is_file():
    sys.exit("Run flutter pub get before preparing macOS media dependencies.")
packages = json.loads(config.read_text())["packages"]
package = next((item for item in packages if item["name"] == sys.argv[2]), None)
if package is None:
    sys.exit("Missing media package: " + sys.argv[2])
uri = urlparse(urljoin(config.as_uri(), package["rootUri"]))
if uri.scheme != "file":
    sys.exit("Expected a local package root: " + sys.argv[2])
print(unquote(uri.path))
PY
}
video="$(package_root media_kit_video)"
libraries="$(package_root media_kit_libs_macos_video)"
if [[ ! -f "$video/common/darwin/Makefile" || ! -f "$libraries/macos/Makefile" ]]; then
  echo "Run flutter pub get before preparing macOS media dependencies." >&2
  exit 1
fi

# Scope curl's standard retry settings to dependency build commands. The
# dependencies retain ownership of download versions, checksums and extraction.
curl_directory="$(mktemp -d "${TMPDIR:-/tmp}/booruflow-media-curl.XXXXXX")"
trap 'rm -rf -- "$curl_directory"' EXIT
export CURL_HOME="$curl_directory"
cat > "$CURL_HOME/.curlrc" <<'CURL'
fail
retry = 3
retry-all-errors
retry-delay = 2
retry-max-time = 600
connect-timeout = 15
max-time = 300
CURL

# Their podspecs do not propagate make failures. Run the supported setup here
# so a failed download stops CI before Swift reports missing mpv types.
make -C "$video/common/darwin" HEADERS_DESTDIR="$video/macos/Headers"
for header in client.h render.h render_gl.h stream_cb.h; do
  if [[ ! -s "$video/macos/Headers/mpv/$header" ]]; then
    echo "Media setup did not produce mpv/$header." >&2
    exit 1
  fi
done
make -C "$libraries/macos"
if [[ ! -s "$libraries/macos/Frameworks/Mpv.xcframework/Info.plist" ]]; then
  echo "Media setup did not produce Mpv.xcframework." >&2
  exit 1
fi
