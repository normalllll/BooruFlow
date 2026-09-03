import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    var centeredFrame = self.frame
    if let visibleFrame = NSScreen.main?.visibleFrame {
      centeredFrame.origin = NSPoint(
        x: visibleFrame.midX - centeredFrame.width / 2,
        y: visibleFrame.midY - centeredFrame.height / 2
      )
    }
    self.setFrame(centeredFrame, display: false)

    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
