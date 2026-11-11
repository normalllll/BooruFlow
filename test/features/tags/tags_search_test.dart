// Tags and search: query editing, tag menu and search pages. Asserts through
// Frost widget types, i18n keys, routes and fake repository state.
//
// Layouts: "wide" is a 1440x900 desktop window (sidebar, the search lives in
// the title bar as FrostCaptionSearch); "compact" is a 390x844 touch window
// (bottom bar, the search lives in the page header as InlineSearch).
// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/common_tags_page.dart';
import 'package:booruflow/features/tags/my_tags_page.dart';
import 'package:booruflow/features/tags/tag_menu.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/features/tags/tags_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../../support/browse_support.dart';

// ---------------------------------------------------------------------------
// Fakes and data
// ---------------------------------------------------------------------------

final class _MemoryStore implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

class _Downloads extends DownloadItems {
  @override
  List<BooruDownloadItem> build() => [];
}

BooruSource _source(String id) => BooruSource(
  sourceId: id,
  displayName: id,
  protocol: BooruProtocol.moebooru,
  enabledByDefault: true,
  isAiSource: false,
  capabilities: const SourceCapabilities(
    discovery: DiscoveryCapabilities(
      popular: CapabilityAvailability.unsupported,
      commonTags: CapabilityAvailability.available,
      popularRanges: [],
      historicalRanges: [],
      timeBasis: PopularTimeBasis.indexTimeWindow,
      additionalFeeds: [],
      autocompleteMinChars: 1,
    ),
    ratings: [ContentRating.general],
    authKind: AuthKind.none,
    supportsSearch: true,
    supportsPostDetail: true,
    supportsAutocomplete: true,
    supportsRelatedPosts: false,
    supportsOriginal: true,
    supportsAuthenticatedMedia: false,
    supportsBackgroundDownload: true,
  ),
);

/// The one tag repository every page reads: history, aliases, common tags and
/// typed suggestions are plain fields the tests set before mounting.
class _Repo extends TagSuggestionRepository {
  final events = StreamController<void>.broadcast(sync: true);
  final stored = <UserTagAlias>[];
  final history = <String, List<String>>{};

  /// What [common] returns per page; page 1 falls back to [commonItems].
  List<TagSuggestion> commonItems = _commonItems;
  final commonPages = <int, List<TagSuggestion>>{};
  final commonCalls = <int>[];
  bool failCommon = false;

  /// Remote suggestions by the typed word (the term at the caret, no operator).
  final suggestions = <String, List<TagSuggestion>>{};
  final remoteCalls = <String>[];

  @override
  Stream<void> get changes => events.stream;
  @override
  Future<void> initialize() async {}
  @override
  List<UserTagAlias> get aliases => List.of(stored);
  @override
  Future<void> saveAlias(UserTagAlias alias) async {
    stored.removeWhere((value) => value.id == alias.id);
    stored.add(alias);
    events.add(null);
  }

  @override
  Future<void> deleteAlias(String id) async {
    stored.removeWhere((value) => value.id == id);
    events.add(null);
  }

  @override
  String? displayName(String source, String locale, String value) => null;
  @override
  List<TagSuggestion> local(String source, String locale, String text) => [];
  @override
  List<TagSuggestion> merge(
    String source,
    String locale,
    String text,
    Iterable<TagSuggestion> values,
  ) => values.toList();
  @override
  Future<List<TagSuggestion>> remote(
    String source,
    String locale,
    String text,
  ) async {
    remoteCalls.add(text);
    return suggestions[text] ?? [];
  }

  @override
  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async {
    commonCalls.add(page);
    if (failCommon) throw StateError('offline');
    return commonPages[page] ?? (page == 1 ? commonItems : const []);
  }

  @override
  Future<List<String>> recentSearches(String source) async =>
      List.of(history[source] ?? []);
  @override
  Future<void> removeSearch(String source, String query) async =>
      history[source]?.remove(query);
  @override
  Future<void> clearSearches(String source) async => history[source] = [];
  @override
  Future<void> remember(String source, List<String> tags) async {
    history[source] = {tags.join(' '), ...?history[source]}.toList();
  }
}

TagSuggestion _tagSuggestion(
  String value,
  TagCategory category,
  String count,
) => TagSuggestion(
  value: value,
  category: category,
  count: count,
  origin: SuggestionOrigin.sourceApi,
  verified: true,
);

/// Most used first, one or more tags in every category.
final _commonItems = [
  _tagSuggestion('1girl', TagCategory.general, '5000000'),
  _tagSuggestion('highres', TagCategory.meta, '3000000'),
  _tagSuggestion('sky', TagCategory.general, '400000'),
  _tagSuggestion('hatsune_miku', TagCategory.character, '160204'),
  _tagSuggestion('genshin_impact', TagCategory.copyright, '90000'),
  _tagSuggestion('wlop', TagCategory.artist, '1204'),
  _tagSuggestion('mika_pikazo', TagCategory.artist, '880'),
];

/// More than the eight a drop-down shows, newest first.
const _recents = [
  'sky -cloud',
  'blue_eyes',
  'wlop',
  'long_hair',
  'solo',
  'smile',
  'scenery',
  'flower',
  'night',
  'rain',
  'cat',
  'dog',
];

UserTagAlias _alias(
  String id,
  String value,
  String display, {
  String source = UserTagAlias.allSources,
}) => UserTagAlias(
  id: id,
  value: value,
  sourceId: source,
  locale: 'en',
  displayName: display,
);

final _myTags = [
  _alias('a1', 'sky_blue', 'My Sky'),
  _alias('a2', 'tower', 'Tower', source: 'yande'),
];

BooruPost _booruPost(String id) => BooruPost(
  sourceId: 'yande',
  postId: id,
  postKey: 'yande:$id',
  rating: ContentRating.general,
  tags: const [
    BooruTag(name: 'actual_artist', category: TagCategory.artist),
    BooruTag(name: 'sky', category: TagCategory.general),
  ],
  media: const [
    MediaVariant(
      kind: MediaVariantKind.sample,
      url: 'https://example.invalid/sample.png',
      width: 600,
      height: 800,
    ),
  ],
  webUrl: 'https://yande.re/post/show/$id',
  flags: const PostFlags(
    hasChildren: false,
    isPending: false,
    isDeleted: false,
    isAiGenerated: false,
  ),
);

late _Repo repo;

