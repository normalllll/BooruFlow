import 'package:flutter/material.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/widgets/rounded_surface.dart';

enum AppButtonKind { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.labelWidget,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.secondary,
    this.loading = false,
    this.compact = false,
    this.tooltip,
    super.key,
  });

  final String label;
  final Widget? labelWidget;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;
  final bool loading;
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    final foreground = switch (kind) {
      AppButtonKind.primary => colors.onPrimary,
      AppButtonKind.secondary => colors.onSurface,
      AppButtonKind.danger => colors.error,
      AppButtonKind.ghost => colors.primary,
    };
    final background = switch (kind) {
      AppButtonKind.primary => colors.primary,
      AppButtonKind.secondary => tokens.surfaceRaised,
      AppButtonKind.danger => colors.errorContainer.withValues(alpha: 0.45),
      AppButtonKind.ghost => Colors.transparent,
    };
    final border = switch (kind) {
      AppButtonKind.primary => colors.primary,
      AppButtonKind.secondary => tokens.line,
      AppButtonKind.danger => colors.error.withValues(alpha: 0.55),
      AppButtonKind.ghost => Colors.transparent,
    };
    final button = FilledButton(
      clipBehavior: Clip.antiAlias,
      onPressed: loading ? null : onPressed,
      style: ButtonStyle(
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        minimumSize: WidgetStatePropertyAll(Size(0, compact ? 36 : 44)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 8,
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return tokens.surfaceMuted;
          }
          if (states.contains(WidgetState.hovered)) {
            return kind == AppButtonKind.primary
                ? colors.primary.withValues(alpha: 0.86)
                : tokens.surfaceTint;
          }
          return background;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurfaceVariant.withValues(alpha: 0.55)
              : foreground,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: border)),
        elevation: const WidgetStatePropertyAll(0),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 18),
          if (loading || icon != null) const SizedBox(width: 8),
          Flexible(
            child:
                labelWidget ??
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
          ),
        ],
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.selected = false,
    this.selectedBackgroundColor,
    this.danger = false,
    this.iconSize = 19,
    this.color,
    this.padding = const EdgeInsets.all(8),
    this.constraints,
    this.visualDensity,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool selected;
  final Color? selectedBackgroundColor;
  final bool danger;
  final double iconSize;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    final foreground =
        color ??
        (danger
            ? colors.error
            : selected
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      iconSize: iconSize,
      padding: padding,
      constraints: constraints,
      visualDensity: visualDensity,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          constraints?.constrain(const Size.square(40)) ??
              const Size.square(40),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.onSurfaceVariant.withValues(alpha: 0.38)
              : foreground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (selected) {
            return selectedBackgroundColor ?? colors.primaryContainer;
          }
          if (states.contains(WidgetState.hovered)) return tokens.surfaceMuted;
          return Colors.transparent;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: enabled,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: value ? colors.primary : colors.outline),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: value ? colors.onPrimary : colors.onSurfaceVariant,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const SizedBox.square(dimension: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class AppChoiceToggle extends StatelessWidget {
  const AppChoiceToggle({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = AppThemeTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AppRoundedSurface(
        color: selected ? colors.primaryContainer : tokens.surfaceMuted,
        borderColor: selected ? colors.primary : colors.outline,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 34),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
