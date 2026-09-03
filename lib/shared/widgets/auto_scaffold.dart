import 'package:flutter/material.dart';
import 'package:yande_gui/core/app_runtime.dart';

bool shouldUseDesktopShell(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 &&
      size.width >= (AppPlatform.isDesktop ? 840 : 900);
}

class AutoScaffold extends StatelessWidget {
  final Widget? verticalOnlyTitleWidget;

  final Widget? horizontalOnlyTitleWidget;

  final Widget? titleWidget;

  final Widget Function(BuildContext context, bool horizontal)? builder;

  final Widget? floatingActionButton;

  final bool? topSafeArea;

  const AutoScaffold({
    super.key,
    this.verticalOnlyTitleWidget,
    this.horizontalOnlyTitleWidget,
    this.titleWidget,
    this.builder,
    this.floatingActionButton,
    this.topSafeArea,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isVertical = size.width < size.height;
    final useDesktopShell = shouldUseDesktopShell(context);

    final Widget child =
        builder?.call(context, !isVertical) ?? const SizedBox();

    final Widget? title =
        titleWidget ??
        (isVertical ? verticalOnlyTitleWidget : horizontalOnlyTitleWidget);

    return Scaffold(
      appBar: title != null && !useDesktopShell
          ? AppBar(title: title, scrolledUnderElevation: 0)
          : null,
      resizeToAvoidBottomInset: true,
      body: SafeArea(top: topSafeArea ?? true, child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}
