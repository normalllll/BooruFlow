# Development tools

## Rust/Dart bridge generation

Keep `flutter_rust_bridge_codegen`, the Dart runtime/hooks packages, and the
Rust crate on the same version. After changing the Rust API, run both steps
from the repository root:

```sh
flutter_rust_bridge_codegen generate --no-build-runner
dart run build_runner build
```

FRB 2.14's automatic `build_runner` step filters outputs to `lib/src/rust`.
With this project's build_runner, that filtered run removes unrelated generated
Riverpod/Drift outputs. Skip FRB's partial run and let the complete second step
generate bridge Freezed models, providers, database code, and translations
together. Do not add `--build-filter` to the second command. If generation was
already run without `--no-build-runner`, rerun the full second step to recover
missing outputs; no provider or database source changes are required.

Stop and rebuild a running app after regenerating the bridge: hot reload cannot
replace its native Rust library. Do not hand-edit generated Dart/Rust files.

## History check

Enable the repository hooks once per clone:

```bash
git config core.hooksPath tool/hooks
```

`pre-commit` checks the staged diff, `commit-msg` the message, and `pre-push`
the commits the push would send. A failing hook stops the commit or push
before anything leaves the machine; CI does not run this check. Run the push
check by hand on the commits that are not on the upstream yet, or on any
range:

```bash
dart tool/check_history.dart
dart tool/check_history.dart --range <base>..<tip>
```

The check rejects merge commits, leftover `fixup!` commits, subjects that are
not Conventional Commits, files that `.gitignore` or `.git/info/exclude`
excludes, and text that belongs to a plan or conversation: plan and stage
labels, spec section numbers, request IDs outside `// frost-escape:` lines,
review and decision history, and paths on this machine. It also flags a `fix:`
commit that changes a file an unpushed `feat:` or `refactor:` commit created;
fold such a fix into that commit with `git commit --fixup`. When a finding is
wrong, the maintainer decides whether to push past it.

## UI automation and sample data

- `tool/automation_entry.dart` is the Debug entrypoint for the
  flutter-ui-automation skill: it enables the Flutter Driver extension with the
  app's test commands and starts the app on sample data.
- `tool/sample_main.dart` runs the app on the sample data in `lib/dev/`
  (`flutter run -d windows -t tool/sample_main.dart`).

Both keep storage in a fresh temporary directory and never read or write the
real profile. Release builds do not include the sample data.

For screenshots of real sources, start the automation entrypoint with
`--real-data` (desktop launch arguments) or
`--dart-define=BOORUFLOW_REAL_DATA=true` (`flutter run` on iOS and Android). It
still uses the temporary profile.

## UI icon and branding resources

UI icon SVG sources live in `tool/icons/svg`; they are not runtime assets.
Allocations in `tool/icons/codepoints.csv` are append-only. Preserve retired
rows and their codepoints.

Prepare the fixed generator environment using
[`tool/icon_font/README.md`](icon_font/README.md), then run:

```powershell
./tool/generate_ui_icons.ps1 -Dart <flutter-sdk>/bin/cache/dart-sdk/bin/dart.exe
```

Use the generator's add/retire
commands for new/retired icons; replace source artwork in place to update one.
Commit source/map and generated TTF/Dart together. `build/icon-review` contains
disposable geometric overlays. Never edit generated Dart manually.

BooruFlowIcons is a declared font; appIcons keeps the existing semantic slots.
Directional arrows/panels carry explicit RTL metadata. Logos, multicolour artwork
and photographs remain images, outside this font.

Branding editing masters and notes live in `tool/branding`. The existing Pillow
exporter creates 256px runtime images without cropping their original composition:

```sh
python tool/generate_app_icons.py --runtime-only
```

Their largest in-app size is 64 logical px, covering up to 4x DPR. Without that
switch the script also regenerates platform launcher resources. Original editing
masters are retained outside assets. Noto OFL and Lucide ISC remain explicit
runtime resources, registered in lib/app/licenses.dart. Keep these required
licenses; source SVG, editing masters and README documents do not belong in assets.

## Reduced libmpv

Video plays through media_kit, but the app ships its own libmpv instead of
media_kit's prebuilt libraries: FFmpeg keeps only what booru posts use (H.264,
HEVC, VP8, VP9, AV1 and MPEG-4 video; AAC, MP3, Opus, Vorbis, FLAC and PCM
audio; MP4 and Matroska/WebM; HTTP(S) with an HTTP proxy) plus each platform's
hardware decoder, and mpv leaves out scripting, disc, Vulkan and similar
features. Everything is linked into one library per platform:
`libmpv-2.dll` on Windows, `libmpv.so` per Android ABI and `Mpv.framework` in
an `Mpv.xcframework` for macOS and iOS. Linux uses the system libmpv.

`tool/libmpv/build.sh` builds all of them on macOS (Xcode, the Android NDK of
`android/app/build.gradle.kts`, and `brew install meson ninja nasm cmake
pkgconf`; it downloads llvm-mingw for Windows) and writes the release archives
and `SHA256SUMS` to `build/libmpv/dist`. Source versions are pinned at the top
of the script. `patch_mac_gl.py` lets mpv use VideoToolbox's OpenGL interop on
macOS without its Cocoa backend, which needs Swift and Metal;
`patch_audiounit.py` lets several players share the iOS audio session. mpv is
built without GPL parts; with mbedTLS the Android build is LGPL v3, the others
LGPL v2.1 or later.

A build is published as a `libmpv-<mpv version>-<build>` GitHub release of
this repository. The app's builds download from it and check the SHA-256 in:

- `windows/CMakeLists.txt` (`libmpv-windows-x86_64.zip`)
- `android/app/build.gradle.kts` (`libmpv-android.zip`)
- `third_party/media_kit_libs_macos_video/macos/Makefile` and
  `third_party/media_kit_libs_ios_video/ios/Makefile` (`Mpv.xcframework.zip`)

The two `third_party` packages are media_kit's macOS and iOS library packages
with only their Makefile changed; `pubspec.yaml` overrides them, and a local
`pubspec_overrides.yaml` has to repeat those two overrides.

## macOS media prerequisites

After `flutter pub get`, run `bash tool/ci/prepare_macos_media.sh` before the
macOS build. CI uses this command for both architecture jobs. It runs the media
packages' own Makefiles with scoped curl retries, leaving their pinned versions
and checksum verification in control. It propagates setup failures and checks
that mpv headers and the native framework exist before Swift compilation.
CocoaPods otherwise ignores these Makefile failures and can report a misleading
`cannot find type 'mpv_node_list'` compilation error after a failed download.

Run its failure/retry checks with `python3 tool/ci/test_prepare_macos_media.py`
on macOS or Linux; they use a local HTTP server and temporary package fixtures.
