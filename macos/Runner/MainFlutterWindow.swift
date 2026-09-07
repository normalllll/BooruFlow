import Cocoa
import FlutterMacOS

// AppKit owns the title bar, traffic lights, dragging, double-click preference,
// full-screen transitions and resize edges. Flutter renders only the content.
class MainFlutterWindow: NSWindow, NSToolbarDelegate {
  private var windowChannel: FlutterMethodChannel?
  private var stateObservers: [NSObjectProtocol] = []
  private var stateRevision: Int64 = 0
  private var sidebarVisible = false
  private var sidebarTooltip = ""
  private let sidebarIdentifier = NSToolbarItem.Identifier("desktop.sidebar")
  private var legacyAccessory: NSTitlebarAccessoryViewController?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    styleMask.remove(.fullSizeContentView)
    titleVisibility = .visible
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = false
    minSize = NSSize(width: 480, height: 360)
    center()

    if #available(macOS 11.0, *) {
      let nativeToolbar = NSToolbar(identifier: "desktop.toolbar")
      nativeToolbar.delegate = self
      nativeToolbar.allowsUserCustomization = false
      nativeToolbar.autosavesConfiguration = false
      nativeToolbar.displayMode = .iconOnly
      toolbar = nativeToolbar
      toolbarStyle = .unifiedCompact
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: "desktop_window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "window_closed", message: "Window is closed", details: nil))
        return
      }
      switch call.method {
      case "getState":
        result(self.windowState())
      case "setToolbar":
        if let config = call.arguments as? [String: Any] {
          self.configureToolbar(config)
        }
        result(nil)
      case "setRegions":
        // No Flutter drag regions: AppKit receives the original native events.
        result(nil)
      case "minimize":
        self.performMiniaturize(nil)
        result(nil)
      case "toggleMaximized":
        self.performZoom(nil)
        self.publishState()
        result(nil)
      case "close":
        result(nil)
        DispatchQueue.main.async { [weak self] in self?.performClose(nil) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    for notification in [
      NSWindow.didResizeNotification,
      NSWindow.didBecomeKeyNotification,
      NSWindow.didResignKeyNotification,
      NSWindow.didMiniaturizeNotification,
      NSWindow.didDeminiaturizeNotification,
      NSWindow.didEnterFullScreenNotification,
      NSWindow.didExitFullScreenNotification
    ] {
      stateObservers.append(NotificationCenter.default.addObserver(
        forName: notification, object: self, queue: .main
      ) { [weak self] _ in self?.publishState() })
    }
    super.awakeFromNib()
  }

  private func windowState() -> [String: Any] {
    return [
      "maximized": isZoomed,
      "fullscreen": styleMask.contains(.fullScreen),
      "active": isKeyWindow,
      "revision": stateRevision
    ]
  }

  private func publishState() {
    stateRevision += 1
    windowChannel?.invokeMethod("stateChanged", arguments: windowState())
  }

  private func configureToolbar(_ config: [String: Any]) {
    if let appTitle = config["title"] as? String { title = appTitle }
    if let dark = config["dark"] as? Bool {
      appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    }
    sidebarTooltip = config["sidebarTooltip"] as? String ?? ""
    sidebarVisible = config["showSidebarButton"] as? Bool ?? false
    if let toolbar = toolbar {
      let index = toolbar.items.firstIndex { $0.itemIdentifier == sidebarIdentifier }
      if sidebarVisible && index == nil {
        toolbar.insertItem(withItemIdentifier: sidebarIdentifier, at: 0)
      } else if !sidebarVisible, let index = index {
        toolbar.removeItem(at: index)
      }
      toolbar.items.first { $0.itemIdentifier == sidebarIdentifier }?.toolTip = sidebarTooltip
    } else {
      // On pre-11 macOS, a right-side title-bar accessory avoids adding a
      // second toolbar row. It does not replace any native window buttons.
      if sidebarVisible && legacyAccessory == nil {
        let accessory = NSTitlebarAccessoryViewController()
        let button = NSButton(image: NSImage(named: NSImage.touchBarSidebarTemplateName)
                              ?? NSImage(), target: self, action: #selector(toggleSidebar))
        button.isBordered = false
        button.frame = NSRect(x: 0, y: 0, width: 32, height: 24)
        accessory.view = button
        accessory.layoutAttribute = .right
        addTitlebarAccessoryViewController(accessory)
        legacyAccessory = accessory
      } else if !sidebarVisible, let accessory = legacyAccessory,
                let index = titlebarAccessoryViewControllers.firstIndex(of: accessory) {
        removeTitlebarAccessoryViewController(at: index)
        legacyAccessory = nil
      }
      legacyAccessory?.view.toolTip = sidebarTooltip
    }
  }

  @objc private func toggleSidebar() {
    windowChannel?.invokeMethod("toggleSidebar", arguments: nil)
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [sidebarIdentifier, .flexibleSpace]
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [.flexibleSpace]
  }

  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
               willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    guard identifier == sidebarIdentifier else { return nil }
    let item = NSToolbarItem(itemIdentifier: identifier)
    item.label = sidebarTooltip
    item.toolTip = sidebarTooltip
    item.target = self
    item.action = #selector(toggleSidebar)
    if #available(macOS 11.0, *) {
      item.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: sidebarTooltip)
    }
    return item
  }

  deinit {
    windowChannel?.setMethodCallHandler(nil)
    stateObservers.forEach(NotificationCenter.default.removeObserver)
  }
}
