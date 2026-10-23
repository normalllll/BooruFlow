// Deterministic repository for preview boards only; production never imports it.
import 'dart:async';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/src/rust/api/booru_models.dart' show TagCategory;

class PreviewSearchRepository extends TagSuggestionRepository {
  PreviewSearchRepository(this.board);
  final String board;
  final _events = StreamController<void>.broadcast(sync: true);
  final _next = Completer<List<TagSuggestion>>();
  late final _aliases = board == 'Q03'
      ? <UserTagAlias>[]
      : [
          for (final (i, value) in [
            ('夕阳风景', 'scenery sunset', '*'),
            ('初音', 'hatsune_miku', '*'),
            (
              '壁纸',
              'wallpaper',
              const {'Q05', 'Q06', 'Q11'}.contains(board) ? 'wallhaven' : '*',
            ),
            if (const {'Q05', 'Q06', 'Q11'}.contains(board)) ...[
              ('芙莉莲', 'frieren', 'danbooru'),
              ('原神', 'genshin_impact', '*'),
              ('碧蓝航线', 'azur_lane', 'yande'),
            ],
          ].indexed)
            UserTagAlias(
              id: 'preview-$i',
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
  late final commonTags = board == 'Q03'
      ? [
          tag('original', '原创', TagCategory.copyright),
          tag('genshin_impact', '原神', TagCategory.copyright),
          tag('azur_lane', '碧蓝航线', TagCategory.copyright),
          tag('dress', '连衣裙', TagCategory.general),
          tag('wings', '翅膀', TagCategory.general),
          tag('thighhighs', '过膝袜', TagCategory.general),
          tag('horns', '角', TagCategory.general),
          tag('sky', '天空', TagCategory.general),
        ]
      : [
          tag('mika_pikazo', null, TagCategory.artist),
          tag('wlop', null, TagCategory.artist),
          tag('void_0', null, TagCategory.artist),
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
  late final allTags = [
    tag('1girl', null, TagCategory.general, '5912004'),
    tag('solo', null, TagCategory.general, '4820331'),
    tag('long_hair', '长发', TagCategory.general, '3904112'),
    tag('original', '原创', TagCategory.copyright, '1402550'),
    tag('hatsune_miku', '初音未来', TagCategory.character, '160204'),
    tag('blue_archive', '蔚蓝档案', TagCategory.copyright, '140875'),
    tag('scenery', '风景', TagCategory.general, '98301'),
    tag('frieren', '芙莉莲', TagCategory.character, '41226'),
    tag('wlop', null, TagCategory.artist, '1204'),
    tag('highres', '高分辨率', TagCategory.meta, '6104887'),
    for (var i = 10; i < 50; i++)
      tag('landscape_$i', '风景 $i', TagCategory.general, '${10000 - i}'),
  ];
  late final cloudTags = [
    tag('cloud', '云', TagCategory.general, '1204331'),
    tag('cloudy_sky', '多云的天空', TagCategory.general, '88410'),
    tag('clouds', '云层', TagCategory.general, '52106'),
    tag('cloud_strife', '克劳德·斯特莱夫', TagCategory.character, '21077'),
    tag('cumulonimbus_cloud', '积雨云', TagCategory.general, '4312'),
    if (board == 'Q09')
      tag('cloud_hair_ornament', '云形发饰', TagCategory.general, '1900'),
  ];
  @override
  Future<void> initialize() async {}
  @override
  Stream<void> get changes => _events.stream;
  @override
  List<UserTagAlias> get aliases =>
      List.unmodifiable(board == 'Q08' ? _aliases.take(2) : _aliases);
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
  Future<List<String>> recentSearches(String source) async => board == 'Q03'
      ? []
      : List.of(board == 'Q08' ? _history.take(3) : _history);
  @override
  Future<void> removeSearch(String source, String query) async =>
      _history.remove(query);
  @override
  Future<void> clearSearches(String source) async => _history.clear();
  @override
  Future<void> remember(String source, List<String> tags) async {
    final q = tags.join(' ');
    _history.remove(q);
    _history.insert(0, q);
  }

  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async {
    if (page > 1) return _next.future;
    return board == 'Q08'
        ? commonTags
              .where(
                (tag) => const {
                  'hatsune_miku',
                  'frieren',
                  'scenery',
                  'sky',
                  'night',
                  'flower',
                }.contains(tag.value),
              )
              .toList()
        : commonTags;
  }

  @override
  List<TagSuggestion> local(String source, String locale, String text) => [];
  @override
  Future<List<TagSuggestion>> remote(
    String source,
    String locale,
    String text,
  ) async => text.startsWith('clou')
      ? cloudTags
      : [
          for (final item in [
            ...commonTags,
            tag('landscape', '风景', TagCategory.general),
          ])
            if (item.value.startsWith(text)) item,
        ];
  @override
  List<TagSuggestion> merge(
    String source,
    String locale,
    String text,
    Iterable<TagSuggestion> values,
  ) => values.toList();
  @override
  String? displayName(String source, String locale, String value) => [
    ...commonTags,
    ...allTags,
    ...cloudTags,
    tag('twintails', '双马尾', TagCategory.general),
    tag('sunset', '日落', TagCategory.general),
    tag('cityscape', '城市风景', TagCategory.general),
    tag('horns', '角', TagCategory.general),
  ].where((tag) => tag.value == value).firstOrNull?.displayName;
  Future<void> dispose() => _events.close();
}
