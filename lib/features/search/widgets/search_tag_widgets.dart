import 'dart:math' as math;

import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/tag_label.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';

String compactCount(String count) {
  final number = int.tryParse(count);
  if (number == null) return count;
  if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}m';
  if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
  return count;
}

String categoryLabel(TagCategory category) => switch (category) {
  TagCategory.artist => t.discovery.artist,
  TagCategory.character => t.discovery.character,
  TagCategory.copyright => t.discovery.copyright,
  TagCategory.meta => t.discovery.meta,
  TagCategory.general => t.discovery.general,
};

class SelectedTags extends StatelessWidget {
  const SelectedTags({
    super.key,
    required this.tags,
    required this.displayName,
    required this.onRemove,
    required this.onMore,
  });
  final List<String> tags;
  final String Function(String) displayName;
  final ValueChanged<String> onRemove;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = Theme.of(context).textTheme.labelLarge!;
      double textWidth(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width;
        painter.dispose();
        return width;
      }

      final widths = tags
          .map(
            (tag) => math.min(
              math.min(240.0, constraints.maxWidth),
              textWidth(TagLabel.text(tag, displayName(tag))) + 64,
            ),
          )
          .toList();
      final rows = <List<int>>[[], []];
      final used = [0.0, 0.0];
      var row = 0;
      var visible = 0;
      for (var i = 0; i < tags.length; i++) {
        final gap = rows[row].isEmpty ? 0.0 : 8.0;
        if (used[row] + gap + widths[i] > constraints.maxWidth &&
            rows[row].isNotEmpty) {
          row++;
        }
        if (row >= 2) break;
        used[row] += (rows[row].isEmpty ? 0 : 8) + widths[i];
        rows[row].add(i);
        visible++;
      }
      final moreWidth = math.min(
        constraints.maxWidth,
        textWidth('+${tags.length}') + 48,
      );
      if (visible < tags.length) {
        while (rows[1].isNotEmpty &&
            used[1] + 8 + moreWidth > constraints.maxWidth) {
          used[1] -= widths[rows[1].removeLast()] + (rows[1].isEmpty ? 0 : 8);
          visible--;
        }
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 0; r < 2; r++)
            if (rows[r].isNotEmpty || r == 1 && visible < tags.length)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      SizedBox(
                        width: widths[rows[r][i]],
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InputChip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: TagLabel(
                              value: tags[rows[r][i]],
                              translation: displayName(tags[rows[r][i]]),
                              style: style,
                            ),
                            onDeleted: () => onRemove(tags[rows[r][i]]),
                            deleteButtonTooltipMessage: t.generic.clear,
                          ),
                        ),
                      ),
                    ],
                    if (r == 1 && visible < tags.length) ...[
                      if (rows[r].isNotEmpty) const SizedBox(width: 8),
                      SizedBox(
                        width: moreWidth,
                        child: ActionChip(
                          label: Text(
                            '+${tags.length - visible}',
                            style: style,
                            maxLines: 1,
                          ),
                          onPressed: onMore,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ],
      );
    },
  );
}
