import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/tags/edit_user_tag.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The context menu of a tag wherever one is shown: the post's tags, the Tags
/// pages and the search suggestions. [raw] is the tag as the source spells it.
/// [query] is the search being refined: adding and excluding extend it.
List<FrostMenuEntry> tagMenuEntries(
  BuildContext context,
  String raw, {
  required String sourceId,
  List<String> query = const [],
}) {
  List<String> refined(String tag) => [...query, if (!query.contains(tag)) tag];
  return [
    FrostMenuAction(
      t.postDetail.searchTag,
      leading: FrostGlyph.icon(appIcons.search),
      onSelected: () => context.pushTaggedPosts([raw], sourceId: sourceId),
    ),
    FrostMenuAction(
      t.postDetail.addToSearch,
      leading: FrostGlyph.icon(appIcons.add),
      onSelected: () => query.isEmpty
          ? context.openSearch(raw, sourceId: sourceId)
          : context.pushTaggedPosts(refined(raw), sourceId: sourceId),
    ),
    FrostMenuAction(
      t.postDetail.excludeTag,
      leading: FrostGlyph.icon(appIcons.remove),
      onSelected: () =>
          context.pushTaggedPosts(refined('-$raw'), sourceId: sourceId),
    ),
    FrostMenuAction(
      t.discovery.addCustomTag,
      leading: FrostGlyph.icon(appIcons.edit),
      onSelected: () => editUserTag(
        context,
        source: sourceId,
        locale: LocaleSettings.currentLocale.languageTag,
        value: raw,
      ),
    ),
    FrostMenuAction(
      t.frost.copy,
      leading: FrostGlyph.icon(appIcons.copy),
      onSelected: () =>
          performPostAction(context, () => copyPostValue(context, raw)),
    ),
  ];
}
