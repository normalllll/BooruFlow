// Post detail page: media, information, tags and actions.
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
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
    supportsRelatedPosts: true,
    supportsOriginal: true,
    supportsAuthenticatedMedia: false,
    supportsBackgroundDownload: true,
  ),
);

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

/// Every post carries one tag per category named after its id, so the shown
/// post can be identified by its tags alone.
BooruPost _data(String id, {bool hasChildren = false, String? parentId}) =>
    BooruPost(
      sourceId: 'yande',
      postId: id,
      postKey: 'yande:$id',
      author: 'uploader_not_artist',
      webUrl: 'https://yande.re/post/show/$id',
      sourceUrl: 'https://example.invalid/work/$id',
      rating: ContentRating.general,
      score: 128,
      createdAtIso8601: '2026-10-12T01:02:03Z',
      tags: [
        BooruTag(name: 'artist_$id', category: TagCategory.artist),
        BooruTag(name: 'char_$id', category: TagCategory.character),
        BooruTag(name: 'series_$id', category: TagCategory.copyright),
        BooruTag(name: 'tag_$id', category: TagCategory.general),
        BooruTag(name: 'meta_$id', category: TagCategory.meta),
      ],
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
      flags: PostFlags(
        parentId: parentId,
        hasChildren: hasChildren,
        isPending: false,
        isDeleted: false,
        isAiGenerated: false,
      ),
    );

class _Engine implements BooruEngine {
  /// What the source reports as related to a post (its family).
  List<BooruPost> Function(String id) related = (_) => const [];
  final posts = <String, BooruPost>{};

