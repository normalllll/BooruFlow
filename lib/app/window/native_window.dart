import 'dart:async';

import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const desktopTitleBarHeight = 44.0;

bool get isDesktopWindowConfigured =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

// AppKit and GTK own their title bars outside the Flutter content area.
bool get usesFlutterTitleBar =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

double get desktopTitleBarInset =>
    usesFlutterTitleBar ? desktopTitleBarHeight : 0;

@immutable
class NativeWindowState {
  const NativeWindowState({
    this.maximized = false,
    this.active = true,
    this.fullscreen = false,
    this.hoveredButton = '',
    this.pressedButton = '',
    this.revision = -1,
  });

  final bool maximized;
  final bool active;
  final bool fullscreen;
  final String hoveredButton;
  final String pressedButton;
  final int revision;

  factory NativeWindowState.fromMap(Map<Object?, Object?> value) =>
      NativeWindowState(
        maximized: value['maximized'] == true,
        active: value['active'] != false,
        fullscreen: value['fullscreen'] == true,
        hoveredButton: value['hoveredButton'] as String? ?? '',
        pressedButton: value['pressedButton'] as String? ?? '',
        revision: (value['revision'] as num?)?.toInt() ?? 0,
      );
}

class NativeWindowController extends ChangeNotifier {
  NativeWindowController({
    this.channel = const MethodChannel('desktop_window'),
  });

  final MethodChannel channel;
  NativeWindowState _state = const NativeWindowState();
  NativeWindowState get state => _state;
  VoidCallback? onToggleSidebar;
  bool _disposed = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    channel.setMethodCallHandler((call) async {
      if (_disposed) return;
      if (call.method == 'stateChanged' && call.arguments is Map) {
        _acceptState(Map<Object?, Object?>.from(call.arguments as Map));
      } else if (call.method == 'toggleSidebar') {
        onToggleSidebar?.call();
      }
    });
    final result = await _invoke<Map<Object?, Object?>>('getState');
    if (result != null && !_disposed) _acceptState(result);
  }

  void _acceptState(Map<Object?, Object?> value) {
    final next = NativeWindowState.fromMap(value);
    // A reply to the startup query can arrive after a newer native event.
    if (next.revision < _state.revision) return;
    _state = next;
    notifyListeners();
  }

  Future<void> minimize() => _invoke<void>('minimize');
  Future<void> toggleMaximized() => _invoke<void>('toggleMaximized');
  Future<void> close() => _invoke<void>('close');
  Future<void> setRegions(List<List<Object>> regions) =>
      _invoke<void>('setRegions', regions);
  Future<void> setToolbar(Map<String, Object> toolbar) =>
      _invoke<void>('setToolbar', toolbar);

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (_disposed) return null;
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      debugPrint(
        'Desktop window $method failed: ${error.code}: ${error.message}',
      );
    } on MissingPluginException catch (error) {
      debugPrint('Desktop window bridge is unavailable: $error');
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    if (_initialized) channel.setMethodCallHandler(null);
    onToggleSidebar = null;
    super.dispose();
  }
}

@immutable
class NativeWindowLabels {
  const NativeWindowLabels({
    required this.minimize,
    required this.maximize,
    required this.restore,
    required this.close,
  });

  final String minimize;
  final String maximize;
  final String restore;
  final String close;

  factory NativeWindowLabels.forLocale(Locale locale) {
    final labels = AppLocaleUtils.parse(
      locale.toLanguageTag(),
    ).translations.nativeWindow;
    return NativeWindowLabels(
      minimize: labels.minimize,
      maximize: labels.maximize,
      restore: labels.restore,
      close: labels.close,
    );
  }
}

/// Install with MaterialApp.builder, outside its Navigator/Router. Dialog
/// barriers then cover the page, not the window controls or draggable region.
class NativeWindowFrame extends StatefulWidget {
  const NativeWindowFrame({
    required this.child,
    required this.title,
    required this.leading,
    required this.background,
    required this.foreground,
    required this.border,
    this.labels,
    this.onToggleSidebar,
    this.sidebarCollapsed = false,
    this.sidebarTooltip = '',
    this.controller,
    super.key,
  });

  final Widget child;
  final String title;
  final Widget leading;
  final Color background;
  final Color foreground;
  final Color border;
  final NativeWindowLabels? labels;
  final VoidCallback? onToggleSidebar;
  final bool sidebarCollapsed;
  final String sidebarTooltip;
  final NativeWindowController? controller;

  @override
  State<NativeWindowFrame> createState() => _NativeWindowFrameState();
}

