import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;
import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/posts/logic.dart' as posts;
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/widgets/post_detail_controls.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/post_preview_card.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../support/preseeded_media.dart';
import '../discovery/browse_v2_test.dart' show PendingMediaEngine;
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart'
    show SearchRepositoryFake, testSource;
import 'post_media_handoff_test.dart' show seed;

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

BooruPost data(String id, {int? width = 4096, int? height = 2894}) => BooruPost(
  sourceId: 'yande',
  postId: id,
  postKey: 'yande:$id',
  author: 'uploader_not_artist',
  webUrl: 'https://yande.re/post/show/$id',
  sourceUrl: 'https://example.invalid/work/$id',
  rating: ContentRating.general,
  score: 128,
  createdAtIso8601: '2026-10-12T01:02:03Z',
  tags: const [
    BooruTag(name: 'actual_artist', category: TagCategory.artist),
    BooruTag(name: 'sky', category: TagCategory.general),
  ],
  media: [
    for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
      MediaVariant(
        kind: kind,
        url: 'https://example.invalid/$id/${kind.name}.png',
        width: width,
        height: height,
        byteLengthDecimal: '2600000',
        checksum: const Checksum(
          algorithm: ChecksumAlgorithm.md5,
          value: '0123456789abcdef0123456789abcdef',
        ),
        extension_: 'png',
      ),
  ],
  flags: const PostFlags(
    hasChildren: false,
    isPending: false,
    isDeleted: false,
    isAiGenerated: false,
  ),
);

class _Window extends ChangeNotifier implements FrostWindowActions {
  @override
  FrostCaptionState get captionState => const FrostCaptionState(
    maximized: false,
    active: false,
    maximizeHovered: false,
    maximizePressed: false,
    failed: false,
  );
  @override
  Future<void> minimize() async {}
  @override
  Future<void> toggleMaximized() async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> retry() async {}
  @override
  void updateHitRegions(List<FrostHitRegion> regions) {}
}

class _Engine extends PendingMediaEngine {
  bool holdMedia = false;
  int postLoads = 0;
  final preparations = <(String, MediaVariantKind), int>{};
  final held = <(MediaRequest, Completer<MediaRequest>)>[];
  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async {
    postLoads++;
    return data(postId);
  }

  @override
  Stream<MediaFetchEvent> streamMedia({required MediaRequest request}) async* {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    yield MediaFetchEvent.chunk(
      bytes: bytes,
      receivedBytesDecimal: '${bytes.length}',
      totalBytesDecimal: '${bytes.length}',
    );
  }

  MediaRequest request(String id, MediaVariantKind kind) => MediaRequest(
    sourceId: 'yande',
    postId: id,
    variant: kind,
    url: 'https://example.invalid/$id/${kind.name}.png',
    headers: [],
    routeKey: 'test',
    cacheKey: 'b4-$id-${kind.name}',
    authRevision: 0,
    routeRevision: '0',
    allowDiskCache: false,
  );
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) {
    final key = (postId, variant);
    preparations[key] = (preparations[key] ?? 0) + 1;
    final value = request(postId, variant);
    if (!holdMedia) return Future.value(value);
    final pending = Completer<MediaRequest>();
    held.add((value, pending));
    return pending.future;
  }
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

Finder button(String label) => find
    .byWidgetPredicate(
      (widget) => widget is FrostButton && widget.label == label,
    )
    .hitTestable()
    .first;

