import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/widgets/rounded_surface.dart';

double appFieldHeight(BuildContext context) => math.max(
  36,
  MediaQuery.textScalerOf(
            context,
          ).scale(Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) *
          1.5 +
      12,
);

class AppSelectItem<T> {
  const AppSelectItem({
    required this.value,
    required this.label,
    this.icon,
    this.content,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Widget? content;
}

class AppSelect<T> extends StatefulWidget {
  const AppSelect({
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.autofocus = false,
    this.compact = true,
    this.borderColor,
    super.key,
  });

  final String? label;
  final T? value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool autofocus;
  final bool compact;
  final Color? borderColor;

  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = AppThemeTokens.of(context);
    AppSelectItem<T>? selected;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selected = item;
        break;
      }
    }

    final select = LayoutBuilder(
      builder: (context, constraints) {
        final fieldHeight = appFieldHeight(context);
        final itemHeight = fieldHeight;
        final labelStyle = theme.textTheme.bodyMedium;
        var labelWidth = 0.0;
        for (final item in widget.items) {
          final painter = TextPainter(
            text: TextSpan(text: item.label, style: labelStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          labelWidth = math.max(
            labelWidth,
            painter.width + (item.icon == null ? 0 : 26),
          );
          painter.dispose();
        }
        // Allow the popup to fit its labels even when the field is narrow.
        final menuWidth = math.min(
          MediaQuery.sizeOf(context).width - 24,
          math.max(constraints.maxWidth, labelWidth.ceilToDouble() + 72),
        );
        return MenuAnchor(
          clipBehavior: Clip.antiAlias,
          crossAxisUnconstrained: true,
          onOpen: () => setState(() => _open = true),
          onClose: () => setState(() => _open = false),
          style: MenuStyle(
            minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
            maximumSize: WidgetStatePropertyAll(Size(menuWidth, 320)),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
            backgroundColor: WidgetStatePropertyAll(tokens.surfaceRaised),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(10),
            shadowColor: WidgetStatePropertyAll(
              Colors.black.withValues(alpha: 0.18),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                side: BorderSide(color: tokens.line),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          menuChildren: [
            for (final item in widget.items)
              SizedBox(
                width: menuWidth - 8,
                child: MenuItemButton(
                  clipBehavior: Clip.antiAlias,
                  onPressed: () => widget.onChanged(item.value),
                  style: ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(0, itemHeight)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStatePropertyAll(
                      const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => item.value == widget.value
                          ? colors.primaryContainer
                          : states.contains(WidgetState.hovered)
                          ? tokens.surfaceTint
                          : Colors.transparent,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      item.value == widget.value
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  trailingIcon: item.value == widget.value
                      ? const Icon(Icons.check_rounded, size: 18)
                      : const SizedBox(width: 18),
                  leadingIcon: item.icon == null
                      ? null
                      : Icon(item.icon, size: 18),
                  child:
                      item.content ??
                      Text(
                        item.label,
                        style: labelStyle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                ),
              ),
          ],
          builder: (context, controller, child) => Focus(
            autofocus: widget.autofocus,
            child: AppRoundedSurface(
              color: _open ? tokens.surfaceRaised : tokens.surfaceMuted,
              borderColor:
                  widget.borderColor ??
                  (_open ? colors.primary : colors.outline),
              borderWidth: widget.borderColor == null && _open ? 1.5 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: controller.isOpen ? controller.close : controller.open,
                child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                    width: constraints.maxWidth,
                    height: fieldHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        if (selected?.icon != null) ...[
                          Icon(
                            selected!.icon,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child:
                              selected?.content ??
                              Text(
                                selected?.label ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 120),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final label = widget.label;
    if (label == null) return select;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        select,
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.height,
    this.focusNode,
    this.readOnly = false,
    this.label,
    this.controller,
    this.scrollController,
    this.hintText,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.monospace = false,
    this.obscureText = false,
    this.autofocus = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    super.key,
  });

  final String? label;
  final TextEditingController? controller;
  final double? height;
  final FocusNode? focusNode;
  final bool readOnly;
  final ScrollController? scrollController;
  final String? hintText;
  final IconData? leading;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool monospace;
  final bool obscureText;
  final bool autofocus;
  final int minLines;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;
  final TapRegionCallback? onTapOutside;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = AppThemeTokens.of(context);
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: tokens.line),
      borderRadius: BorderRadius.circular(10),
    );
    final field = SizedBox(
      height: height,
      child: TextField(
        autofocus: autofocus,
        focusNode: focusNode,
        readOnly: readOnly,
        controller: controller,
        scrollController: scrollController,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        minLines: minLines,
        maxLines: maxLines,
        textAlignVertical: height == null ? null : TextAlignVertical.center,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        onTap: onTap,
        onTapOutside: onTapOutside,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: monospace ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          errorBorder: border,
          focusedErrorBorder: border,
          isDense: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: height == null ? 12 : 4,
          ),
          errorText: errorText,
          prefixIcon: leading == null ? null : Icon(leading, size: 18),
          suffixIcon: trailing == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: trailing,
                ),
          suffixIconConstraints: trailing == null
              ? null
              : BoxConstraints(minHeight: height ?? 36),
          filled: true,
          fillColor: enabled ? tokens.surfaceMuted : tokens.surface,
        ),
      ),
    );
    final label = this.label;
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        field,
      ],
    );
  }
}
