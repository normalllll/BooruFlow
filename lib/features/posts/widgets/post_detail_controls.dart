import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The more menu as a toolbar item: it folds first and merges its entries into
/// the toolbar's own More.
FrostToolbarItem postMoreAction(
  BuildContext context,
  List<FrostMenuEntry> entries,
) => FrostToolbarItem.custom(
  minWidth: FrostDensity.of(context).targetHeight,
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
