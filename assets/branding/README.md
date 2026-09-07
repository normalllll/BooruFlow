# Application icon

`app_icon_source.png` is the supplied transparent master artwork. Keep it as the
source of truth; platform exports are committed so builds do not require Python.

To regenerate from the repository root, using Python 3.9+ and Pillow:

```sh
python -m pip install Pillow
python tool/generate_app_icons.py
```

- Windows: `windows/runner/resources/app_icon.ico`, one 256×256 entry as requested.
- Android: existing launcher resources in all five density directories, including
  foreground, opaque background and monochrome layers. Foreground padding allows
  adaptive launcher masks without changing the artwork.
- iOS: all sizes referenced by the existing AppIcon catalog, with an opaque pale
  background and no alpha channel.
- macOS: all sizes referenced by the existing AppIcon catalog, with a rounded
  pale background and transparent outer margin.
- Linux: `icon-512.png` for the portable bundle and `linux/icons/hicolor` for
  desktop packages. The release workflow installs all supplied sizes.

The exporter measures the opaque subject while ignoring faint pixels and isolated
specks, then crops excess margins without filtering the artwork itself. Subject
occupancy is 96% for Windows/Linux, 90% for iOS and 82% for macOS (whose background
keeps its original margin). Android scales to fit a central 72dp circular viewport
with a 1dp inset; review manufacturer-specific masks when replacing the master.
The source master remains unchanged.
