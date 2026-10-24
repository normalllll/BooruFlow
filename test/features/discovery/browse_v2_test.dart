import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/discovery_page.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/post_preview_card.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

import 'home_page_test.dart' show browseTestApp;
import 'search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class PendingMediaEngine implements BooruEngine {
  final pending = <Completer<MediaRequest>>[];
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) {
    final completer = Completer<MediaRequest>();
    pending.add(completer);
    return completer.future;
  }

  FeedRequest? lastFeed;
  SearchRequest? lastSearch;
  @override
  Future<String> feedWebUrl({required FeedRequest request}) async {
    lastFeed = request;
    return 'https://yande.re/post';
  }

  @override
  Future<String> searchWebUrl({required SearchRequest request}) async {
    lastSearch = request;
    return 'https://yande.re/post?tags=sky';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PendingMediaService extends BooruService {
  final mediaEngine = PendingMediaEngine();
  @override
  BooruEngine get engine => mediaEngine;
}

BooruPost browsePost(int id, {ContentRating rating = ContentRating.general}) =>
    BooruPost(
      sourceId: 'yande',
      postId: '$id',
      postKey: 'yande:$id',
      rating: rating,
      tags: const [],
      media: const [
        MediaVariant(
          kind: MediaVariantKind.sample,
          url: 'https://example.invalid/sample.jpg',
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
CollectionKey collectionKey(int revision) => CollectionKey(
  sourceId: 'yande',
  request: const FeedCollectionRequest(),
  ratings: const [],
  revision: revision,
);
Widget collectionApp({
  required CollectionKey collection,
  required CollectionLoader loader,
  required PendingMediaService service,
  double scale = 1,
  GlobalKey<PostCollectionViewState>? viewKey,
}) => ProviderScope(
  overrides: [booruServiceProvider.overrideWithValue(service)],
  child: browseTestApp(
    PostCollectionView(
      key: viewKey,
      collection: (key: collection, loader: loader),
      headerBuilder: (_, source) =>
          const FrostPageHeader(title: FrostText('Browse')),
    ),
    scale: scale,
  ),
);

void main() {
  late PendingMediaService service;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    service = PendingMediaService()
      ..useSourcesForTesting([testSource('yande')]);
  });
  for (final (width, expectedColumns) in [
    (390.0, 2),
    (720.0, 3),
    (1024.0, 4),
    (1440.0, 6),
    (2600.0, 8),
  ]) {
    testWidgets(
      'first frame skeleton uses $expectedColumns columns at $width and matches live cards',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final first = Completer<PostPage>();
        await tester.pumpWidget(
          collectionApp(
            collection: collectionKey(0),
            loader: (_, _) => first.future,
            service: service,
          ),
        );
        final skeletons = find.byType(FrostMediaCard);
        final firstRect = tester.getRect(skeletons.first),
            secondRect = tester.getRect(skeletons.at(1));
        const gap = FrostGap.grid;
        expect(secondRect.left - firstRect.right, gap);
        final grid = tester.widget<FrostSliverWaterfallGrid<int>>(
          find.byType(FrostSliverWaterfallGrid<int>),
        );
        final actualCount = frostWaterfallColumnCount(
          width: width - (width < 600 ? 24 : 40),
          preferredTileWidth: grid.preferredTileWidth,
          columns: grid.columns,
          maxColumns: grid.maxColumns,
          gap: grid.crossAxisSpacing,
          textScale: 1,
        );
        expect(actualCount, expectedColumns);
        first.complete(
          PostPage(items: List.generate(100, browsePost), exhausted: true),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          tester.getRect(find.byType(PostPreviewCard).first).width,
          firstRect.width,
        );
        expect(find.byType(PostPreviewCard).evaluate().length, lessThan(100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
  testWidgets(
    'collection switch shows skeleton immediately instead of retaining old images',
    (tester) async {
      final second = Completer<PostPage>();
      Future<PostPage> loader(CollectionKey key, String? _) => key.revision == 0
          ? Future.value(PostPage(items: [browsePost(1)], exhausted: true))
          : second.future;
      final key = GlobalKey<PostCollectionViewState>();
      var revision = 0;
      late StateSetter change;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            StatefulBuilder(
              builder: (context, update) {
                change = update;
                return PostCollectionView(
                  key: key,
                  collection: (key: collectionKey(revision), loader: loader),
                  headerBuilder: (_, source) =>
                      const FrostPageHeader(title: FrostText('Browse')),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<PostPreviewCard>(find.byType(PostPreviewCard)).post.id,
        '1',
      );
      change(() => revision = 1);
      await tester.pump();
      expect(find.byType(PostPreviewCard), findsNothing);
      expect(find.byType(FrostMediaCard), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SliverOpacity && widget.opacity < 1,
        ),
        findsNothing,
      );
      second.complete(PostPage(items: [browsePost(2)], exhausted: true));
      await tester.pump();
      expect(
        tester.widget<PostPreviewCard>(find.byType(PostPreviewCard)).post.id,
        '2',
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SliverOpacity && widget.opacity < 1,
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.byType(PostPreviewCard),
          matching: find.byType(FrostLayoutCrossfade),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'pagination keeps one footer without skeleton cards at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final more = Completer<PostPage>();
        final identity = collectionKey(0);
        Future<PostPage> loader(CollectionKey _, String? cursor) =>
            cursor == null
            ? Future.value(
                PostPage(
                  items: List.generate(100, browsePost),
                  nextCursor: 'next',
                  exhausted: false,
                ),
              )
            : more.future;
        await tester.pumpWidget(
          collectionApp(
            collection: identity,
            loader: loader,
            service: service,
            scale: scale,
          ),
        );
        await tester.pump();
        final view = tester.state<PostCollectionViewState>(
          find.byType(PostCollectionView),
        );
        unawaited(view.source.loadMore());
        await tester.pump();
        final grid = tester.widget<FrostSliverWaterfallGrid<Post>>(
          find.byType(FrostSliverWaterfallGrid<Post>),
        );
        expect(grid.items.length, 100);
        final scroll = tester
            .widget<FrostRefreshView>(find.byType(FrostRefreshView))
            .scrollController!;
        for (
          var attempt = 0;
          attempt < 8 &&
              find.byType(FrostLoadingMoreIndicator<Post>).evaluate().isEmpty;
          attempt++
        ) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pump();
        }
        expect(find.byType(FrostLoadingMoreIndicator<Post>), findsOneWidget);
        expect(tester.takeException(), isNull);
        more.complete(const PostPage(items: [], exhausted: true));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
  testWidgets('source-owned rate-limit retry is disabled until its deadline', (
    tester,
  ) async {
    var calls = 0;
    Future<PostPage> loader(CollectionKey _, String? cursor) async {
      if (++calls == 1) {
        throw const BooruError(
          code: BooruErrorCode.rateLimited,
          sourceId: 'yande',
          userMessageKey: 'booru.error.rateLimited',
          diagnosticId: 'limit',
          retryAfterSeconds: 2,
        );
      }
      return const PostPage(items: [], exhausted: true);
    }

    await tester.pumpWidget(
      collectionApp(
        collection: collectionKey(0),
        loader: loader,
        service: service,
      ),
    );
    await tester.pump();
    await tester.pump();
    final retry = find.byType(FrostButton);
    expect(tester.widget<FrostButton>(retry).onPressed, isNull);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2100)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<FrostButton>(retry).onPressed, isNotNull);
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'media discards a stale preparation failure and retries the current post',
    (tester) async {
      var id = 1;
      late StateSetter change;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            StatefulBuilder(
              builder: (context, update) {
                change = update;
                return Center(
                  child: SizedBox(
                    width: 240,
                    height: 320,
                    child: PostMedia(post: Post(browsePost(id))),
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(service.mediaEngine.pending, hasLength(1));
      change(() => id = 2);
      await tester.pump();
      expect(service.mediaEngine.pending, hasLength(2));
      service.mediaEngine.pending.first.completeError(
        StateError('stale failure'),
      );
      await tester.pump();
      expect(find.byType(FrostErrorDetails), findsNothing);
      service.mediaEngine.pending[1].completeError(
        const BooruError(
          code: BooruErrorCode.authenticationRequired,
          sourceId: 'yande',
          userMessageKey: 'booru.error.authenticationRequired',
          diagnosticId: 'current',
        ),
      );
      await tester.pump();
      expect(find.byType(FrostBadge), findsOneWidget);
      expect(
        tester.widget<FrostBadge>(find.byType(FrostBadge)).label,
        t.booruError.authenticationRequired,
      );
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is FrostButton && widget.label == t.generic.retry,
        ),
      );
      await tester.pump();
      expect(service.mediaEngine.pending, hasLength(3));
      await tester.pumpWidget(const SizedBox());
      service.mediaEngine.pending.last.completeError(
        StateError('disposed failure'),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'compact long press opens the shared fitted actions with post context',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var activated = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            Center(
              child: SizedBox(
                width: 180,
                child: PostPreviewCard(
                  post: Post(browsePost(1)),
                  onTap: (_, _) => activated++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.longPress(find.byType(FrostMediaCard));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(activated, 0);
      expect(find.text('yande · #1'), findsOneWidget);
      expect(
        find.byType(FrostThumbnail),
        findsNothing,
      ); // Shared menu uses the media identity heading.
      for (final label in [
        t.postDetail.download,
        t.discovery.copyLink,
        t.frost.openInBrowser,
        t.discovery.searchAuthor,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(FrostMenuAnchor), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is FrostButton && widget.label == t.frost.close,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'image-only card exposes four context actions and a hover download control',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            Center(
              child: SizedBox(
                width: 240,
                child: PostPreviewCard(
                  post: Post(browsePost(1)),
                  onTap: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );
      final card = tester.widget<FrostMediaCard>(find.byType(FrostMediaCard));
      expect(card.footer, isNull);
      expect(card.topStart, isNull);
      final entries = card.contextMenu
          .whereType<FrostMenuSection>()
          .single
          .entries
          .whereType<FrostMenuAction>();
      expect(entries.map((entry) => entry.label), [
        t.postDetail.download,
        t.discovery.copyLink,
        t.frost.openInBrowser,
        t.discovery.searchAuthor,
      ]);
      expect(
        entries.last.enabled,
        false,
      ); // No artist tag: never invent an invalid source query.
      final download = find.byWidgetPredicate(
        (widget) =>
            widget is FrostButton && widget.label == t.postDetail.download,
      );
      expect(download, findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(PostPreviewCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(download, findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(download, findsNothing);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'authentication replaces the GIF badge while preserving the resolution badge',
    (tester) async {
      final data = browsePost(1);
      final animated = Post(
        BooruPost(
          sourceId: data.sourceId,
          postId: data.postId,
          postKey: data.postKey,
          rating: data.rating,
          tags: data.tags,
          flags: data.flags,
          media: const [
            MediaVariant(
              kind: MediaVariantKind.sample,
              url: 'https://example.invalid/animation.gif',
              mediaType: MediaType.gif,
              width: 600,
              height: 800,
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            Center(
              child: SizedBox(
                width: 240,
                child: PostPreviewCard(post: animated, onTap: (_, _) {}),
              ),
            ),
          ),
        ),
      );
      FrostMediaCard card() =>
          tester.widget<FrostMediaCard>(find.byType(FrostMediaCard));
      expect(
        card().topStart,
        isA<FrostBadge>().having(
          (badge) => badge.label,
          'label',
          t.discovery.mediaAnimation,
        ),
      );
      expect(
        card().bottomEnd,
        isA<FrostBadge>().having((badge) => badge.label, 'label', '600 × 800'),
      );
      service.mediaEngine.pending.single.completeError(
        const BooruError(
          code: BooruErrorCode.authenticationRequired,
          sourceId: 'yande',
          userMessageKey: 'booru.error.authenticationRequired',
          diagnosticId: 'auth-card',
        ),
      );
      await tester.pump();
      expect(find.byType(FrostBadge), findsNWidgets(2));
      expect(
        card().topStart,
        isA<FrostBadge>().having(
          (badge) => badge.label,
          'label',
          t.booruError.authenticationRequired,
        ),
      );
      expect(
        card().bottomEnd,
        isA<FrostBadge>().having((badge) => badge.label, 'label', '600 × 800'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'author action routes to the artist tag and source, never the uploader name',
    (tester) async {
      final item = Post(
        BooruPost(
          sourceId: 'yande',
          postId: '1',
          postKey: 'yande:1',
          author: 'uploader_name',
          rating: ContentRating.general,
          media: const [],
          tags: const [
            BooruTag(name: 'creator_画師', category: TagCategory.artist),
          ],
          flags: const PostFlags(
            hasChildren: false,
            isPending: false,
            isDeleted: false,
            isAiGenerated: false,
          ),
        ),
      );
      Uri? resultUri;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              final action =
                  postMenuEntries(
                        context: context,
                        post: item,
                        download: () {},
                      ).last
                      as FrostMenuAction;
              return FrostButton(
                label: 'Artist action',
                onPressed: action.onSelected,
              );
            },
          ),
          GoRoute(
            path: '/results',
            name: AppRoute.taggedPosts.name,
            builder: (_, state) {
              resultUri = state.uri;
              return const FrostText('Results');
            },
          ),
        ],
      );
      try {
        await tester.pumpWidget(
          TranslationProvider(
            child: FrostScope(
              config: appFrostConfig,
              child: MaterialApp.router(
                routerConfig: router,
                theme: FrostTheme.build(
                  config: appFrostConfig,
                  brightness: Brightness.light,
                  platform: TargetPlatform.windows,
                  locale: const Locale('en'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Artist action'));
        await tester.pumpAndSettle();
        expect(find.text('Results'), findsOneWidget);
        final uri = resultUri!;
        expect(uri.path, '/results');
        expect(uri.queryParameters['source'], 'yande');
        expect(jsonDecode(uri.queryParameters['tags']!), ['creator_画師']);
        expect(uri.toString(), isNot(contains('uploader_name')));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        router.dispose();
      }
    },
  );
  for (final tags in [
    null,
    const ['sky'],
  ]) {
    testWidgets(
      'copy query link sends the typed request to Rust and copies its website result: $tags',
      (tester) async {
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
        await tester.pumpWidget(
          ProviderScope(
            overrides: [booruServiceProvider.overrideWithValue(service)],
            child: browseTestApp(
              DiscoveryPage(
                tags: tags,
                sourceId: 'yande',
                loader: (_, _) async =>
                    const PostPage(items: [], exhausted: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final moreAnchor = find.byWidgetPredicate(
          (widget) =>
              widget is FrostMenuAnchor &&
              widget.entries.any(
                (entry) =>
                    entry is FrostMenuAction &&
                    entry.label == t.discovery.copyQueryLink,
              ),
        );
        await tester.tap(moreAnchor);
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.discovery.copyQueryLink));
        await tester.pumpAndSettle();
        expect(
          copied,
          tags == null
              ? 'https://yande.re/post'
              : 'https://yande.re/post?tags=sky',
        );
        if (tags == null) {
          expect(service.mediaEngine.lastFeed?.kind, FeedKind.latest);
        } else {
          expect(service.mediaEngine.lastSearch?.queryText, 'sky');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
