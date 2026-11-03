import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/browse/collection_actions.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/widgets/post_waterfall.dart';
import 'package:booruflow/features/browse/widgets/query_title.dart';
import 'package:booruflow/features/browse/widgets/rating_filter.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/tags/edit_user_tag.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The posts matching a query, as a second-level page of the destination that
/// opened it.
class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({required this.tags, required this.sourceId, super.key});
  final List<String> tags;
  final String sourceId;
  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage>
    with CollectionActions<ResultsPage> {
  final _search = FrostPageHeaderSearchController();

  @override
  String get sourceId => widget.sourceId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  CollectionKey get collectionKey => CollectionKey(
    sourceId: sourceId,
    request: TagSearchCollectionRequest(widget.tags),
    ratings: ref.read(settingsProvider).ratings,
    revision: ref.read(booruSessionProvider).revision,
  );

  /// Another source runs the same query in place of this page.
  void _selectSource(String id) {
    if (id == sourceId) return;
    ref.read(booruSessionProvider.notifier).selectSource(id);
    context.replaceTaggedPosts(widget.tags, sourceId: id);
  }

  Future<void> _saveTag() async {
    final tags = widget.tags;
    // Aliases name one canonical source tag; a multi-term result offers its
    // terms rather than storing an invalid space-separated alias.
    final tag = tags.length == 1
        ? tags.single
        : await showFrostSheet<String>(
            context: context,
            title: t.discovery.addCustomTag,
            detents: const [FrostSheetDetent.fitted],
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tag in tags)
                  FrostListRow(
                    title: tag,
                    onPressed: () => Navigator.of(context).pop(tag),
                  ),
              ],
            ),
          );
    if (!mounted || tag == null) return;
    await editUserTag(
      context,
      source: sourceId,
      locale: Localizations.localeOf(context).toLanguageTag(),
      value: QueryTerm.parse(tag).value,
    );
  }

  @override
  Widget build(BuildContext context) {
    watchBatch();
    ref.watch(booruSessionProvider);
    ref.watch(settingsProvider.select((s) => s.ratings));
    final sources = ref.watch(booruSourcesProvider);
    final inlineSearch = !FrostShell.titleContentInCaptionOf(context);
    final sourceEntries = [
      for (final item in sources)
        FrostMenuAction(
          item.displayName,
          checked: item.sourceId == sourceId,
          onSelected: () => _selectSource(item.sourceId),
        ),
    ];
    return PostWaterfall(
      collection: (key: collectionKey, loader: null),
      filterBar: const RatingConditions(),
      header: (context, collection) => FrostPageHeader(
        middle: inlineSearch
            ? InlineSearch(
                sourceId: sourceId,
                query: widget.tags,
                replace: true,
                controller: _search,
              )
            : null,
        searchController: _search,
        // Beside the search field the row belongs to the query, which is what
        // this page is about; the source moves into the more menu.
        leading: [
          if (!inlineSearch)
            FrostTitleMenu(title: source.displayName, entries: sourceEntries),
        ],
        title: inlineSearch ? null : QueryTitle(widget.tags),
        actions: toolbar(
          collection,
          more: [
            if (inlineSearch)
              FrostMenuSubmenu(
                source.displayName,
                leading: FrostGlyph.icon(appIcons.image),
                entries: sourceEntries,
              ),
            FrostMenuAction(
              t.discovery.addCustomTag,
              leading: FrostGlyph.icon(appIcons.add),
              onSelected: _saveTag,
            ),
          ],
        ),
      ),
    );
  }
}
