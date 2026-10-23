import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/discovery_logic.dart';
import 'package:booruflow/features/discovery/discovery_page.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/home/home_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import 'search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => values;
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

Widget browseTestApp(
  Widget child, {
  double scale = 1,
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.windows,
  GlobalKey<NavigatorState>? navigatorKey,
}) => TranslationProvider(
  child: ProviderScope(
    child: FrostScope(
      config: appFrostConfig,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: FrostTheme.build(
          config: appFrostConfig,
          brightness: brightness,
          platform: platform,
          locale: const Locale('en'),
        ),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: FrostLayoutScope(child: child),
          ),
        ),
      ),
    ),
  ),
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
      await tester.pumpWidget(browseTestApp(HomePage(loader: empty)));
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
      expect(header.middle, isNull);
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
          browseTestApp(
            DiscoveryPage(
              tags: const ['hatsune_miku'],
              sourceId: 'yande',
              loader: empty,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final header = tester.getRect(find.byType(FrostPageHeader));
        expect(header.height, width < 600 ? 48 : 52);
        expect(
          find.descendant(
            of: find.byType(FrostPageHeader),
            matching: find.text('hatsune_miku'),
          ),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
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
        await tester.pumpWidget(browseTestApp(HomePage(loader: empty)));
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
  testWidgets(
    'empty filtered collection retains one reset action in the conditions',
    (tester) async {
      SettingsService.ratings = [ContentRating.general];
      await tester.pumpWidget(browseTestApp(HomePage(loader: empty)));
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
    },
  );
  testWidgets(
    'phone source label keeps the content keyline and is not ellipsized by the mode reservation',
    (tester) async {
      // Real bundled metrics matter here; Ahem makes Latin labels artificially
      // wide and cannot establish production text visibility at a phone width.
      await (FontLoader(
        'Noto Sans JP',
      )..addFont(rootBundle.load('assets/fonts/NotoSansJP-Subset.ttf'))).load();
      await (FontLoader(
        'Noto Sans SC',
      )..addFont(rootBundle.load('assets/fonts/NotoSansSC-Subset.ttf'))).load();
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
        browseTestApp(
          HomePage(loader: empty),
          platform: TargetPlatform.android,
        ),
      );
      await tester.pumpAndSettle();
      final label = find.descendant(
        of: find.byType(FrostTitleMenu),
        matching: find.text('Danbooru'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.getTopLeft(label).dx, 12);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'fresh settings load all sources with latest feed and no explicit ratings',
    (tester) async {
      final calls = <CollectionKey>[];
      await tester.pumpWidget(
        browseTestApp(
          HomePage(
            loader: (key, _) async {
              calls.add(key);
              return const PostPage(items: [], exhausted: true);
            },
          ),
        ),
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
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'clearing ratings reloads defaults without remounting the collection view',
    (tester) async {
      SettingsService.ratings = [ContentRating.general];
      final calls = <List<ContentRating>>[];
      await tester.pumpWidget(
        browseTestApp(
          HomePage(
            loader: (key, _) async {
              calls.add(key.ratings);
              return const PostPage(items: [], exhausted: true);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = tester.state(find.byType(PostCollectionView));
      SettingsService.ratings = [];
      await tester.pumpAndSettle();
      expect(calls, [
        [ContentRating.general],
        <ContentRating>[],
      ]);
      expect(tester.state(find.byType(PostCollectionView)), same(original));
    },
  );
  testWidgets(
    'global ratings remain visible and editable when unsupported by this source',
    (tester) async {
      SettingsService.ratings = [ContentRating.explicit];
      await tester.pumpWidget(
        browseTestApp(
          DiscoveryPage(tags: const ['sky'], sourceId: 'yande', loader: empty),
        ),
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
    testWidgets('phone mode/range menu aligns its groups in $locale', (
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
        browseTestApp(
          HomePage(loader: empty),
          platform: TargetPlatform.android,
        ),
      );
      await tester.pumpAndSettle();
      // Picker.auto chooses its form from the available toolbar width.
      final picker = find.byType(FrostPicker<FeedKind>).hitTestable().last;
      await tester.tap(
        find
            .descendant(of: picker, matching: find.text(t.discovery.latest))
            .hitTestable()
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.discovery.popular).hitTestable().last);
      await tester.pumpAndSettle();
      final more = find
          .byWidgetPredicate(
            (w) => w is FrostTooltip && w.message == t.frost.more,
          )
          .hitTestable();
      final rangeTrigger = find
          .byWidgetPredicate((w) => w is FrostToolbarMenuButton)
          .hitTestable();
      if (rangeTrigger.evaluate().isNotEmpty) {
        await tester.tap(rangeTrigger.first);
      } else {
        expect(more, findsOneWidget);
        await tester.tap(more);
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .text([t.discovery.timeRange, t.discovery.today].join(' · '))
              .hitTestable()
              .last,
        );
      }
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
        tester.element(find.byType(DiscoveryPage)),
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
            browseTestApp(HomePage(loader: empty), scale: scale),
          );
          await tester.pumpAndSettle();
          final header = tester.getRect(find.byType(FrostPageHeader));
          expect(header.height, lessThan(180));
          if (width == 1440 && scale == 1) {
            final container = ProviderScope.containerOf(
              tester.element(find.byType(HomePage)),
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
                      widget is FrostToolbarMenuButton &&
                      widget.entries.whereType<FrostMenuAction>().any(
                        (entry) => entry.label == t.discovery.historicalPopular,
                      ),
                )
                .hitTestable()
                .first;
            final entries = tester
                .widget<FrostToolbarMenuButton>(rangeMenu)
                .entries;
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
            ProviderScope.containerOf(tester.element(find.byType(HomePage)))
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
            tester.getSize(find.byType(PostCollectionView)).height,
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
        browseTestApp(
          HomePage(
            loader: (_, _) async {
              throw const BooruError(
                code: BooruErrorCode.sourceUnavailable,
                sourceId: 'yande',
                httpStatus: 503,
                userMessageKey: 'booru.error.sourceUnavailable',
                diagnosticId: 'home-test',
              );
            },
          ),
        ),
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
