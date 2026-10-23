import 'dart:convert';

import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/post_reference_page.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/media/media_stage.dart';

import '../discovery/browse_v2_test.dart' show PendingMediaService;
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart'
    show testSource, SearchRepositoryFake;
import 'post_media_handoff_test.dart' show seed;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

Post item(String id, double ratio, {String? parent, bool children = false}) =>
    Post(
      BooruPost(
        sourceId: 'yande',
        postId: id,
        postKey: 'yande:$id',
        rating: ContentRating.general,
        tags: const [BooruTag(name: 'sky', category: TagCategory.general)],
        media: [
          for (final kind in [
            MediaVariantKind.sample,
            MediaVariantKind.original,
          ])
            MediaVariant(
              kind: kind,
              url: 'https://test/$id/${kind.name}.png',
              width: (400 * ratio).round(),
              height: 400,
              mediaType: MediaType.png,
            ),
        ],
        flags: PostFlags(
          parentId: parent,
          hasChildren: children,
          isPending: false,
          isDeleted: false,
          isAiGenerated: false,
        ),
      ),
    );
void main() {
  late PendingMediaService service;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    service = PendingMediaService()
      ..useSourcesForTesting([testSource('yande')]);
  });
  Widget host(List<Post> posts, {int index = 0, List<Post>? relatives}) =>
      ProviderScope(
        overrides: [
          booruServiceProvider.overrideWithValue(service),
          tagSuggestionRepositoryProvider.overrideWithValue(
            SearchRepositoryFake(),
          ),
          for (final post in posts)
            postAttributionDetailProvider((
              sourceId: post.sourceId,
              postId: post.id,
            )).overrideWith((_) async => post),
          getSimilarProvider(
            sourceId: 'yande',
            id: '100',
          ).overrideWith((_) async => relatives ?? posts),
        ],
        child: browseTestApp(
          PostDetailPage(
            args: PostDetailRouteArgs(
              post: posts[index],
              collection: posts,
              initialIndex: index,
            ),
          ),
        ),
      );
  Future<void> setup(
    WidgetTester tester,
    List<Post> posts, {
    int index = 0,
    List<Post>? relatives,
  }) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(posts, index: index, relatives: relatives));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'ready preview paints immediately and media preparation has no route-status wait',
    (tester) async {
      final posts = [item('100', .5, children: true)];
      final preview = MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      await seed(tester, preview);
      late BuildContext root;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            tagSuggestionRepositoryProvider.overrideWithValue(
              SearchRepositoryFake(),
            ),
            postAttributionDetailProvider((
              sourceId: 'yande',
              postId: '100',
            )).overrideWith((_) async => posts.single),
            getSimilarProvider(
              sourceId: 'yande',
              id: '100',
            ).overrideWith((_) async => posts),
          ],
          child: browseTestApp(
            Builder(
              builder: (context) {
                root = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      Navigator.of(root).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, _, _) => PostDetailPage(
            args: PostDetailRouteArgs(
              post: posts.single,
              collection: posts,
              initialIndex: 0,
              preview: preview,
            ),
          ),
          transitionsBuilder: (_, _, _, child) => child,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(RawImage), findsWidgets);
      final route = ModalRoute.of(tester.element(find.byType(PostDetailPage)))!;
      expect(
        route.animation!.status,
        AnimationStatus.forward,
        reason: 'entry animation value ${route.animation!.value}',
      );
      expect(service.mediaEngine.pending, isNotEmpty);
      // Secondary information is introduced by the shared per-frame queue;
      // ready main media and request start above remain immediate.
      for (
        var frame = 0;
        frame < 8 && find.byType(FrostThumbnailStrip).evaluate().isEmpty;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 8));
      }
      expect(route.animation!.status, AnimationStatus.forward);
      expect(find.byType(FrostThumbnailStrip), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();
      expect(service.mediaEngine.pending, isNotEmpty);
      expect(find.byType(FrostThumbnailStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'missing reference uses the shared page safe areas with a 48-point header',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [booruServiceProvider.overrideWithValue(service)],
          child: browseTestApp(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.fromLTRB(19, 47, 31, 24),
                  viewPadding: const EdgeInsets.fromLTRB(19, 47, 31, 24),
                ),
                child: const PostReferencePage(
                  sourceId: null,
                  postId: 'missing',
                ),
              ),
            ),
            platform: TargetPlatform.android,
          ),
        ),
      );
      await tester.pump();
      final header = tester.getRect(find.byType(FrostPageHeader));
      expect(header.top, 47);
      expect(header.height, 48);
      final body = tester.getRect(find.byType(FrostEmptyState));
      expect(body.top, greaterThanOrEqualTo(95));
      expect(body.left, greaterThanOrEqualTo(19));
      expect(body.right, lessThanOrEqualTo(359));
      expect(body.bottom, lessThanOrEqualTo(820));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('new work never inherits the preceding stage spring ratio', (
    tester,
  ) async {
    final posts = [item('101', .5), item('102', 2)];
    await setup(tester, posts);
    double ratio() => tester
        .widget<FrostMediaStageGeometry>(
          find.descendant(
            of: find.byKey(ValueKey(('detail-stage', posts[1].postKey))),
            matching: find.byType(FrostMediaStageGeometry),
          ),
        )
        .aspectRatio;
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is FrostButton && w.label == t.frost.next)
          .hitTestable()
          .first,
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      expect(
        ratio(),
        closeTo(2, 1e-6),
        reason: 'frame $i must use the new work geometry',
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'family order is parent then stable children; selecting changes only highlight',
    (tester) async {
      final posts = [
        item('100', 1, children: true),
        item('101', .5, parent: '100'),
        item('102', 2, parent: '100'),
      ];
      await setup(tester, posts, index: 1);
      FrostThumbnailStrip strip() =>
          tester.widget<FrostThumbnailStrip>(find.byType(FrostThumbnailStrip));
      List<PostMedia> thumbnails() => tester
          .widgetList<PostMedia>(
            find.descendant(
              of: find.byType(FrostThumbnailStrip),
              matching: find.byType(PostMedia),
            ),
          )
          .toList();
      List<String> keys() => [
        for (final media in thumbnails()) media.post.postKey,
      ];
      expect(
        [for (final media in thumbnails()) media.decodeWidth],
        [64, 64, 128],
        reason:
            'each cover thumbnail uses its own 64-square layout and aspect ratio, regardless of selection',
      );
      expect(keys(), ['yande:100', 'yande:101', 'yande:102']);
      strip().onSelected!(2);
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(keys(), ['yande:100', 'yande:101', 'yande:102']);
      expect(strip().selectedIndex, 2);
      strip().onSelected!(0);
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(keys(), ['yande:100', 'yande:101', 'yande:102']);
      expect(strip().selectedIndex, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'family selection preserves the page and strip without extending the grid sequence',
    (tester) async {
      final root = item('100', 1, children: true),
          a = item('101', 1, parent: '100'),
          b = item('102', 1, parent: '100'),
          other = item('200', 1);
      await setup(tester, [root, other], relatives: [root, a, b]);
      final page = tester.state(find.byType(PostDetailPage));
      final stripState = tester.state(find.byType(FrostThumbnailStrip));
      final scroll = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(FrostDetailLayout),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      final offset = scroll.pixels;
      tester
          .widget<FrostThumbnailStrip>(find.byType(FrostThumbnailStrip))
          .onSelected!(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey(('detail-stage', 'yande:102'))),
        findsOneWidget,
      );
      expect(tester.state(find.byType(PostDetailPage)), same(page));
      expect(tester.state(find.byType(FrostThumbnailStrip)), same(stripState));
      expect(scroll.pixels, offset);
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.frost.next,
            )
            .hitTestable()
            .first,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey(('detail-stage', 'yande:200'))),
        findsOneWidget,
        reason:
            'header Next advances to the next grid item, never to an appended family member',
      );
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.frost.previous,
            )
            .hitTestable()
            .first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<FrostThumbnailStrip>(find.byType(FrostThumbnailStrip))
            .itemCount,
        3,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