  @override
  Future<BooruPost> getPost({
    required String sourceId,
    required String postId,
  }) async => posts[postId] ?? _data(postId);
  @override
  Future<List<BooruPost>> relatedPosts({
    required String sourceId,
    required String postId,
  }) async => related(postId);
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

Finder _tag(String name) =>
    find.byWidgetPredicate((w) => w is FrostTag && w.label == name);

/// Controls over the media may be a FrostButton or a FrostMediaButton.
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
  Uri? resultUri;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = _Service();
    service.useSourcesForTesting([_source()]);
    BooruService.instance.useSourcesForTesting([_source()]);
    preview = MemoryImage(base64Decode(_png));
    resultUri = null;
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  PostDetailRouteArgs args(
    List<String> ids, {
    int index = 0,
    ValueChanged<int>? onIndexChanged,
    List<BooruPost>? data,
  }) {
    final posts = [for (final d in data ?? ids.map(_data)) Post(d)];
    return PostDetailRouteArgs(
      post: posts[index],
      collection: posts,
      initialIndex: index,
      preview: preview,
      onIndexChanged: onIndexChanged,
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    PostDetailRouteArgs routeArgs, {
    Size size = const Size(1147, 717),
    TargetPlatform platform = TargetPlatform.windows,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => PostDetailPage(args: routeArgs),
        ),
        GoRoute(
          path: AppRoute.results.path,
          name: AppRoute.results.name,
          builder: (_, state) {
            resultUri = state.uri;
            return const Text('results route');
          },
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
    await _settle(tester);
  }

  Finder verticalScrollables() => find.descendant(
    of: find.byType(PostDetailPage),
    matching: find.byWidgetPredicate(
      (w) => w is Scrollable && w.axis == Axis.vertical,
    ),
  );

  // 5.3 wide: the media stage is fixed, the info column is the one scroller,
  // and the content holds no back button or header row.
  testWidgets(
    'wide layout has exactly one vertical scrollable (the info column) and no back button',
    (tester) async {
      await pumpDetail(tester, args(['101', '102', '103'], index: 1));
      final scrollables = verticalScrollables().evaluate().toList();
      expect(scrollables, hasLength(1));
      final rect = tester.getRect(find.byWidget(scrollables.single.widget));
      final page = tester.getRect(find.byType(PostDetailPage));
      expect(
        rect.left,
        greaterThan(page.left + page.width * .5),
        reason: 'the scroller is the information column on the right',
      );
      final inPage = find.byType(PostDetailPage);
      expect(
        find.descendant(
          of: inPage,
          matching: find.byWidgetPredicate(
            (w) => w is FrostTooltip && w.message == t.frost.back,
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: inPage, matching: _button(t.frost.back)),
        findsNothing,
      );
      // The information column's header carries the post's title, which a
      // shell's title row shows instead; without a shell it shows it itself.
      expect(
        find.descendant(
          of: find.descendant(
            of: inPage,
            matching: find.byType(FrostPageHeader),
          ),
          matching: find.text('#102'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  // 5.3 collection paging by keyboard, with onIndexChanged and clamped ends.
  testWidgets(
    'arrow keys page through the collection, report the index and stop at both ends',
    (tester) async {
      final changes = <int>[];
      await pumpDetail(
        tester,
        args(['101', '102', '103'], index: 1, onIndexChanged: changes.add),
      );
      expect(_tag('tag_102'), findsOneWidget);

      Future<void> press(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await _settle(tester);
      }

      await press(LogicalKeyboardKey.arrowRight);
      expect(_tag('tag_103'), findsOneWidget);
      expect(_tag('tag_102'), findsNothing);
      expect(changes, [2]);

      await press(LogicalKeyboardKey.arrowRight); // last item: nothing
      expect(_tag('tag_103'), findsOneWidget);
      expect(changes, [2]);

      await press(LogicalKeyboardKey.arrowLeft);
      expect(_tag('tag_102'), findsOneWidget);
      expect(changes, [2, 1]);

      await press(LogicalKeyboardKey.arrowLeft);
      expect(_tag('tag_101'), findsOneWidget);
      expect(changes, [2, 1, 0]);

      await press(LogicalKeyboardKey.arrowLeft); // first item: nothing
      expect(_tag('tag_101'), findsOneWidget);
      expect(changes, [2, 1, 0]);
      expect(tester.takeException(), isNull);
    },
  );

  // 5.3: edge buttons for pointer hover, disabled at the ends.
  testWidgets(
    'hovering the stage edges shows paging buttons that are disabled at the ends',
    (tester) async {
      final changes = <int>[];
      await pumpDetail(
        tester,
        args(['101', '102'], onIndexChanged: changes.add),
      );
      final page = tester.getRect(find.byType(PostDetailPage));
      final stageRight = tester.getRect(verticalScrollables()).left;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(Offset(page.left + 30, page.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_button(t.frost.previous), findsOneWidget);
      expect(
        _onPressed(tester, _button(t.frost.previous)),
        isNull,
        reason: 'first item: previous is disabled',
      );

      await mouse.moveTo(Offset(stageRight - 30, page.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final next = _button(t.frost.next);
      expect(next, findsOneWidget);
      expect(_onPressed(tester, next), isNotNull);
      await mouse.down(tester.getCenter(next));
      await mouse.up();
      await _settle(tester);
      expect(changes, [1]);
      expect(_tag('tag_102'), findsOneWidget);

      await mouse.moveTo(Offset(stageRight - 30, page.center.dy + 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        _onPressed(tester, _button(t.frost.next)),
        isNull,
        reason: 'last item: next is disabled',
      );
      expect(tester.takeException(), isNull);
    },
  );

  // 5.3 "with the old page": no n/m badge, no parent/child hover arrows.
  testWidgets('the stage carries no "n/m" badge', (tester) async {
    await pumpDetail(tester, args(['101', '102', '103'], index: 1));
    final page = tester.getRect(find.byType(PostDetailPage));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(Offset(page.left + 200, page.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final counter = RegExp(r'^\s*\d+\s*/\s*\d+\s*$');
    bool isCounter(String? text) => text != null && counter.hasMatch(text);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text && isCounter(w.data ?? w.textSpan?.toPlainText()) ||
            w is FrostBadge && isCounter(w.label),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a parent/child family adds no hover arrows on the stage; the strip is the only switcher',
    (tester) async {
      // One post opened on its own (no collection paging) with two children.
      service.engine.related = (_) => [
        _data('101', hasChildren: true),
        _data('102', parentId: '101'),
        _data('103', parentId: '101'),
      ];
      service.engine.posts['101'] = _data('101', hasChildren: true);
      await pumpDetail(
        tester,
        args(['101'], data: [_data('101', hasChildren: true)]),
      );
      await _settle(tester);
      final strip = find.byType(FrostThumbnailStrip);
      expect(strip, findsOneWidget);
      expect(tester.widget<FrostThumbnailStrip>(strip).itemCount, 3);

      final page = tester.getRect(find.byType(PostDetailPage));
      final stageRight = tester.getRect(verticalScrollables()).left;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      for (final x in [page.left + 30, (page.left + stageRight) / 2]) {
        await mouse.moveTo(Offset(x, page.center.dy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is FrostButton &&
                    (w.label == t.frost.previous || w.label == t.frost.next) &&
                    w.onPressed != null ||
                w is FrostMediaButton &&
                    (w.label == t.frost.previous || w.label == t.frost.next) &&
                    w.onPressed != null,
          ),
          findsNothing,
          reason: 'no usable previous/next control for a family',
        );
      }
      final counter = RegExp(r'^\s*\d+\s*/\s*\d+\s*$');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
                  counter.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? '') ||
              w is FrostBadge && counter.hasMatch(w.label),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  // 5.3: related posts section only when the family has other members.
  testWidgets(
    'related posts are absent when the family is only the post itself',
    (tester) async {
      // A collection of three unrelated posts is not a family.
      await pumpDetail(tester, args(['101', '102', '103'], index: 1));
      expect(find.byType(FrostThumbnailStrip), findsNothing);
    },
  );

  testWidgets(
    'related posts are absent when the source reports only the post itself',
    (tester) async {
      service.engine.related = (_) => [_data('101', hasChildren: true)];
      await pumpDetail(
        tester,
        args(['101'], data: [_data('101', hasChildren: true)]),
      );
      await _settle(tester);
      expect(find.byType(FrostThumbnailStrip), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  // 5.3 tags: grouped by category, tag tap opens the results route.
  testWidgets('tags are grouped by category in the documented order', (
    tester,
  ) async {
    await pumpDetail(tester, args(['101']), size: const Size(1280, 1400));
    final groups = <(String, String)>[
      (t.discovery.artist, 'artist_101'),
      (t.discovery.character, 'char_101'),
      (t.discovery.copyright, 'series_101'),
      (t.discovery.general, 'tag_101'),
      (t.discovery.meta, 'meta_101'),
    ];
    double? previousTop;
    for (final (label, tag) in groups) {
      final tagRect = tester.getRect(_tag(tag));
      final labels = find
          .text(label)
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget)))
          .where(
            (r) =>
                r.bottom <= tagRect.top + 1 &&
                tagRect.top - r.bottom < 48 &&
                (r.left - tagRect.left).abs() < 4,
          );
      expect(
        labels,
        isNotEmpty,
        reason: 'group "$label" sits directly above its tag $tag',
      );
      if (previousTop != null) {
        expect(tagRect.top, greaterThan(previousTop));
      }
      previousTop = tagRect.top;
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a tag opens the results route for that tag', (
    tester,
  ) async {
    await pumpDetail(tester, args(['101']), size: const Size(1280, 1400));
    await tester.tap(_tag('tag_101'));
    await _settle(tester);
    expect(find.text('results route'), findsOneWidget);
    final uri = resultUri!;
    expect(uri.path, AppRoute.results.path);
    expect(uri.queryParameters['source'], 'yande');
    expect(jsonDecode(uri.queryParameters['tags']!), ['tag_101']);
    expect(tester.takeException(), isNull);
  });

  // 5.3 info: key-value rows.
  testWidgets(
    'the info section shows dimensions, size, rating and source as key-value rows',
    (tester) async {
      await pumpDetail(tester, args(['101']), size: const Size(1800, 1300));
      void expectRow(String label, String value) {
        final labels = find
            .text(label)
            .evaluate()
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        final values = find
            .textContaining(value)
            .evaluate()
            .map((e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        expect(labels, isNotEmpty, reason: 'label "$label"');
        expect(values, isNotEmpty, reason: 'value "$value"');
        expect(
          labels.any(
            (l) => values.any(
              // A long value may wrap; the label sits on its first line.
              (v) => (l.top - v.top).abs() < 8 && l.left < v.left,
            ),
          ),
          isTrue,
          reason: '"$label" and "$value" share a row, label first',
        );
      }

      expectRow(t.postDetail.dimensions, '4,096 × 2,894');
      expectRow(t.postDetail.size, 'MB');
      expectRow(t.postDetail.rating, t.postDetail.ratingGeneral);
      expectRow(t.postDetail.source, 'example.invalid/work/101');
      expect(tester.takeException(), isNull);
    },
  );
}
