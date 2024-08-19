import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ShortcutsWidget extends StatefulWidget {
  final ValueKey valueKey;
  final Map<Type, Action<Intent>> actions;

  final Map<ShortcutActivator, Intent> shortcuts;

  final Widget child;

  const ShortcutsWidget({
    super.key,
    required this.valueKey,
    required this.actions,
    required this.shortcuts,
    required this.child,
  });

  @override
  State<ShortcutsWidget> createState() => _ShortcutsWidgetState();
}

class _ShortcutsWidgetState extends State<ShortcutsWidget> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.valueKey,
      onVisibilityChanged: (info) {
        if (info.visibleFraction != 0.0) {
          if (!_visible) {
            _visible = true;
          }
        } else {
          _visible = false;
        }
      },
      child: Shortcuts(
        shortcuts: widget.shortcuts,
        child: Actions(
          dispatcher: MyActionDispatcher(shortcutEnabled: _visible),
          actions: widget.actions,
          child: FocusScope(
            autofocus: true,
            onFocusChange: (focus) {
              if (focus) {
                _visible = true;
              }
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class MyActionDispatcher extends ActionDispatcher {
  final bool shortcutEnabled;

  MyActionDispatcher({required this.shortcutEnabled});

  @override
  Object? invokeAction(Action<Intent> action, Intent intent, [BuildContext? context]) {
    if (shortcutEnabled) {
      return super.invokeAction(action, intent, context);
    }
    return null;
  }
}
