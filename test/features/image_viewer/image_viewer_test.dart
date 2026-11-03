// Full-screen image viewer, opened through the real route (AppRoute.imageViewer).
import 'dart:async';
import 'dart:convert';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/booru_flow_app.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart'
    show MediaFetchEvent;
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';

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

BooruSource _source() => BooruSource(
  sourceId: 'yande',
  displayName: 'Yande.re',
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

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

BooruPost _data(String id) => BooruPost(
  sourceId: 'yande',
  postId: id,
  postKey: 'yande:$id',
  webUrl: 'https://yande.re/post/show/$id',
  rating: ContentRating.general,
  tags: const [],
  media: [
    for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
      MediaVariant(
        kind: kind,
        url: 'https://example.invalid/$id/${kind.name}.png',
        width: 4096,
        height: 2894,
        byteLengthDecimal: '3145728',
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

class _Engine implements BooruEngine {
  @override
  Future<PostPage> feed({required FeedRequest request}) async =>
      const PostPage(items: [], exhausted: true);
  @override
  Future<PostPage> search({required SearchRequest request}) async =>
      const PostPage(items: [], exhausted: true);
  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async => _data(postId);
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

/// Controls over the media may be a FrostButton or a FrostMediaButton.
Finder _button(String label) => find.byWidgetPredicate(
  (w) =>
      w is FrostButton && w.label == label ||
      w is FrostMediaButton && w.label == label,
  description: 'button "$label"',
);

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  const total = 40;
  late _Service service;
  late MemoryImage preview;
  late List<int> changes;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service();
    service.useSourcesForTesting([_source()]);
    BooruService.instance.useSourcesForTesting([_source()]);
    preview = MemoryImage(base64Decode(_png));
    changes = [];
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  /// Opens the viewer on [initial] of a 40-post collection and returns the
  /// window height used.
  Future<double> openViewer(WidgetTester tester, {int initial = 2}) async {
    const size = Size(1280, 800);
    tester.view.physicalSize = size;
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
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          booruServiceProvider.overrideWithValue(service),
          tagSuggestionRepositoryProvider.overrideWithValue(_Tags()),
          downloadItemsProvider.overrideWith(_Downloads.new),
        ],
        child: TranslationProvider(
          child: BooruFlowApp(
            windowController: FrostWindowController(
              minimumSize: const Size(320, 480),
            ),
            checkUpdates: false,
          ),
        ),
      ),
    );
    await _settle(tester);
    unawaited(
      AppRouter.router.pushNamed<void>(
        AppRoute.imageViewer.name,
        extra: ImageViewerRouteArgs(
          collection: [
            for (var i = 0; i < total; i++) Post(_data('${101 + i}')),
          ],
          initialIndex: initial,
          preview: preview,
          onIndexChanged: changes.add,
        ),
      ),
    );
    await _settle(tester);
    expect(AppRouter.currentUri.path, AppRoute.imageViewer.path);
    return size.height;
  }

  // 5.4: top row = close, counter, more.
  testWidgets('the counter "3 / 40" sits in the top row beside close', (
    tester,
  ) async {
    final height = await openViewer(tester);
    final counter = find.text('3 / $total');
    expect(counter, findsOneWidget);
    final close = _button(t.frost.close);
    expect(close, findsOneWidget);
    final counterY = tester.getCenter(counter).dy;
    final closeY = tester.getCenter(close).dy;
    expect(counterY, lessThan(height * .2), reason: 'top row');
    expect(
      (counterY - closeY).abs(),
      lessThan(16),
      reason: 'same row as close',
    );
    expect(
      tester.getCenter(counter).dx,
      closeTo(tester.view.physicalSize.width / 2, 40),
      reason: 'the counter is centred between close and more',
    );
    expect(
      tester.getCenter(_button(t.frost.more)).dy,
      lessThan(height * .2),
      reason: 'more is at the end of the top row',
    );
    expect(tester.takeException(), isNull);
  });

  // 5.4: Esc closes the viewer.
  testWidgets('Esc closes the viewer', (tester) async {
    await openViewer(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester, 20);
    expect(AppRouter.currentUri.path, isNot(AppRoute.imageViewer.path));
    expect(AppRouter.currentUri.path, AppRoute.posts.path);
    expect(find.text('3 / $total'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 5.4: arrow keys change the index and sync it back.
  testWidgets('right arrow changes the index and calls onIndexChanged', (
    tester,
  ) async {
    await openViewer(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.text('4 / $total'), findsOneWidget);
    expect(find.text('3 / $total'), findsNothing);
    expect(changes, [3]);
    expect(AppRouter.currentUri.path, AppRoute.imageViewer.path);
    expect(tester.takeException(), isNull);
  });

  testWidgets('left arrow changes the index and calls onIndexChanged', (
    tester,
  ) async {
    await openViewer(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(find.text('2 / $total'), findsOneWidget);
    expect(changes, [1]);
    expect(tester.takeException(), isNull);
  });

  // 5.4: bottom row = zoom out, zoom in (then original / download).
  testWidgets('zoom out and zoom in are in the bottom row, not the top', (
    tester,
  ) async {
    final height = await openViewer(tester);
    final zoomOut = _button(t.postDetail.zoomOut);
    final zoomIn = _button(t.postDetail.zoomIn);
    expect(zoomOut, findsOneWidget);
    expect(zoomIn, findsOneWidget);
    final outY = tester.getCenter(zoomOut).dy;
    final inY = tester.getCenter(zoomIn).dy;
    expect(outY, greaterThan(height * .75), reason: 'bottom row');
    expect((outY - inY).abs(), lessThan(8), reason: 'one row');
    expect(
      tester.getCenter(zoomOut).dx,
      lessThan(tester.getCenter(zoomIn).dx),
      reason: 'zoom out comes before zoom in',
    );
    expect(
      tester.getCenter(find.text('3 / $total')).dy,
      lessThan(outY),
      reason: 'the counter is no longer at the bottom',
    );
    expect(tester.takeException(), isNull);
  });
}
