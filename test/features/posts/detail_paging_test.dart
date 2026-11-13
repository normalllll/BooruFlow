// Paging in the post detail and the image viewer goes past the loaded items
// when the collection it opened from has more pages.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/app/ambient_artwork.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/image_viewer/viewer_stage.dart';
import 'package:booruflow/features/posts/logic.dart' show getSimilarProvider;
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/video_playback.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart'
    show MediaFetchEvent;
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/frost_app_layers.dart';
import '../discovery/search_interaction_test.dart' show testSource;
import 'post_media_handoff_test.dart' show seed;
import 'video_playback_test.dart' show FakePlayback;

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

/// A preview whose pixels arrive when the test says so.
class _DeferredImage extends ImageProvider<_DeferredImage> {
  final completer = Completer<ui.Image>();
  @override
  Future<_DeferredImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    _DeferredImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    completer.future.then((image) => ImageInfo(image: image)),
  );
}

/// Takes the window artwork requests of the page and nothing else.
class _RecordingAmbient extends AmbientArtwork {
  final selected = <String>[];
  @override
  Future<void> select(
    Object owner,
    Post post, {
    ImageProvider? preview,
  }) async => selected.add(post.postKey);
}

/// Records what a page adds and whether it started a flight for it.
class _RecordingDownloads extends BooruDownloads {
  final added = <Post>[];
  bool? flew;
  @override
  Future<bool> add(
    Post post, {
    bool announce = true,
    bool Function()? flight,
  }) async {
    added.add(post);
    flew = flight?.call() ?? false;
    return true;
  }
}

class _Tags extends TagSuggestionRepository {
  @override
  Future<void> initialize() async {}
  @override
  String? displayName(String source, String locale, String value) => null;
}

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

/// Every post carries a tag named after its id, so the shown post can be
/// identified by its tag alone. Only the original takes [extension]; the
/// sample stays an image, as the cover of a video.
BooruPost _data(String id, {String extension = 'png'}) => BooruPost(
  sourceId: 'yande',
  postId: id,
  postKey: 'yande:$id',
  webUrl: 'https://yande.re/post/show/$id',
  rating: ContentRating.general,
  tags: [BooruTag(name: 'tag_$id', category: TagCategory.general)],
  media: [
    for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
      MediaVariant(
        kind: kind,
        url:
            'https://example.invalid/$id/${kind.name}.${(kind == MediaVariantKind.original ? extension : 'png')}',
        width: _sizes[id]?.$1 ?? 4096,
        height: _sizes[id]?.$2 ?? 2894,
        extension_: (kind == MediaVariantKind.original ? extension : 'png'),
      ),
  ],
  flags: PostFlags(
    parentId: _parents[id],
    hasChildren: _parents.containsValue(id),
    isPending: false,
    isDeleted: false,
    isAiGenerated: false,
  ),
);

/// Media sizes by post id; a post not listed here is landscape.
final _sizes = <String, (int, int)>{};

/// The parent of a post by id, for the posts that belong to a family.
final _parents = <String, String>{};

/// The original extension of the posts the engine returns for a detail.
String _detailExtension = 'png';

class _Engine implements BooruEngine {
  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async => _data(postId, extension: _detailExtension);
  @override
  Future<List<BooruPost>> relatedPosts({
    required String sourceId,
    required String postId,
  }) async => const [];
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

/// A collection with [pages] more pages of one post each after the ones
/// loaded; [failures] loads throw before one succeeds.
class _Pager {
  _Pager({
    required List<String> loaded,
    required this.remaining,
    this.extension = 'png',
  }) : loaded = [
         for (final id in loaded) Post(_data(id, extension: extension)),
       ];
  final String extension;
  final List<Post> loaded;
  final List<String> remaining;
  int failures = 0;
  int calls = 0;

  bool get hasMore => remaining.isNotEmpty;

  PostPaging get paging => PostPaging(
    hasMore: () => hasMore,
    loadMore: () async {
      calls++;
      if (failures > 0) {
        failures--;
        throw StateError('page load failed');
      }
      loaded.add(Post(_data(remaining.removeAt(0), extension: extension)));
      return List.of(loaded);
    },
  );
}

Finder _tag(String name) =>
    find.byWidgetPredicate((w) => w is FrostTag && w.label == name);

Finder _button(String label) => find.byWidgetPredicate(
  (w) =>
      w is FrostButton && w.label == label ||
      w is FrostMediaButton && w.label == label,
  description: 'button "$label"',
);

VoidCallback? _onPressed(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  return widget is FrostButton
      ? widget.onPressed
      : (widget as FrostMediaButton).onPressed;
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 14; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _Service service;
  late MemoryImage preview;
  setUp(() async {
    _detailExtension = 'png';
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service();
    service.useSourcesForTesting([testSource('yande')]);
    BooruService.instance.useSourcesForTesting([testSource('yande')]);
    preview = MemoryImage(base64Decode(_png));
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(1147, 717),
    TargetPlatform platform = TargetPlatform.windows,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => page)],
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
            postPlaybackFactoryProvider.overrideWithValue(FakePlayback.new),
            ...overrides,
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
    await _settle(tester);
  }

