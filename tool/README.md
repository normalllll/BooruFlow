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

## UI icon and branding resources

UI icon SVG sources live in `tool/icons/svg`; they are not runtime assets.
Allocations in `tool/icons/codepoints.csv` are append-only. Preserve retired
rows/codepoints; R18's six allocations remain E900–E905.

Prepare the fixed generator environment using
[`tool/icon_font/README.md`](icon_font/README.md), then run:

```powershell
./tool/generate_ui_icons.ps1 -Dart V:/SDK/flutter/bin/cache/dart-sdk/bin/dart.exe
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
