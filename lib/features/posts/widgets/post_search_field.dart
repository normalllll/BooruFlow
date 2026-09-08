import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:flutter/material.dart';

class PostSearchField extends StatelessWidget {
  const PostSearchField({
    required this.controller,
    required this.onSubmitted,
    this.scrollController,
    this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final ScrollController? scrollController;
  final ValueChanged<String> onSubmitted;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final canSubmit = value.text.trim().isNotEmpty;
            return AppTextField(
              controller: controller,
              scrollController: scrollController,
              textInputAction: TextInputAction.search,
              maxLines: 1,
              onSubmitted: onSubmitted,
              hintText: hintText,
              trailing: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value.text.isNotEmpty)
                      AppIconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        onPressed: controller.clear,
                        icon: const Icon(Icons.close, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    AppIconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).searchFieldLabel,
                      onPressed: canSubmit
                          ? () => onSubmitted(controller.text)
                          : null,
                      icon: Icon(
                        Icons.search,
                        size: 18,
                        color: canSubmit
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.42,
                              ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
