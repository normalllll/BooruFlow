import 'package:flutter/material.dart';
import 'package:booruflow/app/window/native_window.dart';

class DesktopWindowFrame extends StatelessWidget {
  const DesktopWindowFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NativeWindowFrame(
      title: 'BooruFlow',
      leading: Image.asset(
        'assets/branding/app_icon_source.png',
        cacheWidth: 104,
        cacheHeight: 104,
        filterQuality: FilterQuality.medium,
      ),
      background: colors.surface,
      foreground: colors.onSurfaceVariant,
      border: colors.outlineVariant,
      child: child,
    );
  }
}