class _NativeWindowFrameState extends State<NativeWindowFrame>
    with WidgetsBindingObserver {
  late final NativeWindowController _controller;
  final _titleRegion = GlobalKey();
  final _spaceRegion = GlobalKey();
  final _maximizeRegion = GlobalKey();
  String? _lastRegions;
  String? _lastToolbar;
  bool _syncQueued = false;
  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NativeWindowController();
    _controller.onToggleSidebar = () {
      if (mounted && _showSidebar) widget.onToggleSidebar?.call();
    };
    _controller.addListener(_stateChanged);
    WidgetsBinding.instance.addObserver(this);
    if (isDesktopWindowConfigured) unawaited(_initializeNative());
  }

  Future<void> _initializeNative() async {
    await _controller.initialize();
    if (!mounted) return;
    // Retry the initial geometry after the platform channel is ready, even
    // when no activation, maximize or resize event follows the first frame.
    _lastRegions = null;
    _lastToolbar = null;
    _queueSync();
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _stateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() => _queueSync();

  void _queueSync() {
    if (_syncQueued || !isDesktopWindowConfigured) return;
    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueued = false;
      if (mounted) _syncNative();
    });
  }

  void _syncNative() {
    final toolbar = <String, Object>{
      'title': widget.title,
      'dark': Theme.of(context).brightness == Brightness.dark,
      'showSidebarButton': _showSidebar,
      'sidebarCollapsed': widget.sidebarCollapsed,
      'sidebarTooltip': widget.sidebarTooltip,
    };
    if (toolbar.toString() != _lastToolbar) {
      _lastToolbar = toolbar.toString();
      unawaited(_controller.setToolbar(toolbar));
    }
    if (!usesFlutterTitleBar) return;
    final regions = <List<Object>>[];
    for (final entry in [
      (_titleRegion, 'caption'),
      (_spaceRegion, 'caption'),
      (_maximizeRegion, 'maximize'),
    ]) {
      final box = entry.$1.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      regions.add([rect.left, rect.top, rect.right, rect.bottom, entry.$2]);
    }
    if (regions.toString() != _lastRegions) {
      _lastRegions = regions.toString();
      unawaited(_controller.setRegions(regions));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_stateChanged);
    if (usesFlutterTitleBar) unawaited(_controller.setRegions([]));
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWindowConfigured) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        _showSidebar =
            widget.onToggleSidebar != null && constraints.maxWidth >= 800;
        _queueSync();
        if (!usesFlutterTitleBar) return widget.child;
        final state = _controller.state;
        final labels =
            widget.labels ??
            NativeWindowLabels.forLocale(Localizations.localeOf(context));
        // The page's Navigator is below this frame. Give caption tooltips their
        // own overlay while keeping modal barriers confined to the page area.
        return Overlay.wrap(
          child: Column(
            children: [
              Material(
                color: widget.background,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: widget.border)),
                  ),
                  child: _WindowRegionLayout(
                    onLayout: _queueSync,
                    child: SizedBox(
                      height: desktopTitleBarHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.5,
                            ),
                            child: Padding(
                              key: _titleRegion,
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: widget.leading,
                                  ),
                                  const SizedBox(width: 9),
                                  Flexible(
                                    child: Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: widget.foreground.withValues(
                                              alpha: state.active ? 1 : 0.6,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showSidebar)
                            IconButton(
                              tooltip: widget.sidebarTooltip,
                              onPressed: widget.onToggleSidebar,
                              icon: Icon(
                                widget.sidebarCollapsed
                                    ? Icons.keyboard_double_arrow_right_rounded
                                    : Icons.keyboard_double_arrow_left_rounded,
                              ),
                            ),
                          Expanded(child: SizedBox(key: _spaceRegion)),
                          _CaptionButton(
                            label: labels.minimize,
                            icon: Icons.horizontal_rule_rounded,
                            foreground: widget.foreground,
                            onPressed: _controller.minimize,
                          ),
                          _CaptionButton(
                            key: _maximizeRegion,
                            label: state.maximized
                                ? labels.restore
                                : labels.maximize,
                            icon: state.maximized
                                ? Icons.filter_none_rounded
                                : Icons.crop_square_rounded,
                            foreground: widget.foreground,
                            onPressed: _controller.toggleMaximized,
                            nativeHovered: state.hoveredButton == 'maximize',
                            nativePressed: state.pressedButton == 'maximize',
                          ),
                          _CaptionButton(
                            label: labels.close,
                            icon: Icons.close_rounded,
                            foreground: widget.foreground,
                            onPressed: _controller.close,
                            danger: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.nativeHovered = false,
    this.nativePressed = false,
    this.danger = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;
  final bool nativeHovered;
  final bool nativePressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(
          Size(46, desktopTitleBarHeight),
        ),
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              danger &&
                  (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.pressed))
              ? Colors.white
              : foreground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          final hover = nativeHovered || states.contains(WidgetState.hovered);
          final press =
              (nativePressed && nativeHovered) ||
              states.contains(WidgetState.pressed);
          if (!hover && !press) return Colors.transparent;
          return danger
              ? const Color(0xFFC42B1C)
              : foreground.withValues(alpha: press ? 0.12 : 0.08);
        }),
      ),
    ),
  );
}

// Overlay descendants can lay out without rebuilding the frame LayoutBuilder.
// Synchronize from the actual title bar layout, not just ancestor rebuilds.
class _WindowRegionLayout extends SingleChildRenderObjectWidget {
  const _WindowRegionLayout({required this.onLayout, required super.child});

  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _WindowRegionRenderBox(onLayout);

  @override
  void updateRenderObject(
    BuildContext context,
    _WindowRegionRenderBox renderObject,
  ) {
    renderObject.onLayout = onLayout;
  }
}

class _WindowRegionRenderBox extends RenderProxyBox {
  _WindowRegionRenderBox(this.onLayout);

  VoidCallback onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout();
  }
}