// ---------------------------------------------------------------------------
// Layouts and finders
// ---------------------------------------------------------------------------

class _Layout {
  const _Layout(this.name, this.size, this.platform, {required this.compact});
  final String name;
  final Size size;
  final TargetPlatform platform;

  /// Bottom bar: the search is the page header's inline search.
  final bool compact;

  /// Where this layout's search field lives: the title bar or the page header.
  Finder get search =>
      compact ? find.byType(FrostPageHeader) : find.byType(FrostCaptionSearch);

  /// Where its suggestion list is drawn: the title bar drop-down, or (compact)
  /// the page body below the header, so anywhere in the app.
  Finder get suggestionScope =>
      compact ? find.byType(BooruFlowApp) : find.byType(FrostCaptionSearch);
}

const _wide = _Layout(
  'wide',
  Size(1440, 900),
  TargetPlatform.windows,
  compact: false,
);
const _compact = _Layout(
  'compact',
  Size(390, 844),
  TargetPlatform.android,
  compact: true,
);

Finder _editor(_Layout layout) =>
    find.descendant(of: layout.search, matching: find.byType(EditableText));

FrostSearchInput _input(WidgetTester tester, _Layout layout) =>
    tester.widget<FrostSearchInput>(
      find.descendant(
        of: layout.search,
        matching: find.byType(FrostSearchInput),
      ),
    );

String _queryText(WidgetTester tester, _Layout layout) =>
    _input(tester, layout).controller.text;

List<FrostSearchSection> _groups(WidgetTester tester, _Layout layout) {
  final content = _input(tester, layout).content;
  return content is Column
      ? content.children.whereType<FrostSearchSection>().toList()
      : const [];
}

List<String> _tokens(String text) =>
    text.trim().isEmpty ? [] : text.trim().split(RegExp(r'\s+'));

Finder _tag(String label) => find.byWidgetPredicate(
  (w) => w is FrostTag && w.label == label,
  description: 'FrostTag "$label"',
);

Finder _row(String title) => find.byWidgetPredicate(
  (w) => w is FrostListRow && w.title == title,
  description: 'FrostListRow "$title"',
);

Finder get _cancel => find.text(t.frost.cancel).hitTestable();

String _categoryLabel(TagCategory category) => switch (category) {
  TagCategory.artist => t.discovery.artist,
  TagCategory.character => t.discovery.character,
  TagCategory.copyright => t.discovery.copyright,
  TagCategory.meta => t.discovery.meta,
  TagCategory.general => t.discovery.general,
};

List<String> get _menuLabels => [
  t.postDetail.searchTag,
  t.postDetail.addToSearch,
  t.postDetail.excludeTag,
  t.discovery.addCustomTag,
  t.frost.copy,
];

List<String> _actionLabels(List<FrostMenuEntry> entries) =>
    entries.whereType<FrostMenuAction>().map((entry) => entry.label).toList();

bool _holds(List<FrostMenuEntry> entries, String label) => entries.any(
  (entry) => switch (entry) {
    FrostMenuAction() => entry.label == label,
    FrostMenuSection() => _holds(entry.entries, label),
    FrostMenuSubmenu() => _holds(entry.entries, label),
    _ => false,
  },
);

/// The menu in the page header that offers [label].
Finder _headerMenu(String label) => find.descendant(
  of: find.byType(FrostPageHeader),
  matching: find.byWidgetPredicate(
    (w) => switch (w) {
      FrostToolbarMenuButton() => _holds(w.entries, label),
      FrostTitleMenu() => _holds(w.entries, label),
      _ => false,
    },
    description: 'a header menu offering "$label"',
  ),
);

/// The text action at the end of the section header titled [title].
Finder _sectionAction(WidgetTester tester, String title) {
  final header = find.byWidgetPredicate(
    (w) => w is FrostSectionHeader && w.title == title,
    description: 'FrostSectionHeader "$title"',
  );
  expect(header, findsOneWidget);
  final label = tester.widget<FrostSectionHeader>(header).actionLabel;
  expect(label, isNotNull, reason: 'the "$title" section has an action');
  return find.descendant(of: header, matching: find.text(label!));
}

/// The text action of the drop-down group titled [title].
Finder _groupAction(WidgetTester tester, _Layout layout, String title) {
  final group = _groups(
    tester,
    layout,
  ).where((group) => group.title == title).singleOrNull;
  expect(group, isNotNull, reason: 'a "$title" group is listed');
  expect(group!.actionLabel, isNotNull);
  expect(group.onAction, isNotNull);
  return find
      .descendant(
        of: layout.suggestionScope,
        matching: find.text(group.actionLabel!),
      )
      .hitTestable()
      .first;
}

// ---------------------------------------------------------------------------
// Driving the app
// ---------------------------------------------------------------------------

String get _path => AppRouter.currentUri.path;

Future<void> _go(WidgetTester tester, String location) async {
  AppRouter.router.go(location);
  await tester.pumpAndSettle();
}

