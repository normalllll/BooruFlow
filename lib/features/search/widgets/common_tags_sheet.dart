import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart' show TagCategory;
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

/// Common tags share the source cache and pagination. The owning modal supplies
/// the primary scroll controller; the category filter does not refetch pages.
class CommonTagsSheet extends StatefulWidget {
  const CommonTagsSheet({
    super.key,
    required this.repository,
    required this.source,
    required this.locale,
    required this.initialTags,
  });
  final TagSuggestionRepository repository;
  final String source, locale;
  final List<TagSuggestion> initialTags;
  @override
  State<CommonTagsSheet> createState() => _CommonTagsSheetState();
}

class _CommonTagsSheetState extends State<CommonTagsSheet> {
  TagCategory? _category;
  late final _CommonTagsSource _source;
  @override
  void initState() {
    super.initState();
    _source = _CommonTagsSource(
      widget.repository,
      widget.source,
      widget.locale,
      widget.initialTags,
    );
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  Widget _row(TagSuggestion tag, NumberFormat format) {
    final translation = distinctTagTranslation(
      tag.value,
      widget.repository.displayName(widget.source, widget.locale, tag.value) ??
          tag.displayName,
    );
    final count = int.tryParse(tag.count ?? '');
    return FrostListRow(
      title: tag.value,
      subtitle: translation,
      inlineSubtitle: true,
      leading: FrostDataDot(tag.category.colorIndex),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.count != null) ...[
            FrostText(
              count == null ? tag.count! : format.format(count),
              role: FrostTextRole.footnote,
              tone: FrostTextTone.tertiary,
              numeric: true,
            ),
            const SizedBox(width: FrostGap.related),
          ],
          FrostButton.icon(
            icon: appIcons.add,
            label: t.discovery.addTag,
            size: FrostControlSize.compact,
            onPressed: () => Navigator.of(context).pop(tag),
          ),
        ],
      ),
      onPressed: () => Navigator.of(context).pop(tag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
          child: FrostPicker<TagCategory?>.segmented(
            label: t.discovery.commonTags,
            value: _category,
            options: [
              FrostPickerOption(value: null, label: t.downloads.all),
              for (final category in [
                TagCategory.artist,
                TagCategory.character,
                TagCategory.copyright,
                TagCategory.general,
              ])
                FrostPickerOption(
                  value: category,
                  label: categoryLabel(category),
                ),
            ],
            onChanged: (value) => setState(() => _category = value),
          ),
        ),
        Expanded(
          child: FrostLoadingScrollView(
            slivers: [
              FrostSliverDataList<TagSuggestion>(
                source: _source,
                firstLoadSkeleton: Column(
                  children: [
                    for (final title in ['landscape', 'scenery'])
                      FrostListRow(
                        title: title,
                        leading: const FrostDataDot(0),
                        value: '1,234,567',
                      ).frostSkeleton(true),
                  ],
                ),
                itemBuilder: (context, tag, index) =>
                    _category == null || tag.category == _category
                    ? _row(tag, format)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The modal owns paging. The repository still owns its real first-page cache;
/// changing the local category only changes row visibility, not the request.
class _CommonTagsSource extends FrostListSource<TagSuggestion> {
  _CommonTagsSource(this.repository, this.source, this.locale, this.seed);
  final TagSuggestionRepository repository;
  final String source, locale;
  final List<TagSuggestion> seed;
  int _page = 0;
  bool _more = true;
  bool _seedAvailable = true;
  @override
  Future<List<TagSuggestion>> initList() async {
    if (_seedAvailable) {
      _seedAvailable = false;
      _page = 1;
      _more = seed.length == 50;
      return seed;
    }
    return _fetch(1);
  }

  @override
  Future<List<TagSuggestion>> nextList() => _fetch(_page + 1);
  @override
  bool hasMoreByResult(List<TagSuggestion> items) => _more;
  Future<List<TagSuggestion>> _fetch(int page) async {
    try {
      final tags = await repository.common(
        source,
        locale,
        page: page,
        refresh: page == 1,
      );
      final seen = page == 1
          ? <String>{}
          : items.map((tag) => tag.value).toSet();
      final result = [
        for (final tag in tags)
          if (seen.add(tag.value)) tag,
      ];
      _page = page;
      _more = tags.length == 50;
      return result;
    } catch (error) {
      throw makeBooruErrorReadable(error);
    }
  }
}
