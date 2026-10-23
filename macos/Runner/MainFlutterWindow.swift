import Cocoa
import FlutterMacOS

// AppKit retains its native title bar and traffic lights. FrostWindowHost only
// replaces the frame on Windows; no App-specific window channel is needed.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = frame
    contentViewController = flutterViewController
    // Flutter's initial preferred size is zero; retain the nib's window frame.
    setFrame(windowFrame, display: true)
    styleMask.remove(.fullSizeContentView)
    titleVisibility = .visible
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = false
    minSize = NSSize(width: 320, height: 480)
    center()
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
