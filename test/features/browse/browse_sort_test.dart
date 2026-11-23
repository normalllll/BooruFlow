// Sort choice on the home feed and on tag results.
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/discovery_logic.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/browse_support.dart';
import '../../support/frost_app_layers.dart';

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class _Downloads extends DownloadItems {
  @override
  List<BooruDownloadItem> build() => [];
}

class _Tags extends TagSuggestionRepository {
  @override
  Future<void> initialize() async {}
  @override
  String? displayName(String source, String locale, String value) => null;
}

class _RememberedSorts extends SearchSortSelection {
  _RememberedSorts(this.initial);
  final Map<String, SortOrder> initial;
  @override
  Map<String, SortOrder> build() => initial;
}

List<SortOption> _options(List<SortOrder> primary, List<SortOrder> more) => [
  for (final order in primary) SortOption(order: order, primary: true),
  for (final order in more) SortOption(order: order, primary: false),
];

BooruSource _source(
  String id, {
  bool popular = false,
  List<SortOrder> primary = const [SortOrder.latest],
  List<SortOrder> more = const [],
}) {
  final options = _options(primary, more);
  return BooruSource(
    sourceId: id,
    displayName: id,
    protocol: BooruProtocol.danbooru,
    enabledByDefault: true,
    isAiSource: false,
    capabilities: SourceCapabilities(
      sorts: SortCapabilities(feed: options, search: options),
      discovery: DiscoveryCapabilities(
        popular: popular
            ? CapabilityAvailability.available
            : CapabilityAvailability.unsupported,
        commonTags: CapabilityAvailability.unsupported,
        popularRanges: popular ? const [PopularRange.day] : const [],
        historicalRanges: const [],
        timeBasis: PopularTimeBasis.indexTimeWindow,
        autocompleteMinChars: 1,
      ),
      ratings: const [ContentRating.general],
      authKind: AuthKind.none,
      supportsSearch: true,
      supportsPostDetail: true,
      supportsAutocomplete: false,
      supportsRelatedPosts: false,
      supportsOriginal: true,
      supportsAuthenticatedMedia: false,
      supportsBackgroundDownload: true,
    ),
  );
}

const _wide = Size(1147, 717);

final moreButton = find
    .byWidgetPredicate(
      (w) => w is FrostTooltip && w.message == t.frost.more,
      description: 'the more button',
    )
    .hitTestable()
    .first;

