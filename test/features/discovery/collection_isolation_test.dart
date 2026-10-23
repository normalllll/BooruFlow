import 'dart:async';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/posts/widgets/post_preview_card.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'browse_v2_test.dart' show browsePost, PendingMediaService;
import 'home_page_test.dart' show browseTestApp;

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'source switches create cold lists at zero while refresh retains the current list at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var selected = 'A', aCalls = 0;
        late StateSetter change;
        final b = Completer<PostPage>(),
            aNew = Completer<PostPage>(),
            refresh = Completer<PostPage>();
        Future<PostPage> loader(CollectionKey key, String? cursor) {
          if (key.sourceId == 'B') return b.future;
          aCalls++;
          if (aCalls == 1) {
            return Future.value(
              PostPage(items: List.generate(100, browsePost), exhausted: true),
            );
          }
          return aCalls == 2 ? aNew.future : refresh.future;
        }

        final key = GlobalKey<PostCollectionViewState>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              booruServiceProvider.overrideWithValue(PendingMediaService()),
            ],
            child: browseTestApp(
              StatefulBuilder(
                builder: (context, set) {
                  change = set;
                  return PostCollectionView(
                    key: key,
                    collection: (
                      key: CollectionKey(
                        sourceId: selected,
                        request: const FeedCollectionRequest(),
                        ratings: const [],
                        revision: 0,
                      ),
                      loader: loader,
                    ),
                    headerBuilder: (_, source) =>
                        const FrostPageHeader(title: FrostText('Browse')),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        ScrollController scroll() => tester
            .widget<FrostRefreshView>(find.byType(FrostRefreshView))
            .scrollController!;
        scroll().jumpTo(600);
        await tester.pump();
        final old = key.currentState!.source;
        change(() => selected = 'B');
        await tester.pump();
        expect(scroll().offset, 0);
        expect(find.byType(PostPreviewCard), findsNothing);
        expect(find.byType(FrostMediaCard), findsWidgets);
        b.complete(
          PostPage(
            items: List.generate(100, (i) => browsePost(1000 + i)),
            exhausted: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        scroll().jumpTo(320);
        await tester.pump();
        change(() => selected = 'A');
        await tester.pump();
        expect(scroll().offset, 0);
        expect(key.currentState!.source, isNot(same(old)));
        expect(find.byType(PostPreviewCard), findsNothing);
        await tester.pump();
        expect(aCalls, 2);
        aNew.complete(
          PostPage(
            items: List.generate(100, (i) => browsePost(2000 + i)),
            exhausted: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        final current = key.currentState!.source;
        final task = key.currentState!.refresh();
        await tester.pump();
        expect(key.currentState!.source, same(current));
        expect(find.byType(PostPreviewCard), findsWidgets);
        expect(_dimmingCardAncestors(), findsNothing);
        refresh.complete(
          PostPage(
            items: List.generate(100, (i) => browsePost(3000 + i)),
            exhausted: true,
          ),
        );
        await task;
        await tester.pump();
        expect(current.refreshRevision, 2);
        expect(_dimmingCardAncestors(), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
    );
  }
  for (final request in [
    const FeedCollectionRequest(),
    TagSearchCollectionRequest(['sky']),
  ]) {
    testWidgets(
      'feed and tag results use shared first-load skeleton for $request',
      (tester) async {
        final pending = Completer<PostPage>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              booruServiceProvider.overrideWithValue(PendingMediaService()),
            ],
            child: browseTestApp(
              PostCollectionView(
                collection: (
                  key: CollectionKey(
                    sourceId: 'A',
                    request: request,
                    ratings: const [],
                    revision: 0,
                  ),
                  loader: (_, _) => pending.future,
                ),
                headerBuilder: (_, source) =>
                    const FrostPageHeader(title: FrostText('Browse')),
              ),
            ),
          ),
        );
        expect(find.byType(PostPreviewCard), findsNothing);
        expect(find.byType(FrostMediaCard), findsWidgets);
        await tester.pumpWidget(const SizedBox());
        pending.complete(const PostPage(items: [], exhausted: true));
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'leaving a page releases its list and opening it again fetches anew',
    (tester) async {
      var calls = 0;
      Future<PostPage> loader(CollectionKey _, String? cursor) async {
        calls++;
        return PostPage(items: [browsePost(1)], exhausted: true);
      }

      final identity = (
        key: CollectionKey(
          sourceId: 'A',
          request: const FeedCollectionRequest(),
          ratings: const [],
          revision: 0,
        ),
        loader: loader,
      );
      Widget page() => ProviderScope(
        overrides: [
          booruServiceProvider.overrideWithValue(PendingMediaService()),
        ],
        child: browseTestApp(
          PostCollectionView(
            collection: identity,
            headerBuilder: (_, source) =>
                const FrostPageHeader(title: FrostText('Browse')),
          ),
        ),
      );
      await tester.pumpWidget(page());
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(page());
      await tester.pump();
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _dimmingCardAncestors() => find.ancestor(
  of: find.byType(PostPreviewCard).first,
  matching: find.byWidgetPredicate(
    (widget) => switch (widget) {
      SliverOpacity(:final opacity) || Opacity(:final opacity) => opacity < 1,
      FadeTransition(:final opacity) => opacity.value < 1,
      _ => false,
    },
  ),
);
