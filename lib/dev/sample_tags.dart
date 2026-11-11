import 'dart:async';

import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/src/rust/api/booru_models.dart' show TagCategory;

/// Tag suggestions, aliases and search history kept in memory.
class SampleTagRepository extends TagSuggestionRepository {
  final _events = StreamController<void>.broadcast(sync: true);
  final _aliases = <UserTagAlias>[
    for (final (i, value) in [
      ('夕阳风景', 'scenery sunset', '*'),
      ('初音', 'hatsune_miku', '*'),
      ('壁纸', 'wallpaper', '*'),
    ].indexed)
      UserTagAlias(
        id: 'sample-$i',
        value: value.$2,
        sourceId: value.$3,
        locale: 'zh-CN',
        displayName: value.$1,
      ),
  ];
  final _history = <String>[
    'landscape sky scenery',
    'hatsune_miku rating:general',
    'original 1girl outdoors',
    'scenery night city',
  ];

  static TagSuggestion tag(
    String value,
    String? translation,
    TagCategory category, [
    String? count,
  ]) => TagSuggestion(
    value: value,
    displayName: translation,
    category: category,
    count: count,
    origin: SuggestionOrigin.sourceApi,
    verified: true,
  );

  late final commonTags = [
    tag('mika_pikazo', null, TagCategory.artist),
    tag('wlop', null, TagCategory.artist),
    tag('hatsune_miku', '初音未来', TagCategory.character),
    tag('frieren', '芙莉莲', TagCategory.character),
    tag('rem', '蕾姆', TagCategory.character),
    tag('vocaloid', null, TagCategory.copyright),
    tag('genshin_impact', '原神', TagCategory.copyright),
    tag('blue_archive', '蔚蓝档案', TagCategory.copyright),
    tag('scenery', '风景', TagCategory.general),
    tag('sky', '天空', TagCategory.general),
    tag('night', '夜晚', TagCategory.general),
    tag('flower', '花', TagCategory.general),
    tag('city', '城市', TagCategory.general),
    tag('1girl', null, TagCategory.general),
  ];
  late final _allTags = [
    ...commonTags,
    tag('cloud', '云', TagCategory.general, '1204331'),
    tag('cloudy_sky', '多云的天空', TagCategory.general, '88410'),
    tag('twintails', '双马尾', TagCategory.general),
    tag('sunset', '日落', TagCategory.general),
    tag('landscape', '风景', TagCategory.general),
  ];

  @override
  Future<void> initialize() async {}
  @override
  Stream<void> get changes => _events.stream;
  @override
  List<UserTagAlias> get aliases => List.unmodifiable(_aliases);
  @override
  Future<void> saveAlias(UserTagAlias alias) async {
    _aliases.removeWhere((value) => value.id == alias.id);
    _aliases.add(alias);
    _events.add(null);
  }

  @override
  Future<void> deleteAlias(String id) async {
    _aliases.removeWhere((value) => value.id == id);
    _events.add(null);
  }

  @override
  Future<List<String>> recentSearches(String source) async => List.of(_history);
  @override
  Future<void> removeSearch(String source, String query) async =>
      _history.remove(query);
  @override
  Future<void> clearSearches(String source) async => _history.clear();
  @override
  Future<void> remember(String source, List<String> tags) async {
    final query = tags.join(' ');
    _history.remove(query);
    _history.insert(0, query);
  }

  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async => page > 1 ? const [] : commonTags;
  @override
  List<TagSuggestion> local(String source, String locale, String text) => [];
  @override
  Future<List<TagSuggestion>> remote(
    String source,
    String locale,
    String text,
  ) async => [
    for (final item in _allTags)
      if (item.value.startsWith(text)) item,
  ];
  @override
  List<TagSuggestion> merge(
    String source,
    String locale,
    String text,
    Iterable<TagSuggestion> suggestions,
  ) => suggestions.toList();
  @override
  String? displayName(String source, String locale, String value) =>
      _allTags.where((tag) => tag.value == value).firstOrNull?.displayName;
}
