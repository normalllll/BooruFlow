import 'package:flutter/material.dart';

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
    final isVertical = MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;

    final Widget child = builder?.call(context, !isVertical) ?? const SizedBox();

    final Widget? title = titleWidget ?? (isVertical ? verticalOnlyTitleWidget : horizontalOnlyTitleWidget);

    return Scaffold(
      appBar: title != null ? AppBar(title: title, scrolledUnderElevation: 0) : null,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: topSafeArea ?? true,
        child: child,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
