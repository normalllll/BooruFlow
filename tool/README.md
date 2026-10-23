# UI icon and branding resources

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