  group('post detail', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      _Pager pager, {
      required List<int> changes,
      bool withPaging = true,
    }) => pumpPage(
      tester,
      PostDetailPage(
        args: PostDetailRouteArgs(
          post: pager.loaded.last,
          collection: List.of(pager.loaded),
          initialIndex: pager.loaded.length - 1,
          preview: preview,
          onIndexChanged: changes.add,
          paging: withPaging ? pager.paging : null,
        ),
      ),
    );

    TestGesture? mouse;
    var mouseAdded = false;
    setUp(() {
      mouse = null;
      mouseAdded = false;
      _sizes.clear();
    });

    /// Hovers the stage so the paging buttons show, then returns Next.
    Future<Finder> hoverNext(WidgetTester tester) async {
      final page = tester.getRect(find.byType(PostDetailPage));
      final scroller = find.descendant(
        of: find.byType(PostDetailPage),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axis == Axis.vertical,
        ),
      );
      final stageRight = tester.getRect(scroller).left;
      mouse ??= await tester.createGesture(kind: PointerDeviceKind.mouse);
      if (!mouseAdded) {
        await mouse!.addPointer(location: Offset.zero);
        mouseAdded = true;
        addTearDown(mouse!.removePointer);
      }
      await mouse!.moveTo(Offset(stageRight - 30, page.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return _button(t.frost.next);
    }

    Future<void> press(WidgetTester tester, Finder next) async {
      await tester.tap(next);
      await _settle(tester);
    }

    testWidgets('the buttons stay put when the media changes shape', (
      tester,
    ) async {
      _sizes['101'] = (1000, 2000);
      _sizes['102'] = (2000, 1000);
      final pager = _Pager(loaded: ['101', '102'], remaining: []);
      await pumpDetail(tester, pager, changes: []);
      Rect media() => tester.getRect(
        find.descendant(
          of: find.byType(FrostMediaStage),
          matching: find.byType(AspectRatio),
        ),
      );
      final wide = media();
      final next = tester.getRect(await hoverNext(tester));
      final previous = tester.getRect(_button(t.frost.previous));
      await press(tester, _button(t.frost.previous));
      expect(_tag('tag_101'), findsOneWidget);
      expect(media().width, lessThan(wide.width));
      expect(tester.getRect(await hoverNext(tester)), next);
      expect(tester.getRect(_button(t.frost.previous)), previous);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Next is enabled at the loaded end while more exists and '
        'pressing it lands on the next post', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103']);
      final changes = <int>[];
      await pumpDetail(tester, pager, changes: changes);
      expect(_tag('tag_102'), findsOneWidget);
      final next = await hoverNext(tester);
      expect(_onPressed(tester, next), isNotNull);
      await press(tester, next);
      expect(pager.calls, greaterThanOrEqualTo(1));
      expect(_tag('tag_103'), findsOneWidget);
      expect(changes, [2]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Next disables once nothing more can load', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103']);
      await pumpDetail(tester, pager, changes: []);
      final next = await hoverNext(tester);
      await press(tester, next);
      expect(_tag('tag_103'), findsOneWidget);
      expect(pager.hasMore, isFalse);
      await hoverNext(tester);
      expect(_onPressed(tester, _button(t.frost.next)), isNull);
    });

