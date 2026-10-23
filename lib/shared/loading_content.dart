import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

enum _LoadingShape { tags, rows }

/// Content-shaped first-load placeholders. Callers supply representative text;
/// it determines geometry only and is excluded from loading semantics.
class AppLoadingContent extends StatelessWidget {
  const AppLoadingContent.tags({
    required this.labels,
    this.dataColor,
    super.key,
  }) : _shape = _LoadingShape.tags,
       icon = null;
  const AppLoadingContent.rows({required this.labels, this.icon, super.key})
    : _shape = _LoadingShape.rows,
      dataColor = null;
  final List<String> labels;
  final int? dataColor;
  final FrostIconData? icon;
  final _LoadingShape _shape;

  @override
  Widget build(BuildContext context) => switch (_shape) {
    _LoadingShape.tags => Wrap(
      spacing: FrostGap.related,
      runSpacing: FrostGap.related,
      children: [
        for (final label in labels)
          FrostTag(label: label, dataColor: dataColor),
      ],
    ),
    _LoadingShape.rows => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in labels) FrostListRow(title: label, icon: icon),
      ],
    ),
  }.frostSkeleton(true);
}
