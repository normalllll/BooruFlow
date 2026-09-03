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
        child: Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 2, 0),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final canSubmit = value.text.trim().isNotEmpty;

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          scrollController: scrollController,
                          textInputAction: TextInputAction.search,
                          maxLines: 1,
                          onSubmitted: onSubmitted,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintText: hintText,
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      if (value.text.isNotEmpty)
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).deleteButtonTooltip,
                          onPressed: controller.clear,
                          icon: const Icon(Icons.close, size: 18),
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                        ),
                      SizedBox.square(
                        dimension: 32,
                        child: IconButton(
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
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
