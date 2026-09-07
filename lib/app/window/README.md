# Desktop window integration

`NativeWindowFrame` belongs in `MaterialApp.builder`, outside the router. On
Windows it supplies a separate Overlay for caption tooltips, leaving dialog
barriers inside the page area. Desktop toasts reserve `desktopTitleBarInset`.
Mobile platforms render the original child and never contact the native bridge.

The `desktop_window` channel is shared with GitBound's implementation:

- Windows: Flutter draws the title bar. Native HWND hit testing handles caption
  dragging/double-click, edge resizing, the system menu and `HTMAXBUTTON` for
  Windows 11 Snap Layouts. The Flutter child HWND forwards non-client hits to the
  parent. The OS still handles system commands and maximization. Window events
  publish actual state; sequence numbers prevent an old startup reply from
  overwriting a newer event. DWM manages corner and decoration rendering.
- macOS: AppKit draws one native title bar/compact toolbar, with native traffic
  lights and optional sidebar action. It receives original mouse events and
  honors native double-click/full-screen behavior. No Flutter title bar is added.
- Linux: a GTK HeaderBar supplies the native decoration frame, button placement,
  window menu and pointer event handling (including Wayland input serials).
  The window manager decides whether minimize/maximize requests are supported.

The optional sidebar action is enabled by GitBound. BooruFlow does not add a
second set of navigation or window buttons. AppKit uses a same-row accessory on
macOS versions older than 11, rather than adding a second toolbar row.

## Verification

```sh
flutter test --no-pub test/native_window_test.dart
flutter build windows --debug --no-pub
cmake -S windows -B build/windows/x64 -DBUILD_DESKTOP_WINDOW_TESTS=ON
cmake --build build/windows/x64 --config Debug --target desktop_window_test
build/windows/x64/tests/Debug/desktop_window_test.exe
```

The test target is excluded from normal app builds and writes only to the
separate `tests` output directory. The native checks create only hidden HWNDs, checking parent/child hit testing,
resize edges, minimum dimensions, maximized state and teardown. The Flutter
tests cover system state updates, startup/event ordering, modal barriers, region
updates on resize and the absence of duplicate macOS/Linux bars.

Still verify on actual desktop systems: Windows Snap Layout hover/Win+Z,
drag-to-restore, Alt+Space/Alt+F4, multiple monitor DPIs and auto-hidden taskbars;
macOS traffic lights/full screen/double-click preferences; Linux X11/Wayland
resize, window menu and desktop-specific button placement. macOS and Linux
native compilation cannot be performed on the current Windows host (its WSL
virtualization backend is unavailable).
