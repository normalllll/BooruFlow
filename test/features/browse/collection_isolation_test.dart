import 'dart:async';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/widgets/browse_card.dart';
import 'package:booruflow/features/browse/widgets/post_waterfall.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../support/browse_support.dart';
import '../discovery/search_interaction_test.dart' show testSource;

PendingMediaService _service() =>
    PendingMediaService()..useSourcesForTesting([testSource('yande')]);

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

        final key = GlobalKey<PostWaterfallState>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [booruServiceProvider.overrideWithValue(_service())],
            child: browseTestApp(
              StatefulBuilder(
                builder: (context, set) {
                  change = set;
                  return PostWaterfall(
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
                    header: (_, source) =>
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
        expect(find.byType(BrowseCard), findsNothing);
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
        expect(find.byType(BrowseCard), findsNothing);
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
        expect(find.byType(BrowseCard), findsWidgets);
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
            overrides: [booruServiceProvider.overrideWithValue(_service())],
            child: browseTestApp(
              PostWaterfall(
                collection: (
                  key: CollectionKey(
                    sourceId: 'A',
                    request: request,
                    ratings: const [],
                    revision: 0,
                  ),
                  loader: (_, _) => pending.future,
                ),
                header: (_, source) =>
                    const FrostPageHeader(title: FrostText('Browse')),
              ),
            ),
          ),
        );
        expect(find.byType(BrowseCard), findsNothing);
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
        overrides: [booruServiceProvider.overrideWithValue(_service())],
        child: browseTestApp(
          PostWaterfall(
            collection: identity,
            header: (_, source) =>
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
  of: find.byType(BrowseCard).first,
  matching: find.byWidgetPredicate(
    (widget) => switch (widget) {
      SliverOpacity(:final opacity) || Opacity(:final opacity) => opacity < 1,
      FadeTransition(:final opacity) => opacity.value < 1,
      _ => false,
    },
  ),
);
