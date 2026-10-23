# Icon font generator

Converts the app's monochrome SVG sources into an icon font and Dart constants.
The app owns the source artwork and the stable codepoint map.
The fixed picosvg/fontTools environment is development-only and ignored by Git.

```powershell
py -3.12 -m venv tool/icon_font/.venv
tool/icon_font/.venv/Scripts/python.exe -m pip install --only-binary=:all: -r tool/icon_font/requirements.txt
tool/icon_font/.venv/Scripts/python.exe -m unittest discover -s tool/icon_font
```

Use `py -0p` to select an installed Python 3.12 registration on another machine.
All direct/transitive versions are pinned; do not install into system Python.

## Build

```powershell
.venv/Scripts/python.exe generate.py build --source APP/tool/icons/svg --map APP/tool/icons/codepoints.csv --family AppIcons --class-name AppIcons --font APP/assets/fonts/AppIcons.ttf --dart APP/lib/app/icons.g.dart --license APP/tool/icons/LICENSE --review APP/build/icon-review
```

Inputs use a 24x24 viewport, 1.75 stroke, round caps/joins, opaque monochrome.
Strokes become closed filled paths with unioned overlaps and preserved holes.
The viewport clips overflow, matching the previous SVG presentation. A square
1536-unit em preserves canvas origin and advance width; bounds are not stretched.
Checks use actual curve extrema, not the larger quadratic control-point box.

The build checks names/codepoints (including retired slots), closed contours,
cmap, visible bounds and reconstructed filled area. `--review` exports source,
expanded, reconstructed and overlay SVGs for visual inspection, outside assets.
The font embeds copyright/license in name entries 0/13. Also register the supplied
license in the app's LicenseRegistry. The fixed TTF timestamp makes identical
inputs and pinned tools byte-reproducible. Run `dart format` on generated Dart.

## Stable allocations

```powershell
.venv/Scripts/python.exe generate.py add --map APP/tool/icons/codepoints.csv --name arrow-left --file arrow-left.svg --rtl
.venv/Scripts/python.exe generate.py retire --map APP/tool/icons/codepoints.csv --name old-icon
```

Add appends after the highest existing/retired allocation. Retire keeps a
permanent tombstone; never remove or reuse that row. Artwork updates keep the
same name/codepoint. `--previous-map OLD.csv` checks immutable history against a
previous table. `rtl=true` emits const IconData(matchTextDirection: true).
Commit source SVG/map and generated TTF/Dart together; no lock files.

Declare the TTF and necessary runtime license in pubspec. Never declare the SVG
source directory. Map existing FrostIconSet slots to
FrostIconData.glyph(AppIcons.someIcon). Other apps can copy this tool and use
their own font family, source directory and codepoint map.
The generated all/names lists support test overviews; production does not import
the diagnostic entrypoint. Const IconData preserves release icon tree shaking.
