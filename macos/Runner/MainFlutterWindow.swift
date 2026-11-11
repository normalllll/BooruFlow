import Cocoa
import FlutterMacOS

// Window decoration, placement and showing belong to the frost_window plugin:
// the window stays hidden (the nib is not visible at launch) until the app has
// placed it and rendered its first frame. Nothing here orders it front, and
// AppKit neither autosaves nor restores its frame.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // A FlutterViewController that creates its own engine starts it only once
    // its window is on screen, and this window waits for Dart to show it. Run
    // the engine first so Dart can place and show the hidden window.
    let engine = FlutterEngine(name: "main", project: nil, allowHeadlessExecution: true)
    engine.run(withEntrypoint: nil)
    let flutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    let windowFrame = frame
    contentViewController = flutterViewController
    // Flutter's initial preferred size is zero; retain the nib's window frame
    // for the hidden engine surface.
    setFrame(windowFrame, display: true)
    isRestorable = false
    RegisterGeneratedPlugins(registry: flutterViewController)
    registerFolderAccess(flutterViewController.engine.binaryMessenger)
    super.awakeFromNib()
  }

  /// Security-scoped bookmarks keep a folder the user picked writable after
  /// a relaunch. The access stays open for the life of the process.
  private func registerFolderAccess(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "booruflow/folder_access", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      do {
        switch (call.method, call.arguments) {
        case ("bookmark", let path as String):
          let data = try URL(fileURLWithPath: path).bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          result(FlutterStandardTypedData(bytes: data))
        case ("open", let bookmark as FlutterStandardTypedData):
          var stale = false
          let url = try URL(
            resolvingBookmarkData: bookmark.data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &stale
          )
          result(url.startAccessingSecurityScopedResource() ? url.path : nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "folder_access", message: error.localizedDescription, details: nil))
      }
    }
  }
}