void main() {
  late _Service service;
  late MemoryImage preview;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service()..useSourcesForTesting([testSource('yande')]);
    BooruService.instance.useSourcesForTesting([testSource('yande')]);
    preview = MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  Future<void> images(WidgetTester tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await seed(tester, preview);
    for (final id in ['101', '102']) {
      for (final kind in [MediaVariantKind.sample, MediaVariantKind.original]) {
        final provider = RustExtendedNetworkImageProvider(
          mediaStream: preseededMedia,
          request: service.engine.request(id, kind),
        );
        await seed(tester, provider);
        // Match the new display-width hints; these are cached test pixels,
        // independent of the platform codec's asynchronous network work.
        for (final width in [180, 390, 644, 720, 1060, 1440]) {
          await seed(
            tester,
            RustExtendedNetworkImageProvider(
              mediaStream: preseededMedia,
              request: service.engine.request(id, kind),
              decodeWidth: width,
            ),
          );
        }
      }
    }
  }

  Widget scope(Widget child, {CollectionLoader? loader}) => ProviderScope(
    overrides: [
      booruServiceProvider.overrideWithValue(service),
      tagSuggestionRepositoryProvider.overrideWithValue(SearchRepositoryFake()),
      downloadItemsProvider.overrideWith(_Downloads.new),
      collectionLoaderProvider.overrideWithValue(
        loader ??
            (_, _) async =>
                PostPage(items: [data('101'), data('102')], exhausted: true),
      ),
    ],
    child: child,
  );
  Future<void> pump(WidgetTester tester) async {
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  for (final width in [180.0, 360.0]) {
    testWidgets(
      'preview keeps localized resolution at the bottom end at $width',
      (tester) async {
        await tester.pumpWidget(
          scope(
            browseTestApp(
              Center(
                child: SizedBox(
                  width: width,
                  child: PostPreviewCard(
                    post: Post(data('101')),
                    onTap: (_, _) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await pump(tester);
        final card = tester.widget<FrostMediaCard>(find.byType(FrostMediaCard));
        expect(card.bottomEnd, isA<FrostBadge>());
        expect((card.bottomEnd! as FrostBadge).label, '4,096 × 2,894');
        final badge = tester.getRect(find.text('4,096 × 2,894'));
        final bounds = tester.getRect(find.byType(FrostMediaCard));
        expect(badge.center.dx, greaterThan(bounds.center.dx));
        expect(badge.center.dy, greaterThan(bounds.center.dy));
        expect(
          bounds.contains(badge.topLeft) && bounds.contains(badge.bottomRight),
          true,
        );
        LocaleSettings.setLocaleSync(AppLocale.ja);
        await pump(tester);
        expect(
          tester.widget<FrostMediaCard>(find.byType(FrostMediaCard)).bottomEnd,
          isA<FrostBadge>(),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('unknown resolution does not show the media geometry fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      scope(
        browseTestApp(
          Center(
            child: SizedBox(
              width: 180,
              child: PostPreviewCard(
                post: Post(data('101', width: null, height: null)),
                onTap: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await pump(tester);
    expect(
      tester.widget<FrostMediaCard>(find.byType(FrostMediaCard)).bottomEnd,
      isNull,
    );
    expect(find.text('1 × 1'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'listing artwork dimensions drive card ratio and badge before original URL exists',
    (tester) async {
      final post = Post(
        BooruPost(
          sourceId: 'yande',
          postId: '101',
          postKey: 'yande:101',
          width: 1309,
          height: 2000,
          originalFileSizeDecimal: '2397010',
          originalFileExtension: 'png',
          rating: ContentRating.general,
          tags: const [],
          media: const [
            MediaVariant(
              kind: MediaVariantKind.sample,
              url: 'https://example.invalid/101/sample.avif',
              extension_: 'avif',
              mediaType: MediaType.avif,
            ),
          ],
          flags: const PostFlags(
            hasChildren: false,
            isPending: false,
            isDeleted: false,
            isAiGenerated: false,
          ),
        ),
      );
      expect(post.dimensions, (1309, 2000));
      expect(post.fileUrl, isNull);
      expect(post.displayMedia.width, isNull);
      await tester.pumpWidget(
        scope(
          browseTestApp(
            Center(
              child: SizedBox(
                width: 180,
                child: PostPreviewCard(post: post, onTap: (_, _) {}),
              ),
            ),
          ),
        ),
      );
      await pump(tester);
      final card = tester.widget<FrostMediaCard>(find.byType(FrostMediaCard));
      expect(card.aspectRatio, 1309 / 2000);
      expect((card.bottomEnd! as FrostBadge).label, '1,309 × 2,000');
      final size = tester.getSize(find.byType(FrostMediaCard));
      expect(size.width / size.height, closeTo(1309 / 2000, .001));
      final modules = postInformationModules(post);
      expect(
        modules
            .map((item) => item.child)
            .whereType<FrostModule>()
            .singleWhere((module) => module.key == const ValueKey('dimensions'))
            .value,
        '1,309 × 2,000',
      );
      expect(
        modules
            .map((item) => item.child)
            .whereType<FrostModule>()
            .singleWhere((module) => module.key == const ValueKey('file-size'))
            .value,
        '2.3 MB',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final cancelFirst in [false, true]) {
    testWidgets(
      'predictive card return restores the painted source cancelFirst=$cancelFirst',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        AppRouter.router.go('/');
        service.engine.holdMedia = true;
        await images(tester);
        await tester.pumpWidget(
          scope(
            TranslationProvider(child: const BooruFlowApp(checkUpdates: false)),
          ),
        );
        await pump(tester);
        for (final media in tester.widgetList<PostMedia>(
          find.byType(PostMedia),
        )) {
          await seed(
            tester,
            RustExtendedNetworkImageProvider(
              mediaStream: preseededMedia,
              request: service.engine.request(
                media.post.id,
                media.media?.kind ?? MediaVariantKind.sample,
              ),
              decodeWidth: media.decodeWidth,
            ),
          );
        }
        service.engine.holdMedia = false;
        for (final (request, pending) in service.engine.held) {
          pending.complete(request);
        }
        await pump(tester);
        await tester.tap(find.byType(FrostMediaCard).first);
        await pump(tester);
        expect(find.byType(PostDetailPage), findsOneWidget);
        Future<void> gesture(String method, [double? progress]) async {
          await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            'flutter/backgesture',
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(
                method,
                progress == null
                    ? null
                    : {
                        'touchOffset': [20 + progress * 200, 300.0],
                        'progress': progress,
                        'swipeEdge': 0,
                      },
              ),
            ),
            (_) {},
          );
        }

        if (cancelFirst) {
          await gesture('startBackGesture', 0);
          await tester.pump();
          await gesture('updateBackGestureProgress', .5);
          await tester.pump();
          await gesture('cancelBackGesture');
          await pump(tester);
          expect(find.byType(PostDetailPage), findsOneWidget);
        }
        await gesture('startBackGesture', 0);
        await tester.pump();
        await gesture('updateBackGestureProgress', .5);
        await tester.pump();
        await gesture('commitBackGesture');
        // Check the first rendered frame without the detail, rather than only
        // observing a fully settled route after an arbitrary delay.
        var landed = false;
        for (var frame = 0; frame < 90; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (find.byType(PostDetailPage).evaluate().isEmpty) {
            landed = true;
            break;
          }
        }
        expect(landed, isTrue);
        final source = find.byType(PostPreviewCard).first;
        final pixels = find
            .descendant(of: source, matching: find.byType(RawImage))
            .hitTestable();
        expect(
          pixels,
          findsOneWidget,
          reason: 'the source Hero placeholder must end on landing',
        );
        expect(tester.renderObject<RenderImage>(pixels).image, isNotNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
  testWidgets(
    'natural long stage keeps media header until the actual stage has scrolled away',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      service.engine.holdMedia = true;
      final base = data('101');
      final post = Post(
        BooruPost(
          sourceId: base.sourceId,
          postId: base.postId,
          postKey: base.postKey,
          rating: base.rating,
          flags: base.flags,
          media: [
            for (final media in base.media)
              MediaVariant(
                kind: media.kind,
                url: media.url,
                width: 100,
                height: 500,
              ),
          ],
          tags: [
            for (var i = 0; i < 80; i++)
              BooruTag(name: 'long_tag_$i', category: TagCategory.general),
          ],
        ),
      );
      final page = ProviderScope(
        overrides: [
          posts
              .postAttributionDetailProvider((sourceId: 'yande', postId: '101'))
              .overrideWith((_) async => post),
        ],
        child: PostDetailPage(args: PostDetailRouteArgs(post: post)),
      );
      await tester.pumpWidget(scope(browseTestApp(page)));
      await pump(tester);
      final scrollable = find
          .descendant(
            of: find.byType(FrostDetailLayout),
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(tester.getSize(find.byType(FrostMediaStage)).height, 1950);
      position.jumpTo(600);
      await pump(tester);
      expect(
        FrostOnMediaChromeScope.inkOf(
          tester.element(find.byType(FrostPageHeader)),
        ),
        isNotNull,
      );
      position.jumpTo(2000);
      await pump(tester);
      expect(
        FrostOnMediaChromeScope.inkOf(
          tester.element(find.byType(FrostPageHeader)),
        ),
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [720.0, 1440.0]) {
    testWidgets(
      'detail next button clamps a scrolled information pane at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await images(tester);
        final base = data('101');
        final first = Post(
          BooruPost(
            sourceId: base.sourceId,
            postId: base.postId,
            postKey: base.postKey,
            rating: base.rating,
            tags: [
              ...base.tags,
              for (var i = 0; i < 80; i++)
                BooruTag(
                  name: 'long_tag_name_$i',
                  category: TagCategory.general,
                ),
            ],
            media: base.media,
            flags: base.flags,
          ),
        );
        final second = Post(data('102'));
        await tester.pumpWidget(
          scope(
            browseTestApp(
              ProviderScope(
                overrides: [
                  for (final post in [first, second])
                    posts
                        .postAttributionDetailProvider((
                          sourceId: post.sourceId,
                          postId: post.id,
                        ))
                        .overrideWith((_) async => post),
                ],
                child: PostDetailPage(
                  args: PostDetailRouteArgs(
                    post: first,
                    collection: [first, second],
                    preview: preview,
                  ),
                ),
              ),
            ),
          ),
        );
        await pump(tester);
        final scroll = find.descendant(
          of: find.byType(FrostDetailLayout),
          matching: find.byType(CustomScrollView),
        );
        final scrollable = find
            .descendant(
              of: scroll,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first;
        final state = tester.state<ScrollableState>(scrollable);
        state.position.jumpTo(state.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(state.position.pixels, greaterThan(0));
        await tester.tap(button(t.frost.next));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await pump(tester);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey(('detail-stage', 'yande:102'))),
          findsOneWidget,
        );
        final current = tester.state<ScrollableState>(scrollable);
        expect(current, same(state));
        expect(
          current.position.pixels,
          inInclusiveRange(
            current.position.minScrollExtent,
            current.position.maxScrollExtent,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'compact scroll replaces media controls with creator header and retains media State',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await images(tester);
      final base = data('101');
      final post = Post(
        BooruPost(
          sourceId: base.sourceId,
          postId: base.postId,
          postKey: base.postKey,
          rating: base.rating,
          score: base.score,
          createdAtIso8601: base.createdAtIso8601,
          sourceUrl: base.sourceUrl,
          tags: [
            ...base.tags,
            for (var i = 0; i < 80; i++)
              BooruTag(name: 'long_tag_name_$i', category: TagCategory.general),
          ],
          media: base.media,
          flags: base.flags,
        ),
      );
      await tester.pumpWidget(
        scope(
          browseTestApp(
            ProviderScope(
              overrides: [
                posts
                    .postAttributionDetailProvider((
                      sourceId: post.sourceId,
                      postId: post.id,
                    ))
                    .overrideWith((_) async => post),
              ],
              child: PostDetailPage(
                args: PostDetailRouteArgs(post: post, preview: preview),
              ),
            ),
          ),
        ),
      );
      await pump(tester);
      final stage = find.byKey(
        const ValueKey(('detail-stage', 'yande:101')),
        skipOffstage: false,
      );
      final state = tester.state(stage);
      final requests = Map.of(service.engine.preparations);
      expect(find.byType(FrostPageHeader), findsOneWidget);
      final scroll = find.descendant(
        of: find.byType(PostDetailPage),
        matching: find.byType(CustomScrollView),
      );
      await tester.drag(scroll, const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(
        FrostOnMediaChromeScope.inkOf(
          tester.element(find.byType(FrostPageHeader)),
        ),
        isNull,
      );
      expect(
        find.descendant(
          of: find.byType(FrostPageHeader),
          matching: find.text('actual artist'),
        ),
        findsOneWidget,
      );
      expect(tester.state(stage), same(state));
      expect(service.engine.preparations, requests);
      await tester.drag(scroll, const Offset(0, 8000));
      await tester.pumpAndSettle();
      expect(find.byType(FrostPageHeader), findsOneWidget);
      expect(tester.state(stage), same(state));
      expect(service.engine.preparations, requests);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'related images include cached relationships and report only known parent and child counts',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await images(tester);
      Post related(String id, String? parent) {
        final base = data(id);
        return Post(
          BooruPost(
            sourceId: base.sourceId,
            postId: base.postId,
            postKey: base.postKey,
            rating: base.rating,
            tags: base.tags,
            media: base.media,
            flags: PostFlags(
              parentId: parent,
              hasChildren: id == '101',
              isPending: false,
              isDeleted: false,
              isAiGenerated: false,
            ),
          ),
        );
      }

      final collection = [
        related('100', null),
        related('101', '100'),
        related('102', '101'),
        related('103', '101'),
      ];
      final post = collection[1];
      await tester.pumpWidget(
        scope(
          browseTestApp(
            ProviderScope(
              overrides: [
                posts
                    .postAttributionDetailProvider((
                      sourceId: post.sourceId,
                      postId: post.id,
                    ))
                    .overrideWith((_) async => post),
              ],
              child: PostDetailPage(
                args: PostDetailRouteArgs(
                  post: post,
                  collection: collection,
                  initialIndex: 1,
                  preview: preview,
                ),
              ),
            ),
          ),
        ),
      );
      await pump(tester);
      expect(
        find.text(
          '${t.postDetail.parentCount(count: '1')} · ${t.postDetail.childCount(count: '2')}',
        ),
        findsOneWidget,
      );
      final strip = tester.widget<FrostThumbnailStrip>(
        find.byType(FrostThumbnailStrip),
      );
      expect(strip.itemCount, 4);
      expect(strip.selectedIndex, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'compact media header contains only onMedia controls and no overlaid title $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await images(tester);
        await tester.pumpWidget(
          scope(
            browseTestApp(
              FrostWindowCaptionScope(
                systemBackdropActive: true,
                child: PostDetailPage(
                  args: PostDetailRouteArgs(
                    post: Post(data('101')),
                    preview: preview,
                  ),
                ),
              ),
              brightness: brightness,
            ),
          ),
        );
        await pump(tester);
        final stage = find.byKey(const ValueKey(('detail-stage', 'yande:101')));
        final click = tester.widget<FrostClickSurface>(
          find.descendant(of: stage, matching: find.byType(FrostClickSurface)),
        );
        expect(click.borderRadius, BorderRadius.zero);
        expect(click.feedback, FrostClickFeedback.media);
        final header = find.byType(FrostPageHeader);
        expect(header, findsOneWidget);
        expect(
          find.descendant(of: header, matching: find.byType(FrostText)),
          findsNothing,
        );
        final buttons = tester.widgetList<FrostButton>(
          find.descendant(of: header, matching: find.byType(FrostButton)),
        );
        expect(buttons, isNotEmpty);
        for (final button in buttons) {
          final glyphs = find.descendant(
            of: find.byWidget(button),
            matching: find.byType(FrostIcon),
          );
          for (final glyph in glyphs.evaluate()) {
            final tokens = FrostThemeTokens.of(glyph);
            expect(FrostOnMediaChromeScope.inkOf(glyph), tokens.onMediaInk);
            expect((glyph.widget as FrostIcon).color, tokens.onMediaInk);
          }
          final plate = find.descendant(
            of: find.byWidget(button),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration as ShapeDecoration).shape is CircleBorder &&
                  (w.decoration as ShapeDecoration).color ==
                      FrostThemeTokens.of(tester.element(header)).onMediaScrim,
            ),
          );
          expect(plate, findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [390.0, 720.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R3 first frame layout width=$width text=$scale follows decoded pixels and keeps real information',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await images(tester);
          await tester.pumpWidget(
            scope(
              browseTestApp(
                PostDetailPage(
                  args: PostDetailRouteArgs(
                    post: Post(data('101')),
                    preview: preview,
                  ),
                ),
                scale: scale,
              ),
            ),
          );
          final stage = find.byKey(
            const ValueKey(('detail-stage', 'yande:101')),
          );
          final frame = find
              .descendant(of: stage, matching: find.byType(FrostMediaFrame))
              .first;
          final rect = tester.getRect(frame);
          // The decoded preview fixture is square, unlike 4096 x 2894 metadata.
          final available = width < 900
              ? Size(width, width < 600 ? width : 540)
              : Size(
                  width - 380,
                  900 - tester.getSize(find.byType(FrostPageHeader)).height,
                );
          final contained = applyBoxFit(
            BoxFit.contain,
            const Size(1, 1),
            available,
          ).destination;
          expect(rect.width, closeTo(contained.width, .001));
          expect(rect.height, closeTo(contained.height, .001));
          expect(
            rect.width == available.width || rect.height == available.height,
            isTrue,
          );
          final layout = tester.widget<FrostDetailLayout>(
            find.byType(FrostDetailLayout),
          );
          expect(layout.headerPlacement, FrostDetailHeaderPlacement.page);
          expect(find.byType(RawImage), findsWidgets);
          expect(find.text('actual artist'), findsOneWidget);
          expect(find.text('uploader_not_artist'), findsNothing);
          expect(
            postInformationModules(Post(data('101'))).last.child,
            isA<FrostModule>(),
          );
          await pump(tester);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('detail uses only the owning Back $platform width=$width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await images(tester);
        var calls = 0;
        await tester.pumpWidget(
          scope(
            browseTestApp(
              FrostShell(
                destinations: const [
                  FrostNavDestination(
                    icon: FrostIconData.glyph(Icons.home),
                    label: 'Browse',
                  ),
                ],
                selectedIndex: null,
                atDestinationRoot: false,
                onDestinationSelected: (_) {},
                canGoBack: true,
                onBack: () => calls++,
                showsMobileNavigation: false,
                child: PostDetailPage(
                  args: PostDetailRouteArgs(
                    post: Post(data('101')),
                    preview: preview,
                  ),
                ),
              ),
              platform: platform,
            ),
          ),
        );
        await pump(tester);
        final pageBack = find.descendant(
          of: find.byType(PostDetailPage),
          matching: find.byWidgetPredicate(
            (w) => w is FrostTooltip && w.message == 'Back',
          ),
        );
        expect(pageBack, width >= 600 ? findsNothing : findsOneWidget);
        final back = find
            .byWidgetPredicate((w) => w is FrostTooltip && w.message == 'Back')
            .hitTestable();
        expect(back, findsOneWidget);
        await tester.tap(back);
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final width in [390.0, 1440.0]) {
    testWidgets('native viewer bounds glass and merges overflow width=$width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await images(tester);
      final window = _Window();
      addTearDown(window.dispose);
      await tester.pumpWidget(
        scope(
          browseTestApp(
            FrostWindowCaptionScope(
              window: window,
              child: ImageZoomPage(
                args: ImageViewerRouteArgs(
                  collection: [Post(data('101'))],
                  initialIndex: 0,
                  preview: preview,
                ),
              ),
            ),
          ),
        ),
      );
      await pump(tester);
      final surface = find.byWidgetPredicate(
        (widget) =>
            widget is FrostSurface &&
            widget.role == FrostSurfaceRole.onMediaChrome,
      );
      final headerSurface = find.ancestor(
        of: find.byType(PostMediaHeader),
        matching: surface,
      );
      expect(tester.getRect(headerSurface).top, 0);
      expect(
        tester.getSize(headerSurface).height,
        FrostPageHeader.verticalHeight,
      );
      final plates = surface.evaluate().where(
        (element) => tester.getSize(find.byWidget(element.widget)).width < 100,
      );
      expect(plates, hasLength(2));
      for (final plate in plates) {
        final context = tester.element(find.byWidget(plate.widget));
        expect(
          tester.getSize(find.byWidget(plate.widget)),
          Size.square(FrostControlSize.regular.height(context)),
        );
      }
      expect(find.byType(FrostCaptionButtons), findsNothing);
      expect(
        tester.getCenter(button(t.frost.close)).dy,
        lessThan(FrostPageHeader.verticalHeight),
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(find.bySemanticsLabel('yande · #101'), findsWidgets);
        final more = find
            .byWidgetPredicate(
              (w) => w is FrostTooltip && w.message == t.frost.more,
            )
            .hitTestable();
        expect(more, findsOneWidget);
        await tester.tap(more);
        await tester.pumpAndSettle();
        expect(find.text(t.discovery.copyLink), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
  test(
    'missing metadata is omitted while media geometry has a finite fallback',
    () {
      final post = Post(
        BooruPost(
          sourceId: 'yande',
          postId: 'unknown',
          postKey: 'yande:unknown',
          rating: ContentRating.unknown,
          tags: [],
          media: const [
            MediaVariant(
              kind: MediaVariantKind.original,
              url: 'https://example.invalid/unknown',
              width: 0,
              height: 0,
            ),
          ],
          flags: data('101').flags,
        ),
      );
      expect(post.aspectRatio, 1);
      final modules = postInformationModules(
        post,
      ).map((item) => item.child as FrostModule).toList();
      expect(modules, isEmpty);
    },
  );
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'detail Add to search preserves end caret and compact keyboard policy at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const channel = MethodChannel('frost_window');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'getState'
              ? {'revision': 0, 'active': true}
              : null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        AppRouter.router.go('/');
        await images(tester);
        await tester.pumpWidget(
          scope(
            TranslationProvider(child: const BooruFlowApp(checkUpdates: false)),
          ),
        );
        await pump(tester);
        unawaited(
          AppRouter.router.pushNamed<void>(
            AppRoute.postDetail.name,
            pathParameters: {'id': '101'},
            extra: PostDetailRouteArgs(post: Post(data('101'))),
          ),
        );
        await pump(tester);
        final sky = find.byWidgetPredicate(
          (w) => w is FrostTag && w.label == 'sky',
        );
        await tester.ensureVisible(sky);
        await pump(tester);
        await tester.tap(sky.hitTestable());
        await pump(tester);
        await tester.tap(find.text(t.postDetail.addToSearch).hitTestable());
        await pump(tester);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'sky ');
        expect(
          editor.controller.selection,
          const TextSelection.collapsed(offset: 4),
        );
        expect(editor.focusNode.hasFocus, isFalse);
        expect(AppRouter.currentUri.queryParameters['focus'], 'false');
        expect(tester.testTextInput.isVisible, isFalse);
        AppRouter.popRightNavigator();
        await pump(tester);
      },
      variant: TargetPlatformVariant.only(
        width < 600 ? TargetPlatform.android : TargetPlatform.windows,
      ),
    );
  }
  for (final known in [false, true]) {
    testWidgets(
      'missing tag classification does not invent a general color: known=$known',
      (tester) async {
        final base = data('101');
        final post = Post(
          BooruPost(
            sourceId: base.sourceId,
            postId: base.postId,
            postKey: base.postKey,
            rating: base.rating,
            media: base.media,
            flags: base.flags,
            tags: known
                ? base.tags
                : base.tags
                      .where((tag) => tag.category == TagCategory.general)
                      .toList(),
          ),
        );
        await tester.pumpWidget(
          scope(
            browseTestApp(
              SizedBox(width: 360, child: PostTagsModule(post: post)),
            ),
          ),
        );
        await pump(tester);
        final tags = tester.widgetList<FrostTag>(find.byType(FrostTag));
        expect(tags, isNotEmpty);
        expect(
          tags.every(
            (tag) => known ? tag.dataColor != null : tag.dataColor == null,
          ),
          isTrue,
        );
        if (!known) expect(find.text('General'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'technical display and copied information omit the real checksum',
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
      final post = Post(data('101'));
      expect(post.md5, '0123456789abcdef0123456789abcdef');
      await tester.pumpWidget(
        browseTestApp(
          Center(
            child: SizedBox(
              width: 500,
              child: PostTechnicalInformation(post: post),
            ),
          ),
        ),
      );
      expect(find.textContaining('MD5'), findsNothing);
      expect(find.textContaining(post.md5), findsNothing);
      await tester.tap(button(t.frost.copyDetails));
      await tester.pump();
      expect(copied, contains('ID: 101'));
      expect(copied, contains(t.postDetail.createdAt));
      expect(copied, isNot(contains(post.md5)));
      expect(copied, isNot(contains('MD5')));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'tag menu uses the canonical tag for clipboard and exposes all five operations',
    (tester) async {
      await images(tester);
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
        scope(
          browseTestApp(
            Center(
              child: SizedBox(
                width: 360,
                child: PostTagsModule(post: Post(data('101'))),
              ),
            ),
          ),
        ),
      );
      await pump(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is FrostTag && widget.label == 'sky',
        ),
      );
      await pump(tester);
      for (final label in [
        'Search this tag',
        'Add to search',
        'Exclude this tag',
        'Add as a custom tag',
        'Copy',
      ]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      await tester.tap(find.text('Copy').hitTestable());
      await pump(tester);
      expect(copied, 'sky');
      expect(find.text('Search this tag').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'same work in two card occurrences has different Hero identities',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await images(tester);
      final opened = <FrostMediaHeroTag?>[];
      await tester.pumpWidget(
        scope(
          browseTestApp(
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 2; i++)
                    SizedBox(
                      width: 180,
                      height: 220,
                      child: PostPreviewCard(
                        post: Post(data('101')),
                        onTap: (tag, image) {
                          expect(image, isNotNull);
                          opened.add(tag);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await pump(tester);
      final heroes = tester
          .widgetList<FrostMediaHero>(find.byType(FrostMediaHero))
          .toList();
      expect(heroes, hasLength(2));
      expect(identical(heroes[0].tag, heroes[1].tag), isFalse);
      await tester.tap(find.byType(FrostMediaCard).first);
      await tester.pump();
      await tester.tap(find.byType(FrostMediaCard).last);
      await tester.pump();
      expect(opened, hasLength(2));
      expect(identical(opened[0], opened[1]), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'sidebar toggles retain collection, scroll, card State and decoded pixels without reloading',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const channel = MethodChannel('frost_window');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            call.method == 'getState' ? {'revision': 0, 'active': true} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      AppRouter.router.go('/');
      service.engine.holdMedia = true;
      await images(tester);
      var loads = 0;
      await tester.pumpWidget(
        scope(
          TranslationProvider(child: const BooruFlowApp(checkUpdates: false)),
          loader: (_, _) async {
            loads++;
            return PostPage(
              items: List.generate(40, (i) => data('${101 + i}')),
              exhausted: true,
            );
          },
        ),
      );
      await pump(tester);
      for (final media in tester.widgetList<PostMedia>(
        find.byType(PostMedia),
      )) {
        await seed(
          tester,
          RustExtendedNetworkImageProvider(
            mediaStream: preseededMedia,
            request: service.engine.request(
              media.post.id,
              media.media?.kind ?? MediaVariantKind.sample,
            ),
            decodeWidth: media.decodeWidth,
          ),
        );
      }
      service.engine.holdMedia = false;
      for (final (request, pending) in service.engine.held) {
        pending.complete(request);
      }
      await pump(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await pump(tester);
      final scrollView = find
          .descendant(
            of: find.byType(PostCollectionView),
            matching: find.byType(CustomScrollView),
          )
          .first;
      await tester.drag(scrollView, const Offset(0, -120));
      await pump(tester);
      final card = find.byType(PostPreviewCard).hitTestable().first;
      final post = tester.widget<PostPreviewCard>(card).post;
      final stableCard = find.byKey(ValueKey(post.postKey));
      final media = find.descendant(
        of: stableCard,
        matching: find.byType(PostMedia),
      );
      final cardState = tester.state(stableCard),
          mediaState = tester.state(media);
      final collectionState = tester.state(find.byType(PostCollectionView));
      final raw = find.descendant(of: media, matching: find.byType(RawImage));
      final pixels = tester.renderObject<RenderImage>(raw).image;
      expect(pixels, isNotNull);
      final position = Scrollable.of(tester.element(stableCard)).position;
      final offset = position.pixels;
      final before = Map.of(service.engine.preparations);
      expect(loads, 1);
      for (var toggle = 0; toggle < 2; toggle++) {
        final label = SettingsService.sidebarExpanded
            ? 'Collapse sidebar'
            : 'Expand sidebar';
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is FrostTooltip && w.message == label,
          ),
        );
        await pump(tester);
        expect(loads, 1);
        expect(
          tester.state(find.byType(PostCollectionView)),
          same(collectionState),
        );
        expect(tester.state(stableCard), same(cardState));
        expect(tester.state(media), same(mediaState));
        expect(tester.renderObject<RenderImage>(raw).image, same(pixels));
        expect(position.pixels, offset);
        for (final entry in before.entries) {
          expect(
            service.engine.preparations[entry.key],
            entry.value,
            reason: '${entry.key} reloaded',
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
  testWidgets(
    'real root viewer preserves shell geometry, reports zoom and returns to the selected stage',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const channel = MethodChannel('frost_window');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            call.method == 'getState' ? {'revision': 0, 'active': true} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      AppRouter.router.go('/');
      service.engine.holdMedia = true;
      await images(tester);
      await tester.pumpWidget(
        scope(
          TranslationProvider(child: const BooruFlowApp(checkUpdates: false)),
        ),
      );
      await pump(tester);
      for (final media in tester.widgetList<PostMedia>(
        find.byType(PostMedia),
      )) {
        await seed(
          tester,
          RustExtendedNetworkImageProvider(
            mediaStream: preseededMedia,
            request: service.engine.request(
              media.post.id,
              media.media?.kind ?? MediaVariantKind.sample,
            ),
            decodeWidth: media.decodeWidth,
          ),
        );
      }
      service.engine.holdMedia = false;
      for (final (request, pending) in service.engine.held) {
        pending.complete(request);
      }
      await pump(tester);
      final sourceTag = tester
          .widget<FrostMediaHero>(
            find.descendant(
              of: find.byType(PostPreviewCard).first,
              matching: find.byType(FrostMediaHero),
            ),
          )
          .tag;
      await tester.tap(find.byType(FrostMediaCard).first);
      await pump(tester);
      expect(
        tester
            .widget<FrostMediaHero>(
              find.descendant(
                of: find.byType(PostDetailPage),
                matching: find.byType(FrostMediaHero),
              ),
            )
            .tag,
        same(sourceTag),
      );
      final stage = find.byKey(const ValueKey(('detail-stage', 'yande:101')));
      final stageState = tester.state(stage);
      final detailLoads = service.engine.postLoads;
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is FrostTooltip && w.message == 'Collapse sidebar',
        ),
      );
      await pump(tester);
      expect(service.engine.postLoads, detailLoads);
      expect(tester.state(stage), same(stageState));
      await tester.pumpAndSettle();
      final beforeStage = tester.getRect(stage);
      expect(tester.takeException(), isNull, reason: 'card to detail');
      expect(
        service.engine.preparations.keys.where(
          (key) => key.$2 == MediaVariantKind.original,
        ),
        isEmpty,
      );
      service.engine.holdMedia = true;
      final heldBefore = service.engine.held.length;
      await tester.tap(button('View original'));
      await tester.pump();
      expect(find.byType(ImageZoomPage), findsNothing);
      expect(tester.state(stage), same(stageState));
      expect(tester.getRect(stage), beforeStage);
      expect(
        tester.widget<FrostButton>(button('View original')).loading,
        isTrue,
      );
      expect(
        find.descendant(of: stage, matching: find.byType(RawImage)),
        findsWidgets,
      );
      final media = tester.widget<PostMedia>(stage);
      await seed(
        tester,
        RustExtendedNetworkImageProvider(
          mediaStream: preseededMedia,
          request: service.engine.request('101', MediaVariantKind.original),
          decodeWidth: media.decodeWidth,
        ),
      );
      service.engine.holdMedia = false;
      for (final (request, pending) in service.engine.held.skip(heldBefore)) {
        pending.complete(request);
      }
      await pump(tester);
      expect(
        find
            .byWidgetPredicate(
              (w) => w is FrostButton && w.label == 'View original',
            )
            .hitTestable(),
        findsNothing,
      );

      final endpoints = find
          .byWidgetPredicate(
            (w) => w is FrostMediaHero && identical(w.tag, sourceTag),
            skipOffstage: false,
          )
          .evaluate()
          .toList();
      expect(endpoints, hasLength(2));
      final owners = endpoints.map((e) => Navigator.of(e)).toSet();
      expect(
        owners,
        hasLength(2),
        reason: 'branch grid and content detail have distinct Navigator owners',
      );
      for (final endpoint in endpoints) {
        expect(ModalRoute.of(endpoint)!.isCurrent, isTrue);
      }
      await tester.tap(
        find
            .descendant(of: stage, matching: find.byType(FrostClickSurface))
            .first,
      );
      var enteringFrames = 0;
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final viewer = find.byType(ImageZoomPage);
        if (viewer.evaluate().isEmpty) continue;
        if (ModalRoute.of(tester.element(viewer))!.animation!.status ==
            AnimationStatus.forward) {
          enteringFrames++;
          for (final presence in tester.widgetList<FrostPresence>(
            find.descendant(of: viewer, matching: find.byType(FrostPresence)),
          )) {
            expect(
              presence.visible,
              isTrue,
              reason: 'viewer chrome enters with the page during frame $frame',
            );
          }
        }
      }
      expect(enteringFrames, greaterThan(0));
      await pump(tester);
      final viewerHeader = tester.widget<PostMediaHeader>(
        find.descendant(
          of: find.byType(ImageZoomPage),
          matching: find.byType(PostMediaHeader),
        ),
      );
      expect(viewerHeader.windowButtons, isFalse);
      expect(tester.takeException(), isNull, reason: 'detail to root viewer');
      expect(find.byType(ImageZoomPage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ImageZoomPage),
          matching: find.byType(FrostMediaHero),
        ),
        findsNothing,
      );

      expect(AppRouter.currentUri.path, AppRoute.imageViewer.path);
      final retainedStage = find.byKey(
        const ValueKey(('detail-stage', 'yande:101')),
        skipOffstage: false,
      );
      expect(tester.state(retainedStage), same(stageState));
      expect(tester.getRect(retainedStage), beforeStage);
      expect(find.byType(FrostShell), findsOneWidget);
      expect(
        find.byType(FrostShellDestination).hitTestable(),
        findsNothing,
        reason:
            'Opaque viewport paint and modal hit testing cover the retained shell',
      );
      expect(find.byType(FrostShell, skipOffstage: false), findsOneWidget);
      final viewer = tester.element(find.byType(ImageZoomPage));
      expect(ModalRoute.of(viewer)!.opaque, isFalse);
      expect(
        ModalRoute.of(viewer),
        isNot(isA<PageRoute<void>>()),
        reason: "the whole-window modal must not start root Hero collection",
      );
      final viewport = find.byType(FrostMediaViewport);
      await tester.pump(const Duration(seconds: 2));
      await pump(tester);
      expect(
        find
            .byWidgetPredicate(
              (widget) => widget is FrostButton && widget.label == 'Zoom out',
            )
            .hitTestable(),
        findsNothing,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(viewport));
      await mouse.moveTo(tester.getCenter(viewport) + const Offset(20, 20));
      await pump(tester);
      expect(
        find
            .byWidgetPredicate(
              (widget) => widget is FrostButton && widget.label == 'Zoom out',
            )
            .hitTestable(),
        findsOneWidget,
      );
      await mouse.removePointer();
      await tester.tapAt(tester.getCenter(viewport));
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tapAt(tester.getCenter(viewport));
      await pump(tester);
      double scale() => tester
          .widget<InteractiveViewer>(
            find.descendant(
              of: viewport,
              matching: find.byType(InteractiveViewer),
            ),
          )
          .transformationController!
          .value
          .getMaxScaleOnAxis();
      expect(scale(), closeTo(2.5, .001));
      expect(find.text('250%'), findsNothing);
      await tester.tap(button('Zoom out'));
      await pump(tester);
      expect(scale(), closeTo(2.5 / 1.5, .001));
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await pump(tester);
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(tester.widget<FrostButton>(button('Zoom out')).onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await pump(tester);
      expect(scale(), closeTo(1.5, .001));
      expect(find.text('100%'), findsNothing);
      for (var step = 0; step < 5; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.pumpAndSettle();
      }
      expect(scale(), 5);
      await mouse.moveTo(tester.getCenter(viewport) + const Offset(1, -10));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<FrostButton>(button('Zoom in')).onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pump(tester);
      expect(
        find.byKey(
          const ValueKey(('detail-stage', 'yande:102')),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 100));
      final closingRoute = ModalRoute.of(
        tester.element(find.byType(ImageZoomPage)),
      );
      expect(
        closingRoute!.animation!.status,
        AnimationStatus.reverse,
        reason: 'Escape starts the normal route return immediately',
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.byType(ImageZoomPage), findsNothing);
      expect(find.textContaining('#102'), findsWidgets);
      final baselineOverlays = find
          .byType(Overlay, skipOffstage: false)
          .evaluate()
          .length;
      for (var visit = 0; visit < 10; visit++) {
        await tester.tap(
          find.byKey(const ValueKey(('detail-stage', 'yande:102'))),
        );
        await tester.pumpAndSettle();
        final current = tester.element(find.byType(ImageZoomPage));
        expect(ModalRoute.of(current)!.opaque, false);
        expect(find.byType(FrostShell), findsOneWidget);
        expect(
          find.byType(FrostShellDestination).hitTestable(),
          findsNothing,
          reason:
              'Opaque viewport paint and modal hit testing cover the retained shell',
        );
        expect(find.byType(FrostMediaViewport), findsOneWidget);
        if (visit == 0 && defaultTargetPlatform == TargetPlatform.android) {
          Future<void> gesture(String method, [double? progress]) async {
            await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              SystemChannels.backGesture.name,
              SystemChannels.backGesture.codec.encodeMethodCall(
                MethodCall(
                  method,
                  progress == null
                      ? null
                      : {
                          'touchOffset': [20.0 + progress * 300, 300.0],
                          'progress': progress,
                          'swipeEdge': 0,
                        },
                ),
              ),
              (_) {},
            );
          }

          final route = ModalRoute.of(current)!;
          expect(route.popGestureEnabled, isTrue);
          final sourceState = tester.state(
            find.byType(PostDetailPage, skipOffstage: false),
          );
          await gesture('startBackGesture', 0);
          await tester.pump();
          expect(route.navigator!.userGestureInProgress, isTrue);
          final chrome = find.descendant(
            of: find.byType(ImageZoomPage),
            matching: find.byType(FrostPresence),
          );
          expect(chrome, findsWidgets);
          for (final presence in tester.widgetList<FrostPresence>(chrome)) {
            expect(
              presence.visible,
              isTrue,
              reason: 'predictive back carries ordinary page chrome',
            );
          }
          await gesture('updateBackGestureProgress', .35);
          await tester.pump();
          expect(route.animation!.value, lessThan(1));
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          expect(
            find.byKey(
              const ValueKey(('detail-stage', 'yande:102')),
              skipOffstage: false,
            ),
            findsOneWidget,
            reason: 'the active post cannot change mid-gesture',
          );
          await gesture('cancelBackGesture');
          await tester.pumpAndSettle();
          expect(route.isCurrent, isTrue);
          expect(route.navigator!.userGestureInProgress, isFalse);
          for (final presence in tester.widgetList<FrostPresence>(chrome)) {
            expect(presence.visible, isTrue);
          }
          expect(
            tester.state(find.byType(PostDetailPage, skipOffstage: false)),
            same(sourceState),
          );
          await gesture('startBackGesture', 0);
          await gesture('updateBackGestureProgress', .7);
          await tester.pump();
          await gesture('commitBackGesture');
        } else if (visit == 1) {
          await tester.timedDrag(
            find.byType(FrostMediaViewport),
            const Offset(0, 180),
            const Duration(milliseconds: 700),
          );
          final viewerRoute = ModalRoute.of(current)!;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(viewerRoute.isCurrent, isTrue);
          expect(
            viewerRoute.animation!.value,
            1,
            reason:
                'The viewport owns the complete exit; the route cannot fade early.',
          );
          await tester.pump(FrostMotion.exit);
          await tester.pump();
          expect(
            find.byType(ImageZoomPage),
            findsNothing,
            reason: 'A completed viewport pop adds no second route exit.',
          );
        } else {
          if (visit == 2) {
            await tester.timedDrag(
              find.byType(FrostMediaViewport),
              const Offset(0, 55),
              const Duration(milliseconds: 700),
            );
            await tester.pumpAndSettle();
            expect(
              ModalRoute.of(current)!.isCurrent,
              isTrue,
              reason: 'Short pull springs back without closing',
            );
          }
          await tester.binding.handlePopRoute();
        }
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(find.byType(ImageZoomPage), findsNothing);
        expect(find.byType(PostDetailPage), findsOneWidget);
        expect(
          find.byType(Overlay, skipOffstage: false).evaluate().length,
          baselineOverlays,
        );
        expect(
          find
              .byKey(const ValueKey(('detail-stage', 'yande:102')))
              .hitTestable(),
          findsOneWidget,
          reason: 'visit $visit remains clickable',
        );
        expect(tester.takeException(), isNull);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PostDetailPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.windows,
    }),
  );
}
