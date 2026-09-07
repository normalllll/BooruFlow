import 'package:flutter/material.dart';

class TagLabel extends StatelessWidget {
  const TagLabel({
    super.key,
    required this.value,
    this.translation,
    this.style,
  });
  final String value;
  final String? translation;
  final TextStyle? style;

  static String text(String value, String? translation) =>
      translation == null || translation.isEmpty || translation == value
      ? '#$value'
      : '$translation #$value';

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        if (translation != null &&
            translation!.isNotEmpty &&
            translation != value)
          TextSpan(text: '$translation '),
        TextSpan(
          text: '#$value',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    ),
    style: style,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
