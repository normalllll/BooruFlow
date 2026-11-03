import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/tag_menu.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/src/rust/api/booru_models.dart' show TagCategory;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

const _categories = [
  TagCategory.artist,
  TagCategory.character,
  TagCategory.copyright,
  TagCategory.general,
  TagCategory.meta,
];

/// Every common tag of [sourceId], most used first, loaded page by page. The
/// category filter works on what has loaded.
class AllCommonTagsPage extends ConsumerStatefulWidget {
  const AllCommonTagsPage({required this.sourceId, super.key});
  final String sourceId;

  @override
  ConsumerState<AllCommonTagsPage> createState() => _AllCommonTagsPageState();
}

class _AllCommonTagsPageState extends ConsumerState<AllCommonTagsPage> {
  TagCategory? _category;
  _CommonTagsSource? _source;
  String? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale == locale && _source != null) return;
    _locale = locale;
    _source?.dispose();
    _source = _makeSource();
  }

  _CommonTagsSource _makeSource() => _CommonTagsSource(
    ref.read(tagSuggestionRepositoryProvider),
    widget.sourceId,
    _locale!,
    firstPage: (refresh) async {
      final common = commonTagsProvider(widget.sourceId, _locale!);
      if (refresh) await ref.read(common.notifier).reload();
      return ref.read(common.future);
    },
  );

  @override
  void didUpdateWidget(AllCommonTagsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceId != widget.sourceId) {
      _source?.dispose();
      _source = _makeSource();
    }
  }

  @override
  void dispose() {
    _source?.dispose();
    super.dispose();
  }

  Widget _row(TagSuggestion tag, NumberFormat format, int index) {
    final source = _source!;
    final translation = distinctTagTranslation(
      tag.value,
      source.repository.displayName(
            source.sourceId,
            source.locale,
            tag.value,
          ) ??
          tag.displayName,
    );
    final count = int.tryParse(tag.count ?? '');
    return Column(
      children: [
        FrostListRow(
          title: tag.value,
          subtitle: translation == null
              ? null
              : FrostRowSubtitle.inline(translation),
          leading: FrostLeading.custom(FrostDataDot(tag.category.colorIndex)),
          value: tag.count == null
              ? null
              : count == null
              ? tag.count
              : format.format(count),
          onPressed: () =>
              context.pushTaggedPosts([tag.value], sourceId: widget.sourceId),
          contextMenu: tagMenuEntries(
            context,
            tag.value,
            sourceId: widget.sourceId,
          ),
        ),
        const FrostDivider(inset: FrostDividerInset.keyline),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return AppPage(
      header: FrostPageHeader(
        title: FrostText(t.discovery.commonTags),
        actions: [
          FrostToolbarItem.menu(
            label: t.discovery.category,
            valueLabel: _category == null
                ? t.discovery.allCategories
                : categoryLabel(_category!),
            priority: FrostToolbarPriority.high,
            entries: [
              FrostMenuAction(
                t.discovery.allCategories,
                checked: _category == null,
                onSelected: () => setState(() => _category = null),
              ),
              for (final category in _categories)
                FrostMenuAction(
                  categoryLabel(category),
                  checked: category == _category,
                  onSelected: () => setState(() => _category = category),
                ),
            ],
          ),
        ],
      ),
      slivers: [
        FrostSliverDataList<TagSuggestion>(
          source: _source!,
          empty: FrostEmptyState(
            icon: const FrostIconData.glyph(BooruFlowIcons.tags),
            title: t.discovery.noCommonTags,
          ),
          firstLoadSkeleton: Column(
            children: [
              for (final title in ['landscape', 'scenery', 'blue_sky'])
                FrostListRow(
                  title: title,
                  leading: const FrostLeading.custom(FrostDataDot(0)),
                  value: '1,234,567',
                ),
            ],
          ).frostSkeleton(true),
          itemBuilder: (context, tag, index) =>
              _category == null || tag.category == _category
              ? _row(tag, format, index)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The first page is the one shared with the rest of the app ([firstPage],
/// asked to load afresh on a refresh); later pages come from the repository.
class _CommonTagsSource extends FrostListSource<TagSuggestion> {
  _CommonTagsSource(
    this.repository,
    this.sourceId,
    this.locale, {
    required this.firstPage,
  });
  final TagSuggestionRepository repository;
  final String sourceId, locale;
  final Future<List<TagSuggestion>> Function(bool refresh) firstPage;
  int _page = 0;
  bool _more = true;
  bool _loadedFirst = false;

  @override
  Future<List<TagSuggestion>> initList() => _fetch(1);

  @override
  Future<List<TagSuggestion>> nextList() => _fetch(_page + 1);

  @override
  bool hasMoreByResult(List<TagSuggestion> items) => _more;

  Future<List<TagSuggestion>> _fetch(int page) async {
    try {
      final tags = page == 1
          ? await firstPage(_loadedFirst)
          : await repository.common(sourceId, locale, page: page);
      if (page == 1) _loadedFirst = true;
      final seen = page == 1
          ? <String>{}
          : items.map((tag) => tag.value).toSet();
      _page = page;
      _more = tags.length == 50;
      return [
        for (final tag in tags)
          if (seen.add(tag.value)) tag,
      ];
    } catch (error) {
      throw makeBooruErrorReadable(error);
    }
  }
}
