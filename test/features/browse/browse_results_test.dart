// Browse and results pages: feeds, results, query header and result marks.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/browse_page.dart';
import 'package:booruflow/features/browse/results_page.dart';
import 'package:booruflow/features/browse/widgets/browse_card.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/src/rust/api/booru_download.dart'
    show MediaFetchEvent;
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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

BooruSource _source(String id, {String? name, bool popular = false}) =>
    BooruSource(
      sourceId: id,
      displayName: name ?? id,
      protocol: BooruProtocol.moebooru,
      enabledByDefault: true,
      isAiSource: false,
      capabilities: SourceCapabilities(
        discovery: DiscoveryCapabilities(
          popular: popular
              ? CapabilityAvailability.available
              : CapabilityAvailability.unsupported,
          commonTags: CapabilityAvailability.available,
          popularRanges: popular
              ? const [PopularRange.day, PopularRange.week, PopularRange.month]
              : const [],
          historicalRanges: popular
              ? const [PopularRange.day, PopularRange.week, PopularRange.month]
              : const [],
          timeBasis: PopularTimeBasis.indexTimeWindow,
          additionalFeeds: const [],
          autocompleteMinChars: 1,
        ),
        ratings: const [ContentRating.general],
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

BooruPost _post(int id) => BooruPost(
  sourceId: 'yande',
  postId: '$id',
  postKey: 'yande:$id',
  rating: ContentRating.general,
  tags: const [],
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

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

/// A scripted engine: every feed or search page is produced by [script], which
/// receives the zero-based number of the call.
class _Engine implements BooruEngine {
  int loads = 0;
  Future<PostPage> Function(int call) script = (_) async =>
      PostPage(items: List.generate(12, (i) => _post(i + 1)), exhausted: true);

  Future<PostPage> _page() => script(loads++);

  @override
  Future<PostPage> feed({required FeedRequest request}) => _page();
  @override
  Future<PostPage> search({required SearchRequest request}) => _page();
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) async => MediaRequest(
    sourceId: sourceId,
    postId: postId,
    variant: variant,
    url: url,
    headers: [],
    routeKey: 'test',
    cacheKey: 'k-$postId-${variant.name}',
    authRevision: 0,
    routeRevision: '0',
    allowDiskCache: false,
  );
  @override
  Stream<MediaFetchEvent> streamMedia({required MediaRequest request}) async* {
    final bytes = base64Decode(_png);
    yield MediaFetchEvent.chunk(
      bytes: bytes,
      receivedBytesDecimal: '${bytes.length}',
      totalBytesDecimal: '${bytes.length}',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

void main() {
  late _Service service;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service();
  });

  void select(List<BooruSource> sources) {
    service.useSourcesForTesting(sources);
    BooruService.instance.useSourcesForTesting(sources);
    service.selectSource(sources.first.sourceId);
    BooruService.instance.selectSource(sources.first.sourceId);
  }

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(1147, 717),
    TargetPlatform platform = TargetPlatform.windows,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => page),
        GoRoute(
          path: AppRoute.results.path,
          name: AppRoute.results.name,
          builder: (_, _) => const SizedBox(),
        ),
        GoRoute(
          path: AppRoute.postDetail.path,
          name: AppRoute.postDetail.name,
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
          ],
          child: FrostScope(
            config: appFrostConfig,
            child: MaterialApp.router(
              routerConfig: router,
              theme: FrostTheme.build(
                config: appFrostConfig,
                brightness: Brightness.light,
                platform: platform,
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

  final downloadButton = find.byWidgetPredicate(
    (w) =>
        w is FrostButton && w.label == t.postDetail.download ||
        w is FrostMediaButton && w.label == t.postDetail.download,
    description: 'a download button',
  );

  // 5.1: several feeds put a FrostTabBar into the page.
  for (final (size, platform) in [
    (const Size(1147, 717), TargetPlatform.windows),
    (const Size(390, 844), TargetPlatform.android),
  ]) {
    testWidgets(
      'a source with several feeds shows a FrostTabBar in the header sections at ${size.width}',
      (tester) async {
        select([_source('yande', name: 'Yande.re', popular: true)]);
        await pumpPage(
          tester,
          const BrowsePage(),
          size: size,
          platform: platform,
        );
        expect(find.byType(AppSectionPage), findsOneWidget);
        expect(find.byType(FrostTabBar), findsOneWidget);
        final tabs = tester.widget<FrostTabBar>(find.byType(FrostTabBar)).tabs;
        expect(tabs.map((tab) => tab.label), [
          t.discovery.latest,
          t.discovery.popular,
        ]);
        // 5.1: the header starts with the source title menu.
        expect(find.byType(FrostTitleMenu), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // 5.1: one feed shows no tab row at all.
  for (final (size, platform) in [
    (const Size(1147, 717), TargetPlatform.windows),
    (const Size(390, 844), TargetPlatform.android),
  ]) {
    testWidgets(
      'a source with a single feed shows no tab row at ${size.width}',
      (tester) async {
        select([_source('yande', name: 'Yande.re')]);
        await pumpPage(
          tester,
          const BrowsePage(),
          size: size,
          platform: platform,
        );
        expect(find.byType(AppPage), findsOneWidget);
        expect(find.byType(AppSectionPage), findsNothing);
        expect(find.byType(FrostTabBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // 5.1: preferredTileWidth follows the thumbnail size; no fixed columns.
  for (final (size, width) in [
    (ThumbnailSize.small, 120.0),
    (ThumbnailSize.medium, 240.0),
    (ThumbnailSize.large, 320.0),
  ]) {
    testWidgets(
      'waterfall preferredTileWidth is $width for thumbnail size ${size.name}',
      (tester) async {
        SettingsService.thumbnailSize = size;
        select([_source('yande', name: 'Yande.re')]);
        await pumpPage(tester, const BrowsePage());
        final grid = tester.widget<FrostSliverDataWaterfallGrid<dynamic>>(
          find.byWidgetPredicate((w) => w is FrostSliverDataWaterfallGrid),
        );
        expect(grid.preferredTileWidth, width);
        expect(grid.columns, isNull);
        expect(grid.maxColumns, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // 5.1: the hover download button belongs to pointer density only.
  testWidgets('pointer density shows the card hover download button', (
    tester,
  ) async {
    select([_source('yande', name: 'Yande.re')]);
    await pumpPage(tester, const BrowsePage());
    final card = find.byType(BrowseCard).first;
    expect(
      find.descendant(of: card, matching: downloadButton),
      findsNothing,
      reason: 'not shown until the pointer is over the card',
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(card));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.descendant(of: card, matching: downloadButton), findsOneWidget);
    expect(
      downloadButton,
      findsOneWidget,
      reason: 'only the hovered card carries the one hover action',
    );
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.descendant(of: card, matching: downloadButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch density always shows the card download button', (
    tester,
  ) async {
    select([_source('yande', name: 'Yande.re')]);
    await pumpPage(
      tester,
      const BrowsePage(),
      size: const Size(390, 844),
      platform: TargetPlatform.android,
    );
    final card = find.byType(BrowseCard).first;
    expect(find.descendant(of: card, matching: downloadButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 5.1: the context menu header is "<source> · #<id>".
  testWidgets('card context menu data carries the "source · #id" header', (
    tester,
  ) async {
    select([_source('yande', name: 'Yande.re')]);
    await pumpPage(tester, const BrowsePage());
    final card = tester.widget<FrostMediaCard>(
      find
          .descendant(
            of: find.byType(BrowseCard).first,
            matching: find.byType(FrostMediaCard),
          )
          .first,
    );
    final sections = card.contextMenu.whereType<FrostMenuSection>().toList();
    expect(sections, isNotEmpty);
    expect(sections.first.header, 'Yande.re · #1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press opens the menu headed "source · #id"', (
    tester,
  ) async {
    select([_source('yande', name: 'Yande.re')]);
    await pumpPage(
      tester,
      const BrowsePage(),
      size: const Size(390, 844),
      platform: TargetPlatform.android,
    );
    await tester.longPress(find.byType(BrowseCard).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Yande.re · #1'), findsOneWidget);
    for (final label in [
      t.postDetail.download,
      t.discovery.copyLink,
      t.frost.openInBrowser,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  // 5.2: the query is the one-line title; the header has a source title menu.
  for (final (size, platform, headerHeight) in [
    (const Size(1147, 717), TargetPlatform.windows, 52.0),
    (const Size(360, 800), TargetPlatform.android, 48.0),
  ]) {
    testWidgets(
      'results page shows the query as its one-line title with the source in the more menu at ${size.width}',
      (tester) async {
        select([
          _source('yande', name: 'Yande.re'),
          _source('konachan_net', name: 'Konachan'),
        ]);
        await pumpPage(
          tester,
          ResultsPage(
            tags: const [
              'hatsune_miku',
              'long_hair',
              'twintails',
              'blue_eyes',
              'school_uniform',
              'smile',
              'solo',
              'sky',
            ],
            sourceId: 'yande',
          ),
          size: size,
          platform: platform,
        );
        final header = find.byType(FrostPageHeader);
        expect(header, findsOneWidget);
        expect(tester.getSize(header).height, headerHeight);
        final title = find.descendant(
          of: header,
          matching: find.textContaining('hatsune_miku'),
        );
        expect(title, findsOneWidget);
        // Without a title row the query is in the header's
        // inline search instead of a title.
        expect(
          find.descendant(of: header, matching: find.byType(InlineSearch)),
          findsOneWidget,
        );
        expect(tester.widget(title), isA<EditableText>());
        // Beside the search the row belongs to the query; the source is in the
        // more menu, under its own name.
        expect(
          find.descendant(of: header, matching: find.byType(FrostTitleMenu)),
          findsNothing,
        );
        await tester.tap(
          find
              .descendant(
                of: header,
                matching: find.byWidgetPredicate((w) {
                  return w is FrostToolbarMenuButton && w.label == t.frost.more;
                }),
              )
              .hitTestable()
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Yande.re').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // 5.1 state rule: a failed refresh keeps the content already on screen.
  testWidgets('a refresh failure keeps the existing cards visible', (
    tester,
  ) async {
    select([_source('yande', name: 'Yande.re')]);
    service.engine.script = (call) async {
      if (call == 0) {
        return PostPage(
          items: List.generate(12, (i) => _post(i + 1)),
          exhausted: true,
        );
      }
      throw const BooruError(
        code: BooruErrorCode.sourceUnavailable,
        sourceId: 'yande',
        httpStatus: 503,
        userMessageKey: 'booru.error.sourceUnavailable',
        diagnosticId: 'refresh-failure',
      );
    };
    await pumpPage(
      tester,
      const BrowsePage(),
      size: const Size(390, 844),
      platform: TargetPlatform.android,
    );
    expect(find.byType(BrowseCard), findsWidgets);
    expect(service.engine.loads, 1);
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axis == Axis.vertical,
    );
    // Touch refresh is a pull down from the top.
    await tester.timedDrag(
      vertical.first,
      const Offset(0, 500),
      const Duration(milliseconds: 500),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      service.engine.loads,
      greaterThanOrEqualTo(2),
      reason: 'the pull must have started a second load',
    );
    expect(find.byType(BrowseCard), findsWidgets);
    expect(find.byType(FrostErrorDetails), findsNothing);
    expect(find.byType(FrostEmptyState), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
