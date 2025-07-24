import 'package:flutter/material.dart';
import 'package:yande_gui/services/tag_translations_service.dart';

class TranslatedTag extends StatelessWidget {
  final String text;

  const TranslatedTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(150),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
            ),
            if (TagTranslationsService.translate(text) case final transltedText?)
              TextSpan(
                text: ' #$transltedText',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
