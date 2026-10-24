import Cocoa
import FlutterMacOS

// Window decoration and native controls belong to the frost_window plugin.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = frame
    contentViewController = flutterViewController
    // Flutter's initial preferred size is zero; retain the nib's window frame.
    setFrame(windowFrame, display: true)
    center()
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
