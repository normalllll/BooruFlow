import 'package:flutter/material.dart';
import 'package:booruflow/core/app_runtime.dart';

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

  final bool showAppBar;

  const AutoScaffold({
    super.key,
    this.verticalOnlyTitleWidget,
    this.horizontalOnlyTitleWidget,
    this.titleWidget,
    this.builder,
    this.floatingActionButton,
    this.showAppBar = true,
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

    final appBar = title != null && !useDesktopShell && showAppBar
        ? AppBar(title: title, scrolledUnderElevation: 0)
        : null;
    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: true,
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}
