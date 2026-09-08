import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:flutter/material.dart';

class TranslatedTag extends StatelessWidget {
  final String text;

  const TranslatedTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 9),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '#$text',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (TagTranslationsService.translate(text)
                  case final translatedText?)
                TextSpan(
                  text: ' · $translatedText',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
