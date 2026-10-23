import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Both detail headers and viewer headers share the actual toolbar folding path.
FrostToolbarItem postIconAction(
  BuildContext context, {
  required String label,
  required FrostIconData icon,
  VoidCallback? onPressed,
  Future<bool> Function()? onPressedAsync,
  FrostToolbarPriority priority = FrostToolbarPriority.normal,
}) => FrostToolbarItem.custom(
  minWidth: FrostDensity.of(context).targetHeight,
  priority: priority,
  overflowEntry: FrostMenuAction(
    label,
    icon: icon,
    onSelected:
        onPressed ??
        (onPressedAsync == null
            ? null
            : () {
                onPressedAsync();
              }),
  ),
  builder: (_) => FrostButton.icon(
    label: label,
    icon: icon,
    size: FrostControlSize.compact,
    onPressed: onPressed,
    onPressedAsync: onPressedAsync,
  ),
);

FrostToolbarItem postMoreAction(
  BuildContext context,
  List<FrostMenuEntry> entries,
) => FrostToolbarItem.custom(
  minWidth: FrostDensity.of(context).targetHeight,
  // Fold this trigger first and merge its entries into the toolbar's More.
  priority: FrostToolbarPriority.low,
  overflowEntry: FrostMenuSection(entries: entries),
  builder: (_) => FrostMenuAnchor(
    entries: entries,
    builder: (context, focus, toggle) => Focus(
      focusNode: focus,
      canRequestFocus: false,
      child: FrostButton.icon(
        label: t.frost.more,
        icon: appIcons.more,
        size: FrostControlSize.compact,
        onPressed: toggle,
      ),
    ),
  ),
);

class PostMediaHeader extends StatelessWidget {
  const PostMediaHeader({
    required this.title,
    this.leading,
    required this.actions,
    this.windowButtons = false,
    super.key,
  });
  final Widget title;
  final Widget? leading;
  final List<FrostToolbarItem> actions;
  final bool windowButtons;
  @override
  Widget build(BuildContext context) => FrostMediaSystemChrome(
    child: FrostOnMediaChromeScope(
      child: Builder(
        builder: (context) => SafeArea(
          bottom: false,
          child: Row(
            children: [
              Expanded(
                child: FrostContentColumn(
                  maxWidth: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: FrostPageHeader.verticalHeight,
                    ),
                    child: DefaultTextStyle(
                      style: FrostTypography.of(context)
                          .style(FrostTextRole.headline)
                          .copyWith(
                            color: FrostThemeTokens.of(context).onMediaInk,
                          ),
                      child: FrostToolbar(
                        leading: [
                          ?(leading ?? FrostPageHeader.leadingFor(context)),
                          if (windowButtons)
                            FrostCaptionRegion(
                              kind: FrostHitKind.caption,
                              child: title,
                            )
                          else
                            title,
                        ],
                        trailing: actions,
                      ),
                    ),
                  ),
                ),
              ),
              if (windowButtons)
                const SizedBox(
                  height: FrostPageHeader.verticalHeight,
                  child: FrostCaptionButtons(),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
