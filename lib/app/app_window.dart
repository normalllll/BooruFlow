import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The window controller created and prepared at startup, for the pages that
/// ask the native window for something (the full-screen viewer).
class AppWindow extends InheritedWidget {
  const AppWindow({required this.controller, required super.child, super.key});
  final FrostWindowController controller;

  static FrostWindowController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppWindow>()?.controller;

  @override
  bool updateShouldNotify(AppWindow oldWidget) =>
      controller != oldWidget.controller;
}
