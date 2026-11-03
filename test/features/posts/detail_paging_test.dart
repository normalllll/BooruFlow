// Paging in the post detail and the image viewer goes past the loaded items
// when the collection it opened from has more pages.
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/image_viewer/viewer_stage.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/video_playback.dart';
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
import 'package:go_router/go_router.dart';

import '../../support/frost_app_layers.dart';
import '../discovery/search_interaction_test.dart' show testSource;
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
  flags: const PostFlags(
    hasChildren: false,
    isPending: false,
    isDeleted: false,
    isAiGenerated: false,
  ),
);

/// Media sizes by post id; a post not listed here is landscape.
final _sizes = <String, (int, int)>{};

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
    Future<void> pumpStacked(
      WidgetTester tester, {
      required List<int> changes,
      Size size = const Size(390, 844),
    }) => pumpPage(
      tester,
      PostDetailPage(
        args: PostDetailRouteArgs(
          post: Post(_data('1')),
          collection: [Post(_data('1')), Post(_data('2'))],
          preview: preview,
          onIndexChanged: changes.add,
        ),
      ),
      size: size,
      platform: TargetPlatform.android,
    );
    Finder stageOf(String id) =>
        find.byKey(ValueKey(('detail-stage', 'yande:$id')));

    testWidgets('a sideways drag moves the whole page with the finger', (
      tester,
    ) async {
      final changes = <int>[];
      await pumpStacked(tester, changes: changes);
      final start = tester.getRect(stageOf('1')).left;
      final info = tester.getTopLeft(_tag('tag_1').first).dx;
      final drag = await tester.startGesture(const Offset(300, 200));
      await drag.moveBy(const Offset(-20, 0));
      await tester.pump();
      await drag.moveBy(const Offset(-100, 0));
      await tester.pump();
      final moved = start - tester.getRect(stageOf('1')).left;
      expect(moved, greaterThan(90));
      expect(moved, lessThan(121));
      expect(
        info - tester.getTopLeft(_tag('tag_1').first).dx,
        moved,
        reason: 'the information moves with the stage',
      );
      expect(stageOf('2'), findsOneWidget, reason: 'the next page shows');
      expect(changes, isEmpty, reason: 'nothing switched yet');
      await drag.moveBy(const Offset(-150, 0));
      await drag.up();
      await _settle(tester);
      expect(changes, [1]);
      expect(tester.getRect(stageOf('2')).left, start);
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
