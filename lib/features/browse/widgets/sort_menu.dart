import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

String sortLabel(SortOrder order) => switch (order) {
  SortOrder.latest => t.discovery.sort.latest,
  SortOrder.oldest => t.discovery.sort.oldest,
  SortOrder.relevance => t.discovery.sort.relevance,
  SortOrder.score => t.discovery.sort.score,
  SortOrder.favorites => t.discovery.sort.favorites,
  SortOrder.views => t.discovery.sort.views,
  SortOrder.upvotes => t.discovery.sort.upvotes,
  SortOrder.hot => t.discovery.sort.hot,
  SortOrder.updated => t.discovery.sort.updated,
  SortOrder.resolution => t.discovery.sort.resolution,
  SortOrder.landscape => t.discovery.sort.landscape,
  SortOrder.portrait => t.discovery.sort.portrait,
  SortOrder.fileSize => t.discovery.sort.fileSize,
  SortOrder.tagCount => t.discovery.sort.tagCount,
  SortOrder.random => t.discovery.sort.random,
};

/// The sorts a source offers for one list and the one in effect. The first
/// option is the default; every control of this file reads from this object,
/// so a page builds it once and hands it to whichever controls it shows.
class SortChoice {
  const SortChoice({
    required this.options,
    required this.selected,
    required this.onSelected,
  });
  final List<SortOption> options;
  final SortOrder selected;
  final ValueChanged<SortOrder> onSelected;

  /// A single option is no choice; the controls stay away.
  bool get isOffered => options.length > 1;
  SortOrder get fallback => options.first.order;
  bool get isDefault => selected == fallback;
  void reset() => onSelected(fallback);

  /// Primary options are listed directly; the others sit in a submenu, which
  /// carries the check mark while one of its options is in effect.
  List<FrostMenuEntry> get entries {
    FrostMenuAction action(SortOption option) => FrostMenuAction(
      sortLabel(option.order),
      checked: option.order == selected,
      onSelected: () => onSelected(option.order),
    );
    final more = [
      for (final option in options)
        if (!option.primary) option,
    ];
    return [
      for (final option in options)
        if (option.primary) action(option),
      if (more.isNotEmpty)
        FrostMenuSubmenu(
          t.discovery.sort.more,
          leading: more.any((option) => option.order == selected)
              ? FrostGlyph.icon(appIcons.check)
              : null,
          entries: [for (final option in more) action(option)],
        ),
    ];
  }

  /// The sort as a submenu of another menu.
  FrostMenuEntry get menuEntry => FrostMenuSubmenu(
    t.discovery.sort.title,
    leading: FrostGlyph.icon(appIcons.sort),
    entries: entries,
  );

  /// A header toolbar item for pages without a tab row.
  FrostToolbarItem toolbarItem(BuildContext context) => FrostToolbarItem.custom(
    minWidth: FrostDensity.of(context).targetHeight,
    priority: FrostToolbarPriority.high,
    builder: (_) => FrostMenuAnchor(
      entries: entries,
      builder: (context, focus, toggle) => Focus(
        focusNode: focus,
        skipTraversal: true,
        child: FrostButton.icon(
          label: t.discovery.sort.title,
          icon: appIcons.sort,
          size: FrostControlSize.compact,
          selected: !isDefault,
          onPressed: toggle,
        ),
      ),
    ),
    overflowEntry: FrostMenuSubmenu(
      t.discovery.sort.title,
      leading: FrostGlyph.icon(appIcons.sort),
      entries: entries,
    ),
  );
}

/// The sort button at the end of a tab row: the sort in effect, as a menu.
class SortTabButton extends StatelessWidget {
  const SortTabButton(this.choice, {super.key});
  final SortChoice choice;

  @override
  Widget build(BuildContext context) => FrostMenuAnchor(
    entries: choice.entries,
    builder: (context, focus, toggle) => Focus(
      focusNode: focus,
      child: FrostButton.plain(
        label: sortLabel(choice.selected),
        icon: appIcons.sort,
        size: FrostControlSize.compact,
        chevron: FrostButtonChevron.down,
        onPressed: toggle,
      ),
    ),
  );
}

/// Opens the sort menu below [anchor], the widget that asked for it.
Future<void> showSortMenu(BuildContext anchor, SortChoice choice) {
  final box = anchor.findRenderObject();
  if (box is! RenderBox || !box.attached) return Future.value();
  return showFrostContextMenu(
    context: anchor,
    globalPosition: box.localToGlobal(box.size.bottomLeft(Offset.zero)),
    entries: choice.entries,
  );
}
