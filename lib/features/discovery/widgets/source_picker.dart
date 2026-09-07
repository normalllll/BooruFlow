import 'package:flutter/material.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';

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
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: AppSelect<String>(
      value: sourceId,
      items: [
        for (final source in BooruService.instance.sources)
          AppSelectItem(value: source.sourceId, label: source.displayName),
      ],
      onChanged: onChanged,
    ),
  );
}