void main() {
  late List<CollectionKey> loaded;

  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    loaded = [];
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    required List<BooruSource> sources,
    List<Object> overrides = const [],
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = BooruService()..useSourcesForTesting(sources);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => page),
        GoRoute(
          path: AppRoute.results.path,
          name: AppRoute.results.name,
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            tagSuggestionRepositoryProvider.overrideWithValue(_Tags()),
            downloadItemsProvider.overrideWith(_Downloads.new),
            collectionLoaderProvider.overrideWithValue((key, _) async {
              loaded.add(key);
              return PostPage(
                items: [for (var i = 0; i < 12; i++) browsePost(i)],
                exhausted: true,
              );
            }),
            ...overrides.cast(),
          ],
          child: FrostScope(
            config: appFrostConfig,
            child: MaterialApp.router(
              routerConfig: router,
              theme: FrostTheme.build(
                config: appFrostConfig,
                brightness: Brightness.light,
                platform: TargetPlatform.android,
                locale: const Locale('en'),
              ),
              builder: (context, child) =>
                  FrostLayoutScope(child: frostAppLayers(child!)),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Finder button(String label) => find.byWidgetPredicate(
    (w) => w is FrostButton && w.label == label,
    description: 'a button labelled $label',
  );
  Finder chip(String label) => find.byWidgetPredicate(
    (w) => w is FrostFilterChip && w.label == label,
    description: 'a filter chip labelled $label',
  );
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).hitTestable().last);
    await settle(tester);
  }

  SortOrder sortOf(CollectionKey key) => switch (key.request) {
    FeedCollectionRequest(:final sort) => sort,
    TagSearchCollectionRequest(:final sort) => sort,
  };

  final danbooruLike = _source(
    'danbooru',
    popular: true,
    primary: [SortOrder.latest, SortOrder.score, SortOrder.random],
    more: [SortOrder.oldest, SortOrder.resolution],
  );
  final gelbooruLike = _source(
    'gelbooru',
    primary: [SortOrder.latest, SortOrder.score],
    more: [SortOrder.oldest],
  );

  group('home feed', () {
    testWidgets('a source with a popular feed has two tabs and the sort '
        'button at the end of the tab row', (tester) async {
      await pump(tester, const BrowsePage(), sources: [danbooruLike]);
      final tabs = tester.widget<FrostTabBar>(find.byType(FrostTabBar)).tabs;
      expect(tabs.map((tab) => tab.label), [
        t.discovery.all,
        t.discovery.popular,
      ]);
      expect(button(t.discovery.sort.latest), findsOneWidget);
      // Sorting is the tab row's: the toolbar holds no second control for it.
      expect(button(t.discovery.sort.title), findsNothing);
      expect(chip(t.discovery.sort.title), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'choosing a sort reloads the feed under another collection key',
      (tester) async {
        await pump(tester, const BrowsePage(), sources: [danbooruLike]);
        final first = loaded.last;
        expect(sortOf(first), SortOrder.latest);

        await tester.tap(button(t.discovery.sort.latest));
        await settle(tester);
        // Primary options are listed; the rest sit under the submenu.
        expect(find.text(t.discovery.sort.score), findsOneWidget);
        expect(find.text(t.discovery.sort.random), findsOneWidget);
        expect(find.text(t.discovery.sort.oldest), findsNothing);
        expect(find.text(t.discovery.sort.more), findsOneWidget);
        await choose(tester, t.discovery.sort.score);

        expect(sortOf(loaded.last), SortOrder.score);
        expect(loaded.last, isNot(first));
        expect(button(t.discovery.sort.score), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a sort chosen from the submenu is checked and its submenu '
        'carries the mark', (tester) async {
      await pump(tester, const BrowsePage(), sources: [danbooruLike]);
      await tester.tap(button(t.discovery.sort.latest));
      await settle(tester);
      await choose(tester, t.discovery.sort.more);
      await choose(tester, t.discovery.sort.oldest);
      expect(sortOf(loaded.last), SortOrder.oldest);

      await tester.tap(button(t.discovery.sort.oldest));
      await settle(tester);
      final entries = find.byType(FrostMenuAnchor);
      expect(entries, findsWidgets);
      final menu = tester
          .widgetList<FrostMenuAnchor>(entries)
          .firstWhere(
            (anchor) => anchor.entries.any((e) => e is FrostMenuSubmenu),
          );
      final submenu = menu.entries.whereType<FrostMenuSubmenu>().single;
      expect(submenu.label, t.discovery.sort.more);
      expect(submenu.leading, isNotNull);
      final checked = submenu.entries.whereType<FrostMenuAction>().where(
        (action) => action.checked == true,
      );
      expect(checked.map((action) => action.label), [t.discovery.sort.oldest]);
    });

    testWidgets('switching to the popular tab and back keeps the chosen sort', (
      tester,
    ) async {
      await pump(tester, const BrowsePage(), sources: [danbooruLike]);
      await tester.tap(button(t.discovery.sort.latest));
      await settle(tester);
      await choose(tester, t.discovery.sort.score);

      await tester.tap(find.text(t.discovery.popular).hitTestable().last);
      await settle(tester);
      // The popular tab has its range button, not a sort.
      expect(button(t.discovery.sort.score), findsNothing);
      await tester.tap(find.text(t.discovery.all).hitTestable().last);
      await settle(tester);
      expect(button(t.discovery.sort.score), findsOneWidget);
      // The section keeps its list: nothing was loaded again for it.
      expect(
        loaded.where((key) => sortOf(key) == SortOrder.score),
        hasLength(1),
      );
    });

    testWidgets('a source with only the all-posts feed has no tab bar; its '
        'sort is in the header toolbar', (tester) async {
      await pump(
        tester,
        const BrowsePage(),
        sources: [gelbooruLike],
        size: _wide,
      );
      expect(find.byType(FrostTabBar), findsNothing);
      expect(button(t.discovery.sort.title), findsOneWidget);
      expect(chip(t.discovery.sort.title), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a non-default sort adds a condition that clears with the '
        'rating condition', (tester) async {
      await pump(
        tester,
        const BrowsePage(),
        sources: [gelbooruLike],
        size: _wide,
      );
      await tester.tap(button(t.discovery.sort.title));
      await settle(tester);
      await choose(tester, t.discovery.sort.score);
      expect(sortOf(loaded.last), SortOrder.score);
      expect(chip(t.discovery.sort.title), findsOneWidget);
      expect(
        tester.widget<FrostFilterChip>(chip(t.discovery.sort.title)).value,
        t.discovery.sort.score,
      );

      SettingsService.ratings = [ContentRating.general];
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(chip(t.discovery.ratingLabel), findsOneWidget);

      await tester.tap(button(t.frost.clearAll));
      await settle(tester);
      expect(sortOf(loaded.last), SortOrder.latest);
      expect(chip(t.discovery.sort.title), findsNothing);
      expect(chip(t.discovery.ratingLabel), findsNothing);
    });

    testWidgets('at phone width the sort is in the more menu, not beside the '
        'search field', (tester) async {
      await pump(tester, const BrowsePage(), sources: [gelbooruLike]);
      expect(button(t.discovery.sort.title), findsNothing);
      await tester.tap(moreButton);
      await settle(tester);
      expect(find.text(t.discovery.sort.title), findsOneWidget);
      await choose(tester, t.discovery.sort.title);
      // The same entries as the toolbar menu: primary options and "More".
      expect(find.text(t.discovery.sort.score), findsOneWidget);
      expect(find.text(t.discovery.sort.more), findsOneWidget);
      await choose(tester, t.discovery.sort.score);
      expect(sortOf(loaded.last), SortOrder.score);
      // The condition stays at every width.
      expect(chip(t.discovery.sort.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('at desktop width the sort is a toolbar button, not in the '
        'more menu', (tester) async {
      await pump(
        tester,
        const BrowsePage(),
        sources: [gelbooruLike],
        size: _wide,
      );
      expect(button(t.discovery.sort.title), findsOneWidget);
      await tester.tap(moreButton);
      await settle(tester);
      expect(find.text(t.discovery.sort.title), findsNothing);
    });

    testWidgets('a source with a single sort shows no sort control', (
      tester,
    ) async {
      await pump(tester, const BrowsePage(), sources: [_source('moe')]);
      expect(button(t.discovery.sort.title), findsNothing);
      expect(button(t.discovery.sort.latest), findsNothing);
      expect(chip(t.discovery.sort.title), findsNothing);
    });
  });

  group('tag results', () {
    testWidgets('opens on the sort last chosen for the source', (tester) async {
      await pump(
        tester,
        const ResultsPage(tags: ['sky'], sourceId: 'danbooru'),
        sources: [danbooruLike],
        overrides: [
          searchSortSelectionProvider.overrideWith(
            () => _RememberedSorts({'danbooru': SortOrder.random}),
          ),
        ],
      );
      expect(sortOf(loaded.last), SortOrder.random);
      expect(chip(t.discovery.sort.title), findsOneWidget);
    });

    testWidgets('opens on the source default when nothing was chosen', (
      tester,
    ) async {
      await pump(
        tester,
        const ResultsPage(tags: ['sky'], sourceId: 'danbooru'),
        sources: [danbooruLike],
        size: _wide,
      );
      expect(sortOf(loaded.last), SortOrder.latest);
      expect(chip(t.discovery.sort.title), findsNothing);
      expect(button(t.discovery.sort.title), findsOneWidget);
    });

    testWidgets('choosing a sort reloads, is remembered and can be cleared '
        'from its condition', (tester) async {
      await pump(
        tester,
        const ResultsPage(tags: ['sky'], sourceId: 'danbooru'),
        sources: [danbooruLike],
        size: _wide,
      );
      await tester.tap(button(t.discovery.sort.title));
      await settle(tester);
      await choose(tester, t.discovery.sort.score);
      expect(sortOf(loaded.last), SortOrder.score);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(ResultsPage)))
            .read(searchSortSelectionProvider),
        {'danbooru': SortOrder.score},
      );

      tester.widget<FrostFilterChip>(chip(t.discovery.sort.title)).onClear!();
      await settle(tester);
      expect(sortOf(loaded.last), SortOrder.latest);
      expect(chip(t.discovery.sort.title), findsNothing);
    });

    /// Opens the results page on danbooru with the sorts [remembered] and
    /// switches it to gelbooru, answering what gelbooru then remembers.
    Future<SortOrder?> switchedSort(
      WidgetTester tester,
      Map<String, SortOrder> remembered,
    ) async {
      await pump(
        tester,
        const ResultsPage(tags: ['sky'], sourceId: 'danbooru'),
        sources: [danbooruLike, gelbooruLike],
        overrides: [
          searchSortSelectionProvider.overrideWith(
            () => _RememberedSorts(remembered),
          ),
        ],
      );
      // Switching replaces the page, so keep hold of the state it shares.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ResultsPage)),
      );
      await tester.tap(moreButton);
      await settle(tester);
      await choose(tester, 'danbooru');
      await choose(tester, 'gelbooru');
      return container.read(searchSortSelectionProvider)['gelbooru'];
    }

    testWidgets('a source that has the current sort takes it over', (
      tester,
    ) async {
      expect(
        await switchedSort(tester, {'danbooru': SortOrder.score}),
        SortOrder.score,
      );
    });

    testWidgets('a source that lacks the current sort keeps its own remembered '
        'sort', (tester) async {
      expect(
        await switchedSort(tester, {
          'danbooru': SortOrder.random,
          'gelbooru': SortOrder.oldest,
        }),
        SortOrder.oldest,
      );
    });

    testWidgets('a source that lacks the current sort and remembers none '
        'is left without one, so it opens on its default', (tester) async {
      expect(
        await switchedSort(tester, {'danbooru': SortOrder.random}),
        isNull,
      );
    });
  });
}
