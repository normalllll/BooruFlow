import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/discovery_logic.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/browse/widgets/post_waterfall.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/browse_support.dart';
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => values;
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

/// [child] with [loader] standing in for the network.
Widget loaderApp(
  Widget child,
  CollectionLoader loader, {
  double scale = 1,
  TargetPlatform platform = TargetPlatform.windows,
}) => browseTestApp(
  ProviderScope(
    overrides: [collectionLoaderProvider.overrideWithValue(loader)],
    child: child,
  ),
  scale: scale,
  platform: platform,
);

void main() {
  const sources = [
    'yande',
    'konachan_net',
    'danbooru',
    'aibooru',
    'gelbooru',
    'wallhaven',
    'anime_pictures',
  ];
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    BooruService.instance.useSourcesForTesting(
      sources.map(testSource).toList(),
    );
  });
  Future<PostPage> empty(CollectionKey _, String? cursor) async =>
      const PostPage(items: [], exhausted: true);
  for (final width in [390.0, 1440.0]) {
    testWidgets('single supported feed omits every mode trigger at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(loaderApp(const BrowsePage(), empty));
      await tester.pumpAndSettle();
      expect(find.byType(FrostPicker<FeedKind>), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is FrostToolbarMenuButton &&
              widget.label == t.discovery.latest,
        ),
        findsNothing,
      );
      final header = tester.widget<FrostPageHeader>(
        find.byType(FrostPageHeader),
      );
      // Without a title row to hold the search, the page carries it.
      expect(header.middle, isA<InlineSearch>());
      expect(header.collapsedMiddle, isNull);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [360.0, 1440.0]) {
    testWidgets(
      'result query is the single page title; filters never resize its header at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          loaderApp(
            const ResultsPage(tags: ['hatsune_miku'], sourceId: 'yande'),
            empty,
          ),
        );
        await tester.pumpAndSettle();
        final header = tester.getRect(find.byType(FrostPageHeader));
        expect(header.height, width < 600 ? 48 : 52);
        expect(
          find.descendant(
            of: find.byType(FrostPageHeader),
            matching: find.textContaining('hatsune_miku'),
          ),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(FrostTitleMenu), findsNothing);
        final filter = find.byWidgetPredicate(
          (widget) =>
              widget is FrostButton && widget.label == t.discovery.filters,
        );
        SettingsService.ratings = [ContentRating.general];
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(FrostPageHeader)), header);
        expect(tester.widget<FrostButton>(filter).selected, true);
        expect(find.byType(FrostFilterChip), findsOneWidget);
        SettingsService.ratings = [];
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(FrostPageHeader)), header);
        expect(tester.widget<FrostButton>(filter).selected, false);
        expect(find.byType(FrostFilterChip), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'preview ratings update immediately without confirmation at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(loaderApp(const BrowsePage(), empty));
        await tester.pumpAndSettle();
        final header = tester.getRect(find.byType(FrostPageHeader));
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is FrostButton && w.label == t.discovery.filters,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.discovery.ratingsTitle), findsOneWidget);
        expect(find.text(t.generic.confirm), findsNothing);
        expect(find.byType(FrostCheckboxRow), findsNWidgets(4));
        expect(find.byType(FrostDialog), findsNothing);
        await tester.tap(
          find.byWidgetPredicate(
            (w) =>
                w is FrostCheckboxRow && w.title == t.postDetail.ratingGeneral,
          ),
        );
        await tester.pumpAndSettle();
        expect(SettingsService.ratings, [ContentRating.general]);
        expect(tester.getRect(find.byType(FrostPageHeader)), header);
        final selected = tester.widget<FrostCheckboxRow>(
          find.byWidgetPredicate(
            (w) =>
                w is FrostCheckboxRow && w.title == t.postDetail.ratingGeneral,
          ),
        );
        expect(selected.value, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('empty filtered collection offers one reset action', (
    tester,
  ) async {
    SettingsService.ratings = [ContentRating.general];
    await tester.pumpWidget(loaderApp(const BrowsePage(), empty));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FrostButton && widget.label == t.discovery.resetFilters,
      ),
      findsOneWidget,
    );
    expect(find.byType(FrostFilterChip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  group('with bundled fonts', () {
    // Real bundled metrics matter here; Ahem makes Latin labels artificially
    // wide and cannot establish production text visibility at a phone width.
    // Loading them outside the test keeps the system-fonts relayout frame
    // they announce from outliving the test's widget tree.
    setUpAll(() async {
      for (final family in ['JP', 'SC']) {
        await (FontLoader('Noto Sans $family')..addFont(
              rootBundle.load('assets/fonts/NotoSans$family-Subset.ttf'),
            ))
            .load();
      }
    });
    testWidgets('phone source label keeps the content keyline', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final base = testSource('danbooru');
      BooruService.instance.useSourcesForTesting([
        BooruSource(
          sourceId: base.sourceId,
          displayName: 'Danbooru',
          protocol: base.protocol,
          enabledByDefault: true,
          isAiSource: false,
          capabilities: base.capabilities,
        ),
      ]);
      await tester.pumpWidget(
        loaderApp(const BrowsePage(), empty, platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();
      final label = find.descendant(
        of: find.byType(FrostTitleMenu),
        matching: find.text('Danbooru'),
      );
      expect(tester.getTopLeft(label).dx, 16);
      expect(tester.takeException(), isNull);
    });
  });
  testWidgets(
    'fresh settings load all sources with latest feed and no explicit ratings',
    (tester) async {
      final calls = <CollectionKey>[];
      await tester.pumpWidget(
        loaderApp(const BrowsePage(), (key, _) async {
          calls.add(key);
          return const PostPage(items: [], exhausted: true);
        }),
      );
      await tester.pumpAndSettle();
      for (final id in sources.skip(1)) {
        BooruService.instance.selectSource(id);
        await tester.pumpAndSettle();
      }
      expect(calls.map((key) => key.sourceId), sources);
      expect(
        calls.every(
          (key) =>
              key.ratings.isEmpty &&
              key.request is FeedCollectionRequest &&
              (key.request as FeedCollectionRequest).kind == FeedKind.latest,
        ),
        true,
      );
      expect(find.byType(FrostTitleMenu), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'clearing ratings reloads defaults without remounting the collection view',
    (tester) async {
      SettingsService.ratings = [ContentRating.general];
      final calls = <List<ContentRating>>[];
      await tester.pumpWidget(
        loaderApp(const BrowsePage(), (key, _) async {
          calls.add(key.ratings);
          return const PostPage(items: [], exhausted: true);
        }),
      );
      await tester.pumpAndSettle();
      final original = tester.state(find.byType(PostWaterfall));
      SettingsService.ratings = [];
      await tester.pumpAndSettle();
      expect(calls, [
        [ContentRating.general],
        <ContentRating>[],
      ]);
      expect(tester.state(find.byType(PostWaterfall)), same(original));
    },
  );
  testWidgets(
    'global ratings remain visible and editable when unsupported by this source',
    (tester) async {
      SettingsService.ratings = [ContentRating.explicit];
      await tester.pumpWidget(
        loaderApp(const ResultsPage(tags: ['sky'], sourceId: 'yande'), empty),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is FrostButton && widget.label == t.discovery.filters,
        ),
      );
      await tester.pumpAndSettle();
      final rows = find.byType(FrostCheckboxRow);
      expect(rows, findsNWidgets(4));
      final explicit = find.byWidgetPredicate(
        (widget) =>
            widget is FrostCheckboxRow &&
            widget.title == t.postDetail.ratingExplicit,
      );
      expect(tester.widget<FrostCheckboxRow>(explicit).value, true);
      await tester.ensureVisible(explicit);
      await tester.tap(explicit);
      await tester.pumpAndSettle();
      expect(SettingsService.ratings, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in AppLocale.values) {
    testWidgets('phone section/range menu aligns its groups in $locale', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(locale);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final definition = testSource('yande');
      BooruService.instance.useSourcesForTesting([
        BooruSource(
          sourceId: definition.sourceId,
          displayName: definition.displayName,
          protocol: definition.protocol,
          enabledByDefault: true,
          isAiSource: false,
          capabilities: SourceCapabilities(
            ratings: definition.capabilities.ratings,
            authKind: definition.capabilities.authKind,
            supportsSearch: true,
            supportsPostDetail: true,
            supportsAutocomplete: true,
            supportsRelatedPosts: false,
            supportsOriginal: true,
            supportsAuthenticatedMedia: false,
            supportsBackgroundDownload: true,
            discovery: const DiscoveryCapabilities(
              popular: CapabilityAvailability.available,
              commonTags: CapabilityAvailability.available,
              popularRanges: [
                PopularRange.day,
                PopularRange.week,
                PopularRange.month,
              ],
              historicalRanges: [
                PopularRange.day,
                PopularRange.week,
                PopularRange.month,
              ],
              timeBasis: PopularTimeBasis.calendarUploadPeriod,
              additionalFeeds: [],
              autocompleteMinChars: 1,
            ),
          ),
        ),
      ]);

      await tester.pumpWidget(
        loaderApp(const BrowsePage(), empty, platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.discovery.popular).hitTestable().last);
      await tester.pumpAndSettle();
      // The range menu sits at the end of the section tabs.
      await tester.tap(find.text(t.discovery.today).hitTestable().last);
      await tester.pumpAndSettle();
      final labels = [
        t.discovery.today,
        t.discovery.thisWeek,
        t.discovery.thisMonth,
      ];
      final left = tester
          .getTopLeft(find.text(labels.first).hitTestable().last)
          .dx;
      for (final label in labels) {
        final option = find.text(label).hitTestable().last;
        expect(option, findsOneWidget);
        expect(tester.getTopLeft(option).dx, left, reason: label);
      }
      await tester.tap(find.text(t.discovery.thisWeek).hitTestable().last);
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BrowsePage)),
      );
      expect(
        container.read(feedSelectionProvider)['yande']!.range,
        PopularRange.week,
      );
      expect(tester.takeException(), isNull);
      LocaleSettings.setLocaleSync(AppLocale.en);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final width in [320.0, 600.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'mode, range and historical date keep one header at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final definition = testSource('yande');
          BooruService.instance.useSourcesForTesting([
            BooruSource(
              sourceId: definition.sourceId,
              displayName: definition.displayName,
              protocol: definition.protocol,
              enabledByDefault: true,
              isAiSource: false,
              capabilities: SourceCapabilities(
                ratings: definition.capabilities.ratings,
                authKind: definition.capabilities.authKind,
                supportsSearch: true,
                supportsPostDetail: true,
                supportsAutocomplete: true,
                supportsRelatedPosts: false,
                supportsOriginal: true,
                supportsAuthenticatedMedia: false,
                supportsBackgroundDownload: true,
                discovery: const DiscoveryCapabilities(
                  popular: CapabilityAvailability.available,
                  commonTags: CapabilityAvailability.available,
                  popularRanges: [
                    PopularRange.day,
                    PopularRange.week,
                    PopularRange.month,
                  ],
                  historicalRanges: [
                    PopularRange.day,
                    PopularRange.week,
                    PopularRange.month,
                  ],
                  timeBasis: PopularTimeBasis.indexTimeWindow,
                  additionalFeeds: [],
                  autocompleteMinChars: 1,
                ),
              ),
            ),
          ]);
          await tester.pumpWidget(
            loaderApp(const BrowsePage(), empty, scale: scale),
          );
          await tester.pumpAndSettle();
          final header = tester.getRect(find.byType(FrostPageHeader));
          expect(header.height, lessThan(180));
          if (width == 1440 && scale == 1) {
            final container = ProviderScope.containerOf(
              tester.element(find.byType(BrowsePage)),
            );
            container
                .read(feedSelectionProvider.notifier)
                .select(
                  'yande',
                  const FeedCollectionRequest(
                    kind: FeedKind.recentPopular,
                    range: PopularRange.week,
                  ),
                );
            await tester.pumpAndSettle();
            final rangeMenu = find
                .byWidgetPredicate(
                  (widget) =>
                      widget is FrostMenuAnchor &&
                      widget.entries.whereType<FrostMenuAction>().any(
                        (entry) => entry.label == t.discovery.historicalPopular,
                      ),
                )
                .hitTestable()
                .first;
            final entries = tester.widget<FrostMenuAnchor>(rangeMenu).entries;
            expect(
              entries.whereType<FrostMenuAction>().where(
                (entry) => entry.label == t.discovery.historicalPopular,
              ),
              hasLength(1),
            );
            expect(
              entries.whereType<FrostMenuSection>().where(
                (entry) => entry.header == t.discovery.historicalPopular,
              ),
              isEmpty,
            );
            await tester.tap(rangeMenu);
            await tester.pumpAndSettle();
            await tester.tap(find.text(t.discovery.historicalPopular));
            await tester.pumpAndSettle();
            final scales = find.descendant(
              of: find.byType(FrostDialog),
              matching: find.byType(FrostPicker<PopularRange>),
            );
            expect(scales, findsOneWidget);
            tester.widget<FrostPicker<PopularRange>>(scales).onChanged!(
              PopularRange.month,
            );
            await tester.pump();
            await tester.tap(find.text(t.generic.confirm));
            await tester.pumpAndSettle();
            expect(
              container.read(feedSelectionProvider)['yande']!.kind,
              FeedKind.historicalPopular,
            );
            expect(
              container.read(feedSelectionProvider)['yande']!.range,
              PopularRange.month,
            );
          }

          for (final kind in [
            FeedKind.recentPopular,
            FeedKind.historicalPopular,
            FeedKind.latest,
          ]) {
            ProviderScope.containerOf(tester.element(find.byType(BrowsePage)))
                .read(feedSelectionProvider.notifier)
                .select(
                  'yande',
                  FeedCollectionRequest(
                    kind: kind,
                    range: kind == FeedKind.latest ? null : PopularRange.month,
                    date: kind == FeedKind.historicalPopular
                        ? '2026-09-05'
                        : null,
                  ),
                );
            await tester.pump();
            expect(tester.getRect(find.byType(FrostPageHeader)), header);
            expect(tester.takeException(), isNull);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(
            tester.getSize(find.byType(FrostPinnedChrome)).height,
            greaterThan(500),
          );
        },
      );
    }
  }
  testWidgets(
    'request failure exposes source and HTTP diagnostics inside expandable details',
    (tester) async {
      await tester.pumpWidget(
        loaderApp(const BrowsePage(), (_, _) async {
          throw const BooruError(
            code: BooruErrorCode.sourceUnavailable,
            sourceId: 'yande',
            httpStatus: 503,
            userMessageKey: 'booru.error.sourceUnavailable',
            diagnosticId: 'home-test',
          );
        }),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FrostErrorDetails), findsOneWidget);
      expect(
        tester
            .widget<FrostErrorDetails>(find.byType(FrostErrorDetails))
            .details,
        contains('source=yande'),
      );
      expect(
        tester
            .widget<FrostErrorDetails>(find.byType(FrostErrorDetails))
            .details,
        contains('HTTP=503'),
      );
      expect(find.text(t.generic.notFound), findsNothing);
    },
  );
}
