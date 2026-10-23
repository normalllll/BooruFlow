import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// A structural group spends no page-edge bleed between sibling controls.
/// Their ordinary hit padding and the related gap both remain available.
class AppActionGroup extends StatelessWidget {
  const AppActionGroup({
    required this.children,
    this.alignment = WrapAlignment.start,
    super.key,
  });
  final List<Widget> children;
  final WrapAlignment alignment;
  @override
  Widget build(BuildContext context) => FrostKeyline(
    leadingRoom: 0,
    trailingRoom: 0,
    edgeDistanceStart: 0,
    edgeDistanceEnd: 0,
    insideContainer: true,
    contentStart: 0,
    child: Wrap(
      spacing: FrostGap.related,
      runSpacing: FrostGap.related,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    ),
  );
}