Future<void> _openResults(
  WidgetTester tester,
  List<String> tags, {
  String source = 'yande',
}) async {
  unawaited(
    AppRouter.router.push(
      Uri(
        path: '/results',
        queryParameters: {'tags': jsonEncode(tags), 'source': source},
      ).toString(),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _resultTags(WidgetTester tester) =>
    tester.widget<ResultsPage>(find.byType(ResultsPage)).tags;

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(FrostPageHeader).first);

Future<void> _focusSearch(WidgetTester tester, _Layout layout) async {
  await tester.showKeyboard(_editor(layout));
  await tester.pumpAndSettle();
}

/// Replaces the query in one edit, with the caret at [caret] (default: end),
/// and lets the suggestion debounce pass.
Future<void> _type(
  WidgetTester tester,
  _Layout layout,
  String text, {
  int? caret,
}) async {
  await _focusSearch(tester, layout);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

/// Secondary click with a pointer, long press on touch.
Future<void> _openMenu(
  WidgetTester tester,
  _Layout layout,
  Finder target,
) async {
  if (layout.compact) {
    await tester.longPress(target);
  } else {
    await tester.tap(target, buttons: kSecondaryButton);
  }
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).hitTestable().last);
  await tester.pumpAndSettle();
}

Future<void> _chooseFromHeaderMenu(WidgetTester tester, String label) async {
  final menu = _headerMenu(label);
  expect(menu, findsWidgets);
  await tester.tap(menu.hitTestable().first);
  await tester.pumpAndSettle();
  await _choose(tester, label);
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

const _channel = MethodChannel('frost_window');

/// The whole app (real router, shell, title bar) at [layout]'s size. [arrange]
/// fills the repository before anything reads it.
Future<void> _mountApp(WidgetTester tester, _Layout layout) async {
  tester.view.physicalSize = layout.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          downloadItemsProvider.overrideWith(_Downloads.new),
          tagSuggestionRepositoryProvider.overrideWithValue(repo),
          collectionLoaderProvider.overrideWithValue(
            (_, _) async => const PostPage(items: [], exhausted: true),
          ),
        ],
        child: BooruFlowApp(
          windowController: FrostWindowController(
            minimumSize: const Size(320, 480),
          ),
          checkUpdates: false,
        ),
      ),
    ),
  );
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// One test per layout, on the platform that layout belongs to.
void _appTest(
  String name,
  Set<_Layout> layouts,
  Future<void> Function(WidgetTester tester, _Layout layout) body, {
  void Function()? arrange,
}) {
  for (final layout in layouts) {
    testWidgets('$name (${layout.name})', (tester) async {
      arrange?.call();
      await _mountApp(tester, layout);
      await body(tester, layout);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(layout.platform));
  }
}

/// A page on its own inside a Frost app, for the tests that need no router.
Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(1147, 717),
  TargetPlatform platform = TargetPlatform.windows,
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        downloadItemsProvider.overrideWith(_Downloads.new),
        tagSuggestionRepositoryProvider.overrideWithValue(repo),
        collectionLoaderProvider.overrideWithValue(
          (_, _) async => const PostPage(items: [], exhausted: true),
        ),
      ],
      child: browseTestApp(page, scale: scale, platform: platform),
    ),
  );
  for (var frame = 0; frame < 16; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() async {
    await SettingsService.initialize(store: _MemoryStore());
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting([
      _source('yande'),
      _source('danbooru'),
    ]);
    repo = _Repo();
    addTearDown(() => repo.events.close());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _channel,
          (call) async => call.method == 'getState'
              ? {
                  'revision': 0,
                  'active': true,
                  'captionMode': 'client',
                  'leftButtons': <String>[],
                  'rightButtons': ['minimize', 'maximize', 'close'],
                  'nativeControls': [0.0, 0.0, 0.0, 0.0],
                }
              : null,
        );
    AppRouter.router.go('/');
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  // -------------------------------------------------------------------------
  // /tags mounts TagsPage
  // -------------------------------------------------------------------------

  _appTest('/tags mounts TagsPage, not PostSearchPage', {_wide, _compact}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    expect(_path, '/tags');
    expect(find.byType(TagsPage), findsOneWidget);
    expect(
      tester.widget<TagsPage>(find.byType(TagsPage)).invalidQuery,
      isFalse,
    );
    expect(
      find.byType(FrostInlineBanner),
      findsNothing,
      reason: 'a healthy page shows no banner',
    );
  });

  _appTest('the page header leads with the source, as Browse does', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    final header = find.byType(FrostPageHeader);
    expect(header, findsOneWidget);
    expect(
      find.descendant(of: header, matching: find.byType(FrostTitleMenu)),
      findsOneWidget,
    );
    // The title row names the page; the header keeps an unpainted copy for
    // screen readers.
    expect(
      find.ancestor(
        of: find.descendant(of: header, matching: find.text(t.navigation.tags)),
        matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 0),
      ),
      findsOneWidget,
      reason: 'the destination is not drawn again in the header',
    );
    expect(
      find.descendant(
        of: header,
        matching: find.byType(FrostCompactBackButton),
      ),
      findsNothing,
      reason: 'a destination root page has no back control',
    );
  });

  // -------------------------------------------------------------------------
  // my tags
  // -------------------------------------------------------------------------

  _appTest(
    'my tags shows the alias display name with the raw value as detail',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      for (final alias in _myTags) {
        final tag = _tag(alias.displayName!);
        expect(tag, findsOneWidget, reason: alias.displayName);
        expect(tester.widget<FrostTag>(tag).detail, alias.value);
      }
    },
    arrange: () => repo.stored.addAll(_myTags),
  );

  _appTest('the Manage action of my tags opens MyTagsPage', {_wide, _compact}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    await tester.tap(_sectionAction(tester, t.discovery.myTags));
    await tester.pumpAndSettle();
    expect(find.byType(MyTagsPage), findsOneWidget);
    expect(_path, '/tags/mine');
  }, arrange: () => repo.stored.addAll(_myTags));

  _appTest(
    'without aliases an add-tag button opens the tag editor',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      final add = find.byWidgetPredicate(
        (w) => w is FrostTag && w.label == t.discovery.addTag,
        description: 'the add tag button',
      );
      expect(add.hitTestable(), findsOneWidget);
      await tester.tap(add.hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(FrostForm), findsOneWidget);
    },
  );

  _appTest('pushUserTags opens MyTagsPage', {_wide}, (tester, layout) async {
    unawaited(_context(tester).pushUserTags<void>(sourceId: 'yande'));
    await tester.pumpAndSettle();
    expect(find.byType(MyTagsPage), findsOneWidget);
    expect(_path, '/tags/mine');
  });

  // -------------------------------------------------------------------------
  // common tags
  // -------------------------------------------------------------------------

  _appTest(
    'common tags are grouped under their category with the category dot',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      final labelTop = <TagCategory, double>{};
      for (final category in TagCategory.values) {
        final label = find.text(_categoryLabel(category));
        expect(label, findsOneWidget, reason: category.name);
        labelTop[category] = tester.getTopLeft(label).dy;
      }
      final order = TagCategory.values.toList()
        ..sort((a, b) => labelTop[a]!.compareTo(labelTop[b]!));
      for (final suggestion in _commonItems) {
        final tag = _tag(suggestion.value);
        expect(tag, findsOneWidget, reason: suggestion.value);
        expect(
          tester.widget<FrostTag>(tag).dataColor,
          suggestion.category.colorIndex,
        );
        final top = tester.getTopLeft(tag).dy;
        expect(
          top,
          greaterThan(labelTop[suggestion.category]!),
          reason: '${suggestion.value} sits below its category name',
        );
        final next = order.indexOf(suggestion.category) + 1;
        if (next < order.length) {
          expect(
            top,
            lessThan(labelTop[order[next]]!),
            reason: '${suggestion.value} sits above the next category name',
          );
        }
      }
    },
  );

  _appTest(
    'the All action of common tags opens AllCommonTagsPage',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      await tester.tap(_sectionAction(tester, t.discovery.commonTags));
      await tester.pumpAndSettle();
      expect(find.byType(AllCommonTagsPage), findsOneWidget);
      expect(
        tester
            .widget<AllCommonTagsPage>(find.byType(AllCommonTagsPage))
            .sourceId,
        'yande',
      );
      expect(_path, '/tags/common');
      expect(AppRouter.currentUri.queryParameters['source'], 'yande');
    },
  );

  _appTest(
    'pushCommonTags opens AllCommonTagsPage for the given source and '
    'completes when it is popped',
    {_wide},
    (tester, layout) async {
      var closed = false;
      unawaited(
        _context(
          tester,
        ).pushCommonTags<void>(sourceId: 'danbooru').then((_) => closed = true),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AllCommonTagsPage>(find.byType(AllCommonTagsPage))
            .sourceId,
        'danbooru',
      );
      expect(AppRouter.currentUri.queryParameters['source'], 'danbooru');
      expect(closed, isFalse);
      AppRouter.popRightNavigator();
      await tester.pumpAndSettle();
      expect(find.byType(AllCommonTagsPage), findsNothing);
      expect(closed, isTrue);
    },
  );

  // -------------------------------------------------------------------------
  // a tag opens its results
  // -------------------------------------------------------------------------

  _appTest(
    'tapping a common tag opens ResultsPage for that tag',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      await tester.tap(_tag('wlop'));
      await tester.pumpAndSettle();
      expect(_path, '/results');
      expect(find.byType(ResultsPage), findsOneWidget);
      expect(_resultTags(tester), ['wlop']);
      expect(
        tester.widget<ResultsPage>(find.byType(ResultsPage)).sourceId,
        'yande',
      );
    },
  );

  _appTest(
    'tapping a my tag opens ResultsPage for its raw value',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      await tester.tap(_tag('My Sky'));
      await tester.pumpAndSettle();
      expect(_path, '/results');
      expect(_resultTags(tester), ['sky_blue']);
    },
    arrange: () => repo.stored.addAll(_myTags),
  );

  // -------------------------------------------------------------------------
  // tag menu
  // -------------------------------------------------------------------------

  testWidgets('tagMenuEntries lists exactly the five tag actions in order', (
    tester,
  ) async {
    await _pumpPage(tester, const SizedBox());
    final entries = tagMenuEntries(
      tester.element(find.byType(FrostLayoutScope)),
      'wlop',
      sourceId: 'yande',
    );
    expect(entries, hasLength(5));
    expect(entries, everyElement(isA<FrostMenuAction>()));
    expect(_actionLabels(entries), _menuLabels);
    expect(tester.takeException(), isNull);
  });

  _appTest(
    'a tag on TagsPage opens a menu with exactly the five tag actions',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      final menu = tester.widget<FrostTag>(_tag('wlop')).contextMenu;
      expect(menu, hasLength(5));
      expect(_actionLabels(menu), _menuLabels);
      await _openMenu(tester, layout, _tag('wlop'));
      for (final label in _menuLabels) {
        expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
      }
    },
  );

  _appTest('Search this tag opens the results of the tag', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    await _openMenu(tester, layout, _tag('wlop'));
    await _choose(tester, t.postDetail.searchTag);
    expect(_path, '/results');
    expect(_resultTags(tester), ['wlop']);
  });

  _appTest('Exclude this tag opens the results of the negated tag', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    await _openMenu(tester, layout, _tag('wlop'));
    await _choose(tester, t.postDetail.excludeTag);
    expect(_path, '/results');
    expect(_resultTags(tester), ['-wlop']);
  });

  _appTest(
    'Add to search puts the tag into the focused title bar search',
    {_wide},
    (tester, layout) async {
      await _go(tester, '/tags');
      await _openMenu(tester, layout, _tag('wlop'));
      await _choose(tester, t.postDetail.addToSearch);
      expect(_tokens(_queryText(tester, layout)), ['wlop']);
      expect(_input(tester, layout).focusNode.hasFocus, isTrue);
      expect(_path, '/tags', reason: 'adding does not search yet');
    },
  );

  _appTest('Add to search expands the inline search with the tag', {_compact}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    await _openMenu(tester, layout, _tag('wlop'));
    await _choose(tester, t.postDetail.addToSearch);
    expect(_path, '/tags');
    expect(_cancel, findsOneWidget, reason: 'the inline search is expanded');
    expect(_tokens(_queryText(tester, layout)), ['wlop']);
  });

  _appTest('Add as a custom tag opens the editor with the raw tag', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags');
    await _openMenu(tester, layout, _tag('wlop'));
    await _choose(tester, t.discovery.addCustomTag);
    expect(find.byType(FrostForm), findsOneWidget);
    final canonical = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is FrostTextField && w.label == t.discovery.canonicalTag,
      ),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(canonical).controller.text, 'wlop');
  });

  _appTest('Copy puts the raw tag on the clipboard', {_wide}, (
    tester,
    layout,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _go(tester, '/tags');
    await _openMenu(tester, layout, _tag('wlop'));
    await _choose(tester, t.frost.copy);
    expect(copied, 'wlop');
  });

  testWidgets(
    'the detail panel tag menu has the same five entries as tagMenuEntries',
    (tester) async {
      await _pumpPage(
        tester,
        Center(
          child: SizedBox(
            width: 360,
            child: PostTagsSection(post: Post(_booruPost('101'))),
          ),
        ),
      );
      final shared = tagMenuEntries(
        tester.element(find.byType(PostTagsSection)),
        'sky',
        sourceId: 'yande',
      );
      for (final name in ['sky', 'actual_artist']) {
        final menu = tester.widget<FrostTag>(_tag(name)).contextMenu;
        expect(menu, hasLength(5), reason: name);
        expect(_actionLabels(menu), _actionLabels(shared), reason: name);
      }
      await tester.tap(_tag('sky'), buttons: kSecondaryButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      for (final label in _menuLabels) {
        expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
      }
      expect(tester.takeException(), isNull);
    },
  );

  // -------------------------------------------------------------------------
  // title bar search, empty input (wide)
  // -------------------------------------------------------------------------

  void arrangeLanding() {
    repo.history['yande'] = List.of(_recents);
    repo.stored.addAll(_myTags);
  }

  _appTest(
    'an empty focused title bar search lists recent searches (at most 8), '
    'my tags and common tags (at most 5)',
    {_wide},
    (tester, layout) async {
      await _focusSearch(tester, layout);
      final groups = _groups(tester, layout);
      expect(groups.map((group) => group.title), [
        t.discovery.recentSearches,
        t.discovery.myTags,
        t.discovery.commonTags,
      ]);
      expect(groups[0].items.map((item) => item.label), _recents.take(8));
      expect(groups[1].items.map((item) => item.label), ['My Sky', 'Tower']);
      expect(groups[1].items.map((item) => item.detail), ['sky_blue', 'tower']);
      expect(groups[2].items.map((item) => item.label), [
        '1girl',
        'highres',
        'sky',
        'hatsune_miku',
        'genshin_impact',
      ]);
      for (final group in groups) {
        expect(group.actionLabel, isNotNull, reason: group.title);
        expect(group.onAction, isNotNull, reason: group.title);
      }
      expect(
        find
            .descendant(
              of: layout.suggestionScope,
              matching: find.text(t.discovery.recentSearches),
            )
            .hitTestable(),
        findsOneWidget,
      );
    },
    arrange: arrangeLanding,
  );

  _appTest('the Clear action empties the recent searches', {_wide}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    await tester.tap(_groupAction(tester, layout, t.discovery.recentSearches));
    await tester.pumpAndSettle();
    expect(repo.history['yande'], isEmpty);
    expect(
      _groups(tester, layout).map((group) => group.title),
      isNot(contains(t.discovery.recentSearches)),
    );
    expect(_groups(tester, layout).map((group) => group.title), [
      t.discovery.myTags,
      t.discovery.commonTags,
    ]);
  }, arrange: arrangeLanding);

  _appTest('the Manage action opens MyTagsPage', {_wide}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    await tester.tap(_groupAction(tester, layout, t.discovery.myTags));
    await tester.pumpAndSettle();
    expect(find.byType(MyTagsPage), findsOneWidget);
    expect(_path, '/tags/mine');
  }, arrange: arrangeLanding);

  _appTest('the All action opens the Tags destination', {_wide}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    await tester.tap(_groupAction(tester, layout, t.discovery.commonTags));
    await tester.pumpAndSettle();
    expect(_path, '/tags');
    expect(find.byType(TagsPage), findsOneWidget);
  }, arrange: arrangeLanding);

  _appTest('a recent search can be removed on its own', {_wide}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    final first = _groups(tester, layout).first.items.first;
    expect(first.onRemove, isNotNull);
    await tester.tap(
      find
          .descendant(
            of: layout.suggestionScope,
            matching: find.byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.frost.remove,
            ),
          )
          .hitTestable()
          .first,
    );
    await tester.pumpAndSettle();
    expect(repo.history['yande'], _recents.skip(1));
    expect(_path, '/', reason: 'removing does not search');
  }, arrange: arrangeLanding);

  _appTest(
    'choosing a recent search fills the input without searching',
    {_wide},
    (tester, layout) async {
      await _focusSearch(tester, layout);
      await tester.tap(
        find
            .descendant(
              of: layout.suggestionScope,
              matching: find.text('sky -cloud'),
            )
            .hitTestable()
            .first,
      );
      await tester.pumpAndSettle();
      expect(_tokens(_queryText(tester, layout)), ['sky', '-cloud']);
      expect(_path, '/');
      expect(find.byType(ResultsPage), findsNothing);
    },
    arrange: arrangeLanding,
  );

  _appTest('choosing a my tag adds its raw value to the query', {_wide}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    await tester.tap(
      find
          .descendant(of: layout.suggestionScope, matching: find.text('My Sky'))
          .hitTestable()
          .first,
    );
    await tester.pumpAndSettle();
    expect(_tokens(_queryText(tester, layout)), ['sky_blue']);
    expect(_path, '/');
  }, arrange: arrangeLanding);

  _appTest('choosing a common tag adds it to the query', {_wide}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    await tester.tap(
      find
          .descendant(
            of: layout.suggestionScope,
            matching: find.text('hatsune_miku'),
          )
          .hitTestable()
          .first,
    );
    await tester.pumpAndSettle();
    expect(_tokens(_queryText(tester, layout)), ['hatsune_miku']);
    expect(_path, '/');
  }, arrange: arrangeLanding);

  // -------------------------------------------------------------------------
  // typed suggestions
  // -------------------------------------------------------------------------

  void arrangeSuggestions() {
    repo.suggestions['mi'] = [
      const TagSuggestion(
        value: 'hatsune_miku',
        displayName: '初音未来',
        count: '160204',
        category: TagCategory.character,
        origin: SuggestionOrigin.sourceApi,
        verified: true,
      ),
    ];
  }

  _appTest(
    'choosing a suggestion replaces the word at the caret and keeps its '
    'leading minus',
    {_wide, _compact},
    (tester, layout) async {
      // The caret sits right after "-mi".
      await _type(tester, layout, 'sky -mi rating:s ', caret: 7);
      expect(repo.remoteCalls, contains('mi'));
      expect(find.text('hatsune_miku').hitTestable(), findsOneWidget);
      await tester.tap(find.text('hatsune_miku').hitTestable().first);
      await tester.pumpAndSettle();
      expect(_tokens(_queryText(tester, layout)), [
        'sky',
        '-hatsune_miku',
        'rating:s',
      ]);
      expect(find.byType(ResultsPage), findsNothing, reason: 'not submitted');
    },
    arrange: arrangeSuggestions,
  );

  _appTest(
    'a suggestion carries its category dot, inline translation and count',
    {_wide, _compact},
    (tester, layout) async {
      await _type(tester, layout, 'mi');
      final item = _groups(tester, layout)
          .expand((group) => group.children)
          .whereType<FrostSearchSuggestionRow>()
          .singleWhere((item) => item.label == 'hatsune_miku');
      expect(item.dataColor, TagCategory.character.colorIndex);
      expect(item.detail, '初音未来');
      expect(item.inlineDetail, isTrue);
      expect(item.value, matches(RegExp(r'\d')));
    },
    arrange: arrangeSuggestions,
  );

  // -------------------------------------------------------------------------
  // submitting from the title bar
  // -------------------------------------------------------------------------

  _appTest('Enter pushes ResultsPage and records a recent search', {_wide}, (
    tester,
    layout,
  ) async {
    final before = AppRouter.rightNavigatorDepth;
    await _type(tester, layout, 'sky -cloud');
    await _submit(tester);
    expect(_path, '/results');
    expect(find.byType(ResultsPage), findsOneWidget);
    expect(_resultTags(tester), ['sky', '-cloud']);
    expect(AppRouter.rightNavigatorDepth, before + 1);
    expect(repo.history['yande']?.first, 'sky -cloud');
  });

  _appTest('Enter on a foreground ResultsPage replaces it', {_wide}, (
    tester,
    layout,
  ) async {
    final before = AppRouter.rightNavigatorDepth;
    await _openResults(tester, ['sky']);
    final depth = AppRouter.rightNavigatorDepth;
    expect(depth, before + 1);
    await _type(tester, layout, 'blue_eyes');
    await _submit(tester);
    expect(find.byType(ResultsPage), findsOneWidget);
    expect(_resultTags(tester), ['blue_eyes']);
    expect(
      AppRouter.rightNavigatorDepth,
      depth,
      reason: 'replaced, not pushed',
    );
    expect(repo.history['yande']?.first, 'blue_eyes');
    AppRouter.popRightNavigator();
    await tester.pumpAndSettle();
    expect(find.byType(ResultsPage), findsNothing);
    expect(_path, '/', reason: 'one Back leaves the replaced results');
  });

  // -------------------------------------------------------------------------
  // title bar search follows the foreground results page
  // -------------------------------------------------------------------------

  _appTest(
    'the title bar search shows the foreground query and is empty '
    'after going back',
    {_wide},
    (tester, layout) async {
      expect(_queryText(tester, layout).trim(), isEmpty);
      await _openResults(tester, ['sky', '-cloud']);
      expect(_tokens(_queryText(tester, layout)), ['sky', '-cloud']);
      AppRouter.popRightNavigator();
      await tester.pumpAndSettle();
      expect(find.byType(ResultsPage), findsNothing);
      expect(_queryText(tester, layout).trim(), isEmpty);
    },
  );

  // -------------------------------------------------------------------------
  // inline search in the page headers
  // -------------------------------------------------------------------------

  void expectHeaderSearch(bool present) {
    final header = find.byType(FrostPageHeader);
    expect(header, findsOneWidget);
    expect(
      find.descendant(of: header, matching: find.byType(FrostSearchInput)),
      present ? findsOneWidget : findsNothing,
    );
    expect(
      find.descendant(of: header, matching: find.byType(InlineSearch)),
      present ? findsOneWidget : findsNothing,
    );
  }

  for (final layout in [_compact, _wide]) {
    _appTest(
      'the BrowsePage, TagsPage and ResultsPage headers '
      '${layout.compact ? 'carry' : 'do not carry'} a search input',
      {layout},
      (tester, layout) async {
        expect(find.byType(BrowsePage), findsOneWidget);
        expectHeaderSearch(layout.compact);
        await _go(tester, '/tags');
        expect(find.byType(TagsPage), findsOneWidget);
        expectHeaderSearch(layout.compact);
        await _openResults(tester, ['sky']);
        expect(find.byType(ResultsPage), findsOneWidget);
        expectHeaderSearch(layout.compact);
      },
    );
  }

  _appTest('the results inline search shows the current query', {_compact}, (
    tester,
    layout,
  ) async {
    await _openResults(tester, ['sky', '-cloud']);
    expect(_tokens(_queryText(tester, layout)), ['sky', '-cloud']);
  });

  _appTest(
    'submitting from the results inline search replaces the page',
    {_compact},
    (tester, layout) async {
      await _openResults(tester, ['sky']);
      final depth = AppRouter.rightNavigatorDepth;
      await _type(tester, layout, 'blue_eyes');
      await _submit(tester);
      expect(find.byType(ResultsPage), findsOneWidget);
      expect(_resultTags(tester), ['blue_eyes']);
      expect(AppRouter.rightNavigatorDepth, depth);
      expect(_cancel, findsNothing, reason: 'submitting collapses the search');
    },
  );

  _appTest(
    'submitting from the browse inline search pushes the results',
    {_compact},
    (tester, layout) async {
      final before = AppRouter.rightNavigatorDepth;
      await _type(tester, layout, 'sky -cloud');
      await _submit(tester);
      expect(_path, '/results');
      expect(_resultTags(tester), ['sky', '-cloud']);
      expect(AppRouter.rightNavigatorDepth, before + 1);
    },
  );

  // -------------------------------------------------------------------------
  // inline search expansion (compact)
  // -------------------------------------------------------------------------

  _appTest('focusing the inline search shows the landing groups', {_compact}, (
    tester,
    layout,
  ) async {
    expect(find.text(t.discovery.recentSearches), findsNothing);
    expect(_cancel, findsNothing);
    await _focusSearch(tester, layout);
    expect(_cancel, findsOneWidget);
    expect(_groups(tester, layout).map((group) => group.title), [
      t.discovery.recentSearches,
      t.discovery.myTags,
      t.discovery.commonTags,
    ]);
    for (final title in [
      t.discovery.recentSearches,
      t.discovery.myTags,
      t.discovery.commonTags,
    ]) {
      expect(find.text(title).hitTestable(), findsOneWidget, reason: title);
    }
    final recents = _groups(tester, layout).first.items;
    expect(recents.map((item) => item.label), _recents.take(8));
  }, arrange: arrangeLanding);

  _appTest('the landing actions work on the inline search', {_compact}, (
    tester,
    layout,
  ) async {
    await _focusSearch(tester, layout);
    await tester.tap(_groupAction(tester, layout, t.discovery.recentSearches));
    await tester.pumpAndSettle();
    expect(repo.history['yande'], isEmpty);
    await tester.tap(_groupAction(tester, layout, t.discovery.commonTags));
    await tester.pumpAndSettle();
    expect(_path, '/tags');
    expect(find.byType(TagsPage), findsOneWidget);
  }, arrange: arrangeLanding);

  _appTest(
    'Cancel collapses the inline search and keeps the text',
    {_compact},
    (tester, layout) async {
      await _type(tester, layout, 'sky');
      expect(_cancel, findsOneWidget);
      await tester.tap(_cancel);
      await tester.pumpAndSettle();
      expect(_cancel, findsNothing);
      expect(_path, '/');
      expect(find.byType(BrowsePage), findsOneWidget);
      expect(_tokens(_queryText(tester, layout)), ['sky']);
      expect(find.text(t.discovery.recentSearches), findsNothing);
      // Expanding again restores the kept text.
      await _focusSearch(tester, layout);
      expect(_cancel, findsOneWidget);
      expect(_tokens(_queryText(tester, layout)), ['sky']);
    },
    arrange: arrangeLanding,
  );

  _appTest(
    'Escape collapses the inline search without leaving the page',
    {_compact},
    (tester, layout) async {
      await _type(tester, layout, 'sky');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_cancel, findsNothing);
      expect(_path, '/');
      expect(_tokens(_queryText(tester, layout)), ['sky']);
    },
  );

  _appTest(
    'system Back collapses the inline search and stays on the '
    'results page',
    {_compact},
    (tester, layout) async {
      await _openResults(tester, ['sky']);
      await _focusSearch(tester, layout);
      expect(_cancel, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_cancel, findsNothing);
      expect(find.byType(ResultsPage), findsOneWidget);
      expect(_path, '/results');
    },
  );

  // -------------------------------------------------------------------------
  // my tags page
  // -------------------------------------------------------------------------

  void arrangeSourceTags() => repo.stored.addAll([
    _alias('y', 'blue_sky', 'Yande tag', source: 'yande'),
    _alias('d', 'long_hair', 'Dan tag', source: 'danbooru'),
    _alias('s', 'any_tag', 'Any tag'),
  ]);

  _appTest(
    'MyTagsPage lists every alias with its raw value and source',
    {_wide},
    (tester, layout) async {
      await _go(tester, '/tags/mine');
      expect(find.byType(MyTagsPage), findsOneWidget);
      for (final (title, value, source) in [
        ('Yande tag', 'blue_sky', 'yande'),
        ('Dan tag', 'long_hair', 'danbooru'),
        ('Any tag', 'any_tag', t.discovery.allTagSources),
      ]) {
        final row = _row(title);
        expect(row, findsOneWidget, reason: title);
        expect(
          find.descendant(of: row, matching: find.textContaining(value)),
          findsWidgets,
          reason: '$title shows its raw value',
        );
        expect(
          find.descendant(of: row, matching: find.textContaining(source)),
          findsWidgets,
          reason: '$title shows its source',
        );
      }
    },
    arrange: arrangeSourceTags,
  );

  _appTest('the route passes its source query to MyTagsPage', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags/mine?source=danbooru');
    expect(
      tester.widget<MyTagsPage>(find.byType(MyTagsPage)).sourceId,
      'danbooru',
    );
  }, arrange: arrangeSourceTags);

  _appTest('the source filter menu narrows the list', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags/mine');
    expect(_row('Dan tag'), findsOneWidget);
    await _chooseFromHeaderMenu(tester, 'yande');
    expect(_row('Yande tag'), findsOneWidget);
    expect(_row('Dan tag'), findsNothing);
    await _chooseFromHeaderMenu(tester, 'danbooru');
    expect(_row('Dan tag'), findsOneWidget);
    expect(_row('Yande tag'), findsNothing);
  }, arrange: arrangeSourceTags);

  _appTest(
    'Delete in the row menu removes the alias from the repository',
    {_wide, _compact},
    (tester, layout) async {
      await _go(tester, '/tags/mine');
      await _openMenu(tester, layout, _row('Dan tag'));
      expect(find.text(t.discovery.editTag).hitTestable(), findsOneWidget);
      await _choose(tester, t.discovery.deleteTag);
      expect(
        find.text(t.discovery.deleteTagConfirm(name: 'Dan tag')),
        findsOneWidget,
      );
      expect(repo.stored, hasLength(3));
      await _choose(tester, t.discovery.deleteTag);
      expect(repo.stored.map((alias) => alias.id), unorderedEquals(['y', 's']));
      expect(_row('Dan tag'), findsNothing);
      expect(_row('Yande tag'), findsOneWidget);
      expect(_row('Any tag'), findsOneWidget);
    },
    arrange: arrangeSourceTags,
  );

  // -------------------------------------------------------------------------
  // all common tags page
  // -------------------------------------------------------------------------

  final countOf = {
    'wlop': RegExp(r'1[.,\s]?2'),
    'hatsune_miku': RegExp(r'1[.,\s]?6'),
  };

  _appTest(
    'AllCommonTagsPage lists rows with a category dot and the count',
    {_wide},
    (tester, layout) async {
      await _go(tester, '/tags/common?source=yande');
      expect(find.byType(AllCommonTagsPage), findsOneWidget);
      expect(
        tester
            .widget<AllCommonTagsPage>(find.byType(AllCommonTagsPage))
            .sourceId,
        'yande',
      );
      expect(repo.commonCalls, contains(1));
      for (final suggestion in _commonItems) {
        final row = _row(suggestion.value);
        expect(row, findsOneWidget, reason: suggestion.value);
        expect(
          find.descendant(of: row, matching: find.byType(FrostDataDot)),
          findsOneWidget,
          reason: '${suggestion.value} has its category dot',
        );
      }
      for (final MapEntry(key: tag, value: count) in countOf.entries) {
        expect(
          find.descendant(of: _row(tag), matching: find.textContaining(count)),
          findsWidgets,
          reason: '$tag shows its count',
        );
      }
    },
  );

  _appTest('the category menu filters the rows by category', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags/common?source=yande');
    expect(_row('hatsune_miku'), findsOneWidget);
    await _chooseFromHeaderMenu(tester, _categoryLabel(TagCategory.artist));
    expect(_row('wlop'), findsOneWidget);
    expect(_row('mika_pikazo'), findsOneWidget);
    expect(_row('hatsune_miku'), findsNothing);
    expect(_row('sky'), findsNothing);
    await _chooseFromHeaderMenu(tester, _categoryLabel(TagCategory.character));
    expect(_row('hatsune_miku'), findsOneWidget);
    expect(_row('wlop'), findsNothing);
  });

  _appTest('tapping a row opens the results of the tag', {_wide, _compact}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags/common?source=yande');
    await tester.tap(_row('wlop'));
    await tester.pumpAndSettle();
    expect(_path, '/results');
    expect(_resultTags(tester), ['wlop']);
  });

  _appTest('a row menu has the five tag actions', {_wide, _compact}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/tags/common?source=yande');
    await _openMenu(tester, layout, _row('wlop'));
    for (final label in _menuLabels) {
      expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
    }
  });

  _appTest(
    'scrolling to the end requests the next page of common tags',
    {_wide},
    (tester, layout) async {
      await _go(tester, '/tags/common?source=yande');
      expect(repo.commonCalls, [1]);
      expect(find.text('last_page_tag'), findsNothing);
      await tester.dragUntilVisible(
        find.text('last_page_tag'),
        find
            .descendant(
              of: find.byType(AllCommonTagsPage),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, -500),
        maxIteration: 60,
      );
      expect(repo.commonCalls, contains(2));
      expect(find.text('last_page_tag'), findsOneWidget);
    },
    arrange: () {
      // A full page of 50 means there may be more.
      repo.commonPages[1] = [
        for (var i = 0; i < 50; i++)
          _tagSuggestion('page_one_tag_$i', TagCategory.general, '${1000 - i}'),
      ];
      repo.commonPages[2] = [
        _tagSuggestion('last_page_tag', TagCategory.general, '3'),
      ];
    },
  );

  // -------------------------------------------------------------------------
  // /results redirect rules
  // -------------------------------------------------------------------------

  _appTest('/results without a query ends on TagsPage', {_wide, _compact}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/results');
    expect(_path, '/tags');
    expect(find.byType(TagsPage), findsOneWidget);
    expect(
      tester.widget<TagsPage>(find.byType(TagsPage)).invalidQuery,
      isFalse,
    );
    expect(find.byType(ResultsPage), findsNothing);
    expect(find.byType(FrostInlineBanner), findsNothing);
  });

  _appTest('/results with an empty tag list ends on TagsPage', {_wide}, (
    tester,
    layout,
  ) async {
    await _go(tester, '/results?source=yande&tags=%5B%5D');
    expect(_path, '/tags');
    expect(find.byType(TagsPage), findsOneWidget);
    expect(find.byType(ResultsPage), findsNothing);
  });

  _appTest(
    '/results for an unknown source shows TagsPage with the invalid '
    'query banner',
    {_wide, _compact},
    (tester, layout) async {
      await _go(
        tester,
        Uri(
          path: '/results',
          queryParameters: {
            'source': 'no_such_source',
            'tags': jsonEncode(['sky']),
          },
        ).toString(),
      );
      expect(_path, '/results');
      expect(find.byType(ResultsPage), findsNothing);
      expect(find.byType(TagsPage), findsOneWidget);
      expect(
        tester.widget<TagsPage>(find.byType(TagsPage)).invalidQuery,
        isTrue,
      );
      expect(
        find.descendant(
          of: find.byType(TagsPage),
          matching: find.byType(FrostInlineBanner),
        ),
        findsOneWidget,
      );
    },
  );

  // -------------------------------------------------------------------------
  // openSearch
  // -------------------------------------------------------------------------

  _appTest(
    'openSearch puts the text into the focused title bar search',
    {_wide},
    (tester, layout) async {
      _context(tester).openSearch('foo', sourceId: 'yande');
      await tester.pumpAndSettle();
      expect(_tokens(_queryText(tester, layout)), ['foo']);
      expect(_input(tester, layout).focusNode.hasFocus, isTrue);
    },
  );

  _appTest(
    'openSearch on the Tags page expands its inline search with the text',
    {_compact},
    (tester, layout) async {
      await _go(tester, '/tags');
      _context(tester).openSearch('foo', sourceId: 'yande');
      await tester.pumpAndSettle();
      expect(_path, '/tags');
      expect(find.byType(TagsPage), findsOneWidget);
      expect(_cancel, findsOneWidget, reason: 'the inline search is expanded');
      expect(_tokens(_queryText(tester, layout)), ['foo']);
      expect(_input(tester, layout).focusNode.hasFocus, isTrue);
    },
  );

  _appTest(
    'openSearch away from the Tags page opens the results above it',
    {_compact},
    (tester, layout) async {
      expect(_path, '/');
      _context(tester).openSearch('foo', sourceId: 'yande');
      await tester.pumpAndSettle();
      expect(_path, '/results');
      expect(ResultsQuery.parse(AppRouter.currentUri).tags, ['foo']);
      AppRouter.router.pop();
      await tester.pumpAndSettle();
      expect(_path, '/');
    },
  );

  // -------------------------------------------------------------------------
  // text scale and long text
  // -------------------------------------------------------------------------

  final longTag = List.filled(6, 'extremely_long_tag_name').join('_');
  final pages = <(String, Widget Function(), Finder Function())>[
    ('tags page', () => const TagsPage(), () => find.byType(FrostTag)),
    (
      'my tags page',
      () => const MyTagsPage(),
      () => _row('My long alias $longTag 0'),
    ),
    (
      'common tags page',
      () => const AllCommonTagsPage(sourceId: 'yande'),
      () => _row('${longTag}_0'),
    ),
  ];
  for (final (name, build, content) in pages) {
    for (final locale in [AppLocale.en, AppLocale.ja]) {
      for (final (size, platform, label) in [
        (const Size(1147, 717), TargetPlatform.windows, 'wide'),
        (const Size(360, 780), TargetPlatform.android, 'narrow touch'),
      ]) {
        testWidgets('$name: ${locale.languageTag} at 2.0 text, $label', (
          tester,
        ) async {
          LocaleSettings.setLocaleSync(locale);
          repo.stored.addAll([
            for (var i = 0; i < 6; i++)
              _alias('long$i', '${longTag}_$i', 'My long alias $longTag $i'),
          ]);
          repo.commonItems = [
            for (var i = 0; i < 30; i++)
              TagSuggestion(
                value: '${longTag}_$i',
                displayName: 'A long translated name $longTag $i',
                count: '${123456789 - i}',
                category: TagCategory.values[i % TagCategory.values.length],
                origin: SuggestionOrigin.sourceApi,
                verified: true,
              ),
          ];
          await _pumpPage(
            tester,
            build(),
            size: size,
            platform: platform,
            scale: 2,
          );
          expect(content(), findsWidgets);
          expect(tester.takeException(), isNull);
          // Settle input-driven chrome too, then leave cleanly.
          await tester.pump(const Duration(seconds: 3));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}

extension on FrostSearchSection {
  List<FrostSearchSuggestionRow> get items =>
      children.whereType<FrostSearchSuggestionRow>().toList();
}
