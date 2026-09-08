import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:flutter/material.dart';

class SourcePicker extends StatelessWidget {
  const SourcePicker({
    super.key,
    required this.sourceId,
    required this.onChanged,
    this.height,
  });
  final String sourceId;
  final double? height;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final sources = BooruService.instance.sources;
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    var labelWidth = 0.0;
    for (final source in sources) {
      final painter = TextPainter(
        text: TextSpan(text: source.displayName, style: labelStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > labelWidth) labelWidth = painter.width;
      painter.dispose();
    }
    return SizedBox(
      // Fit every name, the 20px arrow and two 10px horizontal insets.
      width: labelWidth.ceilToDouble() + 40,
      height: height,
      child: AppSelect<String>(
        borderColor: AppThemeTokens.of(context).line,
        value: sourceId,
        items: [
          for (final source in sources)
            AppSelectItem(value: source.sourceId, label: source.displayName),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