    testWidgets('a failing load keeps the current post and a retry works', (
      tester,
    ) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103'])
        ..failures = 1;
      final changes = <int>[];
      await pumpDetail(tester, pager, changes: changes);
      final next = await hoverNext(tester);
      await press(tester, next);
      expect(_tag('tag_102'), findsOneWidget);
      expect(_tag('tag_103'), findsNothing);
      expect(changes, isEmpty);
      final retry = await hoverNext(tester);
      expect(_onPressed(tester, retry), isNotNull);
      await press(tester, retry);
      expect(_tag('tag_103'), findsOneWidget);
      expect(changes, [2]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a playing video pages like the cover does', (tester) async {
      final pager = _Pager(
        loaded: ['101', '102'],
        remaining: ['103'],
        extension: 'mp4',
      );
      _detailExtension = 'mp4';
      final changes = <int>[];
      await pumpDetail(tester, pager, changes: changes);
      final play = _button(t.frost.play);
      expect(play, findsWidgets);
      await tester.tap(play.first);
      await _settle(tester);
      expect(find.byType(FrostVideoFrame), findsOneWidget);
      final next = await hoverNext(tester);
      expect(_onPressed(tester, next), isNotNull);
      await press(tester, next);
      expect(_tag('tag_103'), findsOneWidget);
      expect(changes, [2]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without paging the end disables Next', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: []);
      await pumpDetail(tester, pager, changes: [], withPaging: false);
      await hoverNext(tester);
      expect(_onPressed(tester, _button(t.frost.next)), isNull);
      expect(_tag('tag_102'), findsOneWidget);
    });
  });

  group('stacked post detail', () {
    setUp(() {
      _sizes.clear();
      _parents.clear();
    });
    Future<void> pumpStacked(
      WidgetTester tester, {
      required List<int> changes,
      Size size = const Size(390, 844),
      int count = 2,
      int initialIndex = 0,
      String extension = 'png',
      List<Override> overrides = const [],
      bool flight = false,
      PostPaging? paging,
      FrostMediaHeroTag? heroTag,
      ImageProvider? openingPreview,
    }) {
      final posts = [
        for (var i = 1; i <= count; i++)
          Post(_data('$i', extension: extension)),
      ];
      Widget page = PostDetailPage(
        args: PostDetailRouteArgs(
          post: posts[initialIndex],
          collection: posts,
          initialIndex: initialIndex,
          preview: openingPreview ?? preview,
          heroTag: heroTag,
          paging: paging,
          onIndexChanged: changes.add,
        ),
      );
      if (flight) {
        page = DownloadFlightHost(
          child: Stack(
            fit: StackFit.expand,
            children: [
              page,
              const Align(
                alignment: Alignment.bottomRight,
                child: DownloadFlightTarget(
                  child: SizedBox.square(dimension: 40),
                ),
              ),
            ],
          ),
        );
      }
      return pumpPage(
        tester,
        page,
        size: size,
        platform: TargetPlatform.android,
        overrides: overrides,
      );
    }

    Finder stageOf(String id) =>
        find.byKey(ValueKey(('detail-stage', 'yande:$id')));
    final pages = find.byKey(const ValueKey('post-detail-pages'));

    /// The height of the stage area, which the information sits under.
    double area(WidgetTester tester) => tester.getSize(pages).height;

    /// How far the stages have moved, in pages.
    double travelled(WidgetTester tester, double start) =>
        (start - tester.getRect(stageOf('1')).left) / 390;

    testWidgets('a sideways drag pages only the stage; the information '
        'follows once it settles', (tester) async {
      final changes = <int>[];
      await pumpStacked(tester, changes: changes);
      final start = tester.getRect(stageOf('1')).left;
      final info = tester.getTopLeft(_tag('tag_1').first);
      final drag = await tester.startGesture(const Offset(300, 200));
      await drag.moveBy(const Offset(-20, 0));
      await tester.pump();
      await drag.moveBy(const Offset(-100, 0));
      await tester.pump();
      final moved = start - tester.getRect(stageOf('1')).left;
      expect(moved, greaterThan(90));
      expect(moved, lessThan(121));
      expect(
        tester.getTopLeft(_tag('tag_1').first),
        info,
        reason: 'the information stays put under a moving stage',
      );
      expect(stageOf('2'), findsOneWidget, reason: 'the next page shows');
      expect(changes, isEmpty, reason: 'nothing switched yet');
      // Past the middle of the page, the post is still the old one.
      await drag.moveBy(const Offset(-150, 0));
      await tester.pump();
      expect(start - tester.getRect(stageOf('1')).left, greaterThan(195));
      expect(changes, isEmpty, reason: 'not at the midpoint');
      expect(_tag('tag_1'), findsWidgets);
      expect(_tag('tag_2'), findsNothing);
      await drag.up();
      await _settle(tester);
      expect(changes, [1], reason: 'once, when the page has settled');
      expect(_tag('tag_2'), findsOneWidget);
      expect(_tag('tag_1'), findsNothing, reason: 'a neighbour has none');
      expect(tester.getRect(stageOf('2')).left, start);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a drag that returns to the page changes nothing', (
      tester,
    ) async {
      final changes = <int>[];
      await pumpStacked(tester, changes: changes);
      final drag = await tester.startGesture(const Offset(300, 200));
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-80, 0));
      await tester.pump();
      await drag.up();
      await _settle(tester);
      expect(changes, isEmpty);
      expect(_tag('tag_1'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the information switches with a fade, not a cut', (
      tester,
    ) async {
      await pumpStacked(tester, changes: []);
      Finder fade(String id) => find.byWidgetPredicate(
        (w) => w is FrostLayoutCrossfade && w.layoutIdentity == 'yande:$id',
      );
      expect(fade('1'), findsOneWidget);
      final drag = await tester.startGesture(const Offset(300, 200));
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-250, 0));
      await tester.pump();
      expect(fade('1'), findsOneWidget, reason: 'still the first post');
      await drag.up();
      await _settle(tester);
      expect(fade('2'), findsOneWidget);
      expect(fade('1'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an upward drag scrolls the stage with the information', (
      tester,
    ) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 400));
      final stage = tester.getTopLeft(stageOf('1')).dy;
      final tag = tester.getTopLeft(_tag('tag_1').first).dy;
      await tester.drag(stageOf('1'), const Offset(0, -80));
      await tester.pump();
      expect(
        stage - tester.getTopLeft(stageOf('1')).dy,
        closeTo(tag - tester.getTopLeft(_tag('tag_1').first).dy, .01),
      );
      expect(stage, greaterThan(tester.getTopLeft(stageOf('1')).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the scroll position stays when the information switches', (
      tester,
    ) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 600));
      await tester.drag(stageOf('1'), const Offset(0, -60));
      await tester.pump();
      final scrolled = tester.getTopLeft(stageOf('1')).dy;
      expect(scrolled, lessThan(0));
      final drag = await tester.startGesture(const Offset(300, 100));
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-250, 0));
      await drag.up();
      await _settle(tester);
      expect(_tag('tag_2'), findsOneWidget);
      expect(tester.getTopLeft(stageOf('2')).dy, scrolled);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the stage area follows the images between a landscape and '
        'a portrait neighbour', (tester) async {
      _sizes['1'] = (2000, 1000);
      _sizes['2'] = (1000, 2000);
      await pumpStacked(tester, changes: []);
      final start = tester.getRect(stageOf('1')).left;
      final landscape = area(tester);
      final gap = tester.getTopLeft(_tag('tag_1').first).dy - landscape;
      final drag = await tester.startGesture(const Offset(300, 100));
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-100, 0));
      await tester.pump();
      final fraction = travelled(tester, start);
      expect(fraction, inExclusiveRange(.2, .4));
      final middle = area(tester);
      expect(
        tester.getTopLeft(_tag('tag_1').first).dy - middle,
        closeTo(gap, .5),
        reason: 'the information keeps its place under the stage',
      );
      await drag.moveBy(const Offset(-150, 0));
      await drag.up();
      await _settle(tester);
      final portrait = area(tester);
      expect(portrait, greaterThan(landscape + 100));
      expect(middle, greaterThan(landscape));
      expect(middle, lessThan(portrait));
      expect(
        middle,
        closeTo(landscape + (portrait - landscape) * fraction, 1.5),
        reason: 'a blend by the fraction of the page',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a ratio that becomes known later moves the stage area '
        'smoothly', (tester) async {
      // A portrait video whose player turns out to be landscape.
      _sizes['1'] = (1000, 2000);
      _detailExtension = 'mp4';
      await pumpStacked(tester, changes: [], extension: 'mp4');
      final portrait = area(tester);
      expect(portrait, greaterThan(500));
      final gap = tester.getTopLeft(_tag('tag_1').first).dy - portrait;
      await tester.tap(_button(t.frost.play).hitTestable().first);
      final areas = <double>[];
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        areas.add(area(tester));
        expect(
          tester.getTopLeft(_tag('tag_1').first).dy - areas.last,
          closeTo(gap, .5),
          reason: 'the information follows the area at frame $frame',
        );
      }
      expect(areas.last, closeTo(195, 1), reason: 'the player is 2:1');
      expect(
        areas.where((height) => height > 205 && height < portrait - 10),
        hasLength(greaterThanOrEqualTo(4)),
        reason: 'it passes through heights in between: $areas',
      );
      for (var i = 1; i < areas.length; i++) {
        final step = areas[i - 1] - areas[i];
        expect(step, greaterThanOrEqualTo(-1e-6), reason: 'frame $i: $areas');
        expect(
          step,
          lessThan((portrait - 195) * .6),
          reason: 'no frame takes most of the change at once: $areas',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the stage area never jumps while paging between shapes', (
      tester,
    ) async {
      _sizes['1'] = (2000, 1000);
      _sizes['2'] = (1000, 2000);
      await pumpStacked(tester, changes: []);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      var last = area(tester);
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = area(tester);
        expect(
          now - last,
          lessThan(60),
          reason: 'frame $frame went from $last to $now',
        );
        expect(now, greaterThanOrEqualTo(last - 1e-6), reason: 'frame $frame');
        last = now;
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long image stops at three quarters of the page', (
      tester,
    ) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 400));
      final frame = find
          .descendant(of: stageOf('1'), matching: find.byType(FrostMediaFrame))
          .first;
      expect(tester.getSize(frame).height, lessThanOrEqualTo(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('past the stage the header turns from media to glass', (
      tester,
    ) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 500));
      expect(find.byType(FrostPinnedChromeGlass), findsNothing);
      await tester.drag(stageOf('1'), const Offset(0, -340));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FrostPinnedChromeGlass), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the header follows the scroll in the frame that moves it', (
      tester,
    ) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 500));
      final glass = find.byType(FrostPinnedChromeGlass);
      expect(glass, findsNothing);
      await tester.dragFrom(const Offset(200, 300), const Offset(0, -340));
      await tester.pump();
      expect(glass, findsOneWidget, reason: 'no later frame is needed');
      await tester.dragFrom(const Offset(200, 300), const Offset(0, 340));
      await tester.pump();
      expect(glass, findsNothing, reason: 'and back over the media');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the header turns to glass at the stage height of the page '
        'shown', (tester) async {
      _sizes['1'] = (2000, 1000);
      _sizes['2'] = (1000, 2000);
      await pumpStacked(tester, changes: [], size: const Size(390, 500));
      // The landscape stage is 195 high: 200 of scroll leaves it behind the
      // header.
      await tester.dragFrom(const Offset(200, 150), const Offset(0, -200));
      await tester.pump();
      expect(find.byType(FrostPinnedChromeGlass), findsOneWidget);
      await tester.dragFrom(const Offset(200, 150), const Offset(0, 200));
      await tester.pump();
      final drag = await tester.startGesture(const Offset(300, 100));
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-250, 0));
      await drag.up();
      await _settle(tester);
      // The portrait stage is much higher: the same scroll is still on media.
      await tester.dragFrom(const Offset(200, 150), const Offset(0, -200));
      await tester.pump();
      expect(find.byType(FrostPinnedChromeGlass), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the system-bar protection eases off past the stage rather '
        'than being removed', (tester) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 500));
      final chrome = find.byType(FrostMediaSystemChrome);
      final state = tester.state(chrome);
      expect(tester.widget<FrostMediaSystemChrome>(chrome).active, isTrue);
      await tester.drag(stageOf('1'), const Offset(0, -340));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<FrostMediaSystemChrome>(chrome).active, isFalse);
      expect(tester.state(chrome), same(state));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a stacked stage has square corners', (tester) async {
      await pumpStacked(tester, changes: [], size: const Size(390, 500));
      final frame = tester.widget<FrostMediaFrame>(
        find
            .descendant(
              of: stageOf('1'),
              matching: find.byType(FrostMediaFrame),
            )
            .first,
      );
      expect(frame.radius, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the index and the ambient artwork change once, on the '
        'settle', (tester) async {
      final ambient = _RecordingAmbient();
      final changes = <int>[];
      await pumpStacked(
        tester,
        changes: changes,
        overrides: [ambientArtworkProvider.overrideWith(() => ambient)],
      );
      expect(ambient.selected, ['yande:1']);
      final drag = await tester.startGesture(const Offset(300, 200));
      await drag.moveBy(const Offset(-20, 0));
      for (var step = 0; step < 4; step++) {
        await drag.moveBy(const Offset(-60, 0));
        await tester.pump();
      }
      expect(changes, isEmpty, reason: 'past the middle, still moving');
      expect(ambient.selected, ['yande:1']);
      await drag.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(changes, isEmpty, reason: 'not while the page is still moving');
      await _settle(tester);
      expect(changes, [1]);
      expect(ambient.selected, ['yande:1', 'yande:2']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the arrow keys page, a second press goes on from the first', (
      tester,
    ) async {
      final changes = <int>[];
      await pumpStacked(tester, changes: changes, count: 4);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 60));
      expect(changes, isEmpty, reason: 'not until the page has settled');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
      expect(changes, [2], reason: 'one settle, on the page two presses reach');
      expect(_tag('tag_3'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await _settle(tester);
      expect(changes, [2, 1]);
      expect(_tag('tag_2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the keys stop at the ends', (tester) async {
      final changes = <int>[];
      await pumpStacked(tester, changes: changes);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await _settle(tester);
      expect(changes, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
      expect(changes, [1]);
      expect(tester.takeException(), isNull);
    });

    group('neighbours', () {
      testWidgets('the next stage is built ahead of its slide, without its '
          'information', (tester) async {
        await pumpStacked(tester, changes: [], count: 4);
        Finder built(String id) => find.byKey(
          ValueKey(('detail-stage', 'yande:$id')),
          skipOffstage: false,
        );
        expect(built('2'), findsOneWidget);
        expect(
          tester.getRect(built('2')).left,
          greaterThanOrEqualTo(390),
          reason: 'beside the page, not on it',
        );
        expect(built('3'), findsNothing, reason: 'only the adjacent one');
        expect(_tag('tag_2'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the stage is not rebuilt for every frame of a change of '
          'height', (tester) async {
        _sizes['1'] = (2000, 1000);
        _sizes['2'] = (1000, 2000);
        await pumpStacked(tester, changes: []);
        final previous = debugOnRebuildDirtyWidget;
        var rebuilds = 0;
        debugOnRebuildDirtyWidget = (element, builtOnce) {
          if (element.widget is PostMedia) rebuilds++;
        };
        addTearDown(() => debugOnRebuildDirtyWidget = previous);
        final heights = <double>{};
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        for (var frame = 0; frame < 12; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          heights.add(area(tester));
        }
        expect(heights.length, greaterThan(6), reason: 'the height moved');
        expect(rebuilds, lessThan(4), reason: 'not once for each frame');
        debugOnRebuildDirtyWidget = previous;
        await _settle(tester);
        expect(tester.takeException(), isNull);
      });
    });

    group('one ratio for the stage and its area', () {
      testWidgets('a preview that arrives after the first layout moves the '
          'stage and the area together', (tester) async {
        final deferred = _DeferredImage();
        await pumpStacked(tester, changes: [], openingPreview: deferred);
        final metadata = area(tester);
        expect(metadata, closeTo(390 / (4096 / 2894), 1));
        double stage() => tester
            .getSize(
              find
                  .descendant(
                    of: stageOf('1'),
                    matching: find.byType(AspectRatio),
                  )
                  .first,
            )
            .height;
        expect(stage(), closeTo(metadata, 1));
        final image = await tester.runAsync(
          () => decodeImageFromList(base64Decode(_png)),
        );
        deferred.completer.complete(image);
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            (area(tester) - stage()).abs(),
            lessThan(40),
            reason: 'frame $frame: the stage fills its area',
          );
        }
        expect(stage(), closeTo(390, 1), reason: 'the preview is square');
        expect(area(tester), closeTo(390, 1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('a preview that is decoded at the first layout is used by '
          'it', (tester) async {
        _sizes['1'] = (2000, 1000);
        await seed(tester, preview);
        await pumpStacked(tester, changes: []);
        expect(
          area(tester),
          closeTo(390, 1),
          reason: 'the square preview, not the 2:1 metadata',
        );
        expect(tester.takeException(), isNull);
      });
    });

    group('paging calls', () {
      testWidgets('with reduced motion a key jumps and the post follows at '
          'once', (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final changes = <int>[];
        await pumpStacked(tester, changes: changes, count: 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(changes, [1]);
        expect(_tag('tag_2'), findsOneWidget);
        expect(tester.getRect(stageOf('2')).left, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(changes, [1, 2]);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(changes, [1, 2, 1]);
        expect(_tag('tag_2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a page animation interrupted by a drag settles on one '
          'post and keys go on from it', (tester) async {
        final changes = <int>[];
        await pumpStacked(tester, changes: changes, count: 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump(const Duration(milliseconds: 80));
        final drag = await tester.startGesture(const Offset(300, 100));
        await drag.moveBy(const Offset(40, 0));
        await tester.pump();
        await drag.moveBy(const Offset(80, 0));
        await tester.pump();
        await drag.up();
        await _settle(tester);
        final settled = changes.isEmpty ? 0 : changes.last;
        expect(changes.length, lessThanOrEqualTo(1));
        expect(_tag('tag_${settled + 1}'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await _settle(tester);
        expect(changes.last, settled + 1);
        expect(_tag('tag_${settled + 2}'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('stacked, wide and stacked again keep the same post', (
        tester,
      ) async {
        final changes = <int>[];
        await pumpStacked(tester, changes: changes, count: 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await _settle(tester);
        expect(changes, [1]);
        tester.view.physicalSize = const Size(1147, 717);
        await _settle(tester);
        expect(_tag('tag_2'), findsOneWidget);
        expect(find.byKey(const ValueKey('post-detail-pages')), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await _settle(tester);
        expect(changes, [1, 2]);
        expect(_tag('tag_3'), findsOneWidget);
        tester.view.physicalSize = const Size(390, 844);
        await _settle(tester);
        expect(_tag('tag_3'), findsOneWidget);
        expect(tester.getRect(stageOf('3')).left, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await _settle(tester);
        expect(changes, [1, 2, 1]);
        expect(_tag('tag_2'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a related member stays through a settle on the same '
          'page, and leaves with the page', (tester) async {
        _parents['9'] = '1';
        final changes = <int>[];
        await pumpStacked(
          tester,
          changes: changes,
          overrides: [
            getSimilarProvider(
              sourceId: 'yande',
              id: '1',
            ).overrideWith((_) async => [Post(_data('1')), Post(_data('9'))]),
          ],
        );
        final strip = find.byType(FrostThumbnailStrip);
        expect(strip, findsOneWidget);
        // The strip's item takes the tap over its picture.
        await tester.tapAt(
          tester.getCenter(
            find.descendant(of: strip, matching: find.byType(PostMedia)).at(1),
          ),
        );
        await _settle(tester);
        expect(_tag('tag_9'), findsOneWidget);
        expect(stageOf('9'), findsOneWidget);
        // Part of a page and back: the same page, the member stays.
        final drag = await tester.startGesture(const Offset(300, 100));
        await drag.moveBy(const Offset(-20, 0));
        await drag.moveBy(const Offset(-60, 0));
        await tester.pump();
        await drag.moveBy(const Offset(60, 0));
        await drag.up();
        await _settle(tester);
        expect(changes, isEmpty);
        expect(_tag('tag_9'), findsOneWidget);
        expect(stageOf('9'), findsOneWidget);
        // The strip keeps the arrow keys for itself; a swipe pages.
        Future<void> swipe(double dx) async {
          final drag = await tester.startGesture(const Offset(300, 100));
          await drag.moveBy(Offset(dx.sign * 20, 0));
          await drag.moveBy(Offset(dx - dx.sign * 20, 0));
          await drag.up();
          await _settle(tester);
        }

        await swipe(-300);
        expect(changes, [1]);
        expect(_tag('tag_2'), findsOneWidget);
        await swipe(300);
        expect(changes, [1, 0]);
        expect(_tag('tag_1'), findsWidgets);
        expect(_tag('tag_9'), findsNothing, reason: 'the page shows its own');
        expect(tester.takeException(), isNull);
      });

      testWidgets('a collection that grows while a drag is held keeps '
          'paging', (tester) async {
        final gate = Completer<void>();
        final loaded = [Post(_data('1')), Post(_data('2'))];
        final remaining = ['3'];
        final changes = <int>[];
        await pumpStacked(
          tester,
          changes: changes,
          initialIndex: 1,
          paging: PostPaging(
            hasMore: () => remaining.isNotEmpty,
            loadMore: () async {
              await gate.future;
              loaded.add(Post(_data(remaining.removeAt(0))));
              return List.of(loaded);
            },
          ),
        );
        expect(_tag('tag_2'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        final drag = await tester.startGesture(const Offset(300, 100));
        await drag.moveBy(const Offset(20, 0));
        await drag.moveBy(const Offset(60, 0));
        await tester.pump();
        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await drag.up();
        await _settle(tester);
        expect(tester.takeException(), isNull);
        // The third post exists now and can be reached from wherever it is.
        final here = changes.isEmpty ? 1 : changes.last;
        for (var i = here; i < 2; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await _settle(tester);
        }
        expect(changes.last, 2);
        expect(_tag('tag_3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('video and Hero', () {
      testWidgets('only the page that is shown plays', (tester) async {
        _detailExtension = 'mp4';
        await pumpStacked(tester, changes: [], extension: 'mp4');
        await tester.tap(_button(t.frost.play).hitTestable().first);
        await _settle(tester);
        expect(find.byType(FrostVideoFrame), findsOneWidget);
        final drag = await tester.startGesture(const Offset(300, 100));
        await drag.moveBy(const Offset(-20, 0));
        await drag.moveBy(const Offset(-120, 0));
        await tester.pump();
        expect(
          find.byType(FrostVideoFrame),
          findsOneWidget,
          reason: 'still the first post until the page settles',
        );
        await drag.moveBy(const Offset(-150, 0));
        await drag.up();
        await _settle(tester);
        expect(find.byType(FrostVideoFrame), findsNothing);
        // Back on the first post it shows its poster and waits to be played.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await _settle(tester);
        expect(find.byType(FrostVideoFrame), findsNothing);
        await tester.tap(_button(t.frost.play).hitTestable().first);
        await _settle(tester);
        expect(find.byType(FrostVideoFrame), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the Hero belongs to the opening post alone', (tester) async {
        final changes = <int>[];
        await pumpStacked(
          tester,
          changes: changes,
          heroTag: FrostMediaHeroTag(image: preview, aspectRatio: 4096 / 2894),
        );
        Finder hero(String id) => find.descendant(
          of: stageOf(id),
          matching: find.byType(FrostMediaHero),
        );
        expect(hero('1'), findsOneWidget);
        expect(hero('2'), findsNothing, reason: 'a neighbour is only passing');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await _settle(tester);
        expect(changes, [1]);
        expect(find.byType(FrostMediaHero), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await _settle(tester);
        expect(hero('1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('the download flight', () {
      final flying = find.byWidgetPredicate(
        (w) => w is Image && w.excludeFromSemantics && w.fit == BoxFit.cover,
        description: 'the flying image',
      );

      testWidgets('starts from the stage on screen', (tester) async {
        final downloads = _RecordingDownloads();
        await pumpStacked(
          tester,
          changes: [],
          flight: true,
          overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
        );
        final stage = tester.getRect(pages);
        await tester.tap(_button(t.postDetail.download).hitTestable().first);
        await tester.pump();
        expect(downloads.added.single.postKey, 'yande:1');
        expect(downloads.flew, isTrue);
        expect(tester.getRect(flying), stage);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });

      testWidgets('starts from where the stage is when it is scrolled', (
        tester,
      ) async {
        final downloads = _RecordingDownloads();
        await pumpStacked(
          tester,
          changes: [],
          flight: true,
          size: const Size(390, 600),
          overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
        );
        await tester.drag(stageOf('1'), const Offset(0, -60));
        await tester.pump();
        final stage = tester.getRect(pages);
        expect(stage.top, lessThan(0));
        await tester.tap(_button(t.postDetail.download).hitTestable().first);
        await tester.pump();
        expect(downloads.flew, isTrue);
        expect(tester.getRect(flying), stage);
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets('takes the post the page has switched to', (tester) async {
        final downloads = _RecordingDownloads();
        await pumpStacked(
          tester,
          changes: [],
          flight: true,
          overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await _settle(tester);
        await tester.tap(_button(t.postDetail.download).hitTestable().first);
        await tester.pump();
        expect(downloads.added.single.postKey, 'yande:2');
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets('starts from the stage beside the information when wide', (
        tester,
      ) async {
        final downloads = _RecordingDownloads();
        final changes = <int>[];
        final posts = [Post(_data('1')), Post(_data('2'))];
        await pumpPage(
          tester,
          DownloadFlightHost(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PostDetailPage(
                  args: PostDetailRouteArgs(
                    post: posts.first,
                    collection: posts,
                    preview: preview,
                    onIndexChanged: changes.add,
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: DownloadFlightTarget(
                    child: SizedBox.square(dimension: 40),
                  ),
                ),
              ],
            ),
          ),
          overrides: [booruDownloadsProvider.overrideWithValue(downloads)],
        );
        final information = tester.getRect(
          find.descendant(
            of: find.byType(PostDetailPage),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axis == Axis.vertical,
            ),
          ),
        );
        await tester.tap(_button(t.postDetail.download).hitTestable().first);
        await tester.pump();
        expect(downloads.flew, isTrue);
        final source = tester.getRect(flying);
        expect(source.left, 0);
        expect(source.top, 0);
        expect(source.right, closeTo(information.left, .5));
        expect(source.bottom, tester.view.physicalSize.height);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('image viewer', () {
    Future<void> pumpViewer(
      WidgetTester tester,
      _Pager pager, {
      required List<int> changes,
      bool withPaging = true,
    }) => pumpPage(
      tester,
      ImageZoomPage(
        args: ImageViewerRouteArgs(
          collection: List.of(pager.loaded),
          initialIndex: pager.loaded.length - 1,
          preview: preview,
          onIndexChanged: changes.add,
          paging: withPaging ? pager.paging : null,
        ),
      ),
    );

    Finder title(String id) => find.byWidgetPredicate(
      (w) => w is ViewerStage && w.post.id == id,
      description: 'viewer showing $id',
    );

    testWidgets('Next is enabled at the loaded end while more exists and '
        'pressing it lands on the next post', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103']);
      final changes = <int>[];
      await pumpViewer(tester, pager, changes: changes);
      expect(_onPressed(tester, _button(t.frost.next)), isNotNull);
      await tester.tap(_button(t.frost.next).hitTestable().first);
      await _settle(tester);
      expect(pager.calls, greaterThanOrEqualTo(1));
      expect(changes, [2]);
      expect(title('103'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Next disables once nothing more can load', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103']);
      await pumpViewer(tester, pager, changes: []);
      await tester.tap(_button(t.frost.next).hitTestable().first);
      await _settle(tester);
      expect(pager.hasMore, isFalse);
      expect(_onPressed(tester, _button(t.frost.next)), isNull);
    });

    testWidgets('a failing load keeps the current post and a retry works', (
      tester,
    ) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103'])
        ..failures = 1;
      final changes = <int>[];
      await pumpViewer(tester, pager, changes: changes);
      await tester.tap(_button(t.frost.next).hitTestable().first);
      await _settle(tester);
      expect(changes, isEmpty);
      expect(title('102'), findsOneWidget);
      expect(_onPressed(tester, _button(t.frost.next)), isNotNull);
      await tester.tap(_button(t.frost.next).hitTestable().first);
      await _settle(tester);
      expect(changes, [2]);
      expect(title('103'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the arrow key also pages past the loaded end', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: ['103']);
      final changes = <int>[];
      await pumpViewer(tester, pager, changes: changes);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
      expect(changes, [2]);
    });

    testWidgets('without paging the end disables Next', (tester) async {
      final pager = _Pager(loaded: ['101', '102'], remaining: []);
      await pumpViewer(tester, pager, changes: [], withPaging: false);
      expect(_onPressed(tester, _button(t.frost.next)), isNull);
    });
  });
}
