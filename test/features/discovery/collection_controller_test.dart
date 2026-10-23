import 'dart:async';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'browse_v2_test.dart' show browsePost;

CollectionKey key({
  PostCollectionRequest? request,
  int revision = 0,
  List<ContentRating> ratings = const [ContentRating.general],
}) => CollectionKey(
  sourceId: 'yande',
  request: request ?? const FeedCollectionRequest(),
  ratings: ratings,
  revision: revision,
);
PostPage page({String? next, bool exhausted = false}) =>
    PostPage(items: const [], nextCursor: next, exhausted: exhausted);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'collection descriptors distinguish query, ratings and revision by value',
    () {
      expect(
        key(request: TagSearchCollectionRequest([' sky ', 'blue'])),
        key(request: TagSearchCollectionRequest(['sky', 'blue'])),
      );
      expect(key(request: TagSearchCollectionRequest(['sky'])), isNot(key()));
      expect(key(revision: 1), isNot(key()));
      expect(key(ratings: [ContentRating.explicit]), isNot(key()));
      expect(
        key(request: TagSearchCollectionRequest(['sky', '-blue'])),
        isNot(key(request: TagSearchCollectionRequest(['sky', 'blue']))),
      );
    },
  );
  test(
    'all-filtered pages continue beyond three pages until an actual result or end',
    () async {
      final cursors = <String?>[];
      final source = PostListSource(
        key(),
        loader: (_, cursor) async {
          cursors.add(cursor);
          return cursors.length < 5
              ? PostPage(
                  items: [
                    browsePost(cursors.length, rating: ContentRating.explicit),
                  ],
                  nextCursor: cursors.length.toString(),
                  exhausted: false,
                )
              : PostPage(items: [browsePost(99)], exhausted: true);
        },
      );
      await source.refresh();
      expect(cursors, [null, '1', '2', '3', '4']);
      expect(source.items.single.id, '99');
      expect(source.hasMore, isFalse);
      source.dispose();
    },
  );
  test('a finite empty ranking stops without another request', () async {
    var calls = 0;
    final source = PostListSource(
      key(),
      loader: (_, _) async {
        calls++;
        return page(exhausted: true);
      },
    );
    await source.refresh();
    await source.loadMore();
    expect(calls, 1);
    expect(source.phase, FrostLoadPhase.empty);
    source.dispose();
  });
  test(
    'old page responses cannot publish after their source was disposed',
    () async {
      final pending = Completer<PostPage>();
      final old = PostListSource(key(), loader: (_, _) => pending.future);
      final first = old.refresh();
      old.dispose();
      final current = PostListSource(
        key(revision: 1),
        loader: (_, _) async => page(exhausted: true),
      );
      await current.refresh();
      pending.complete(PostPage(items: [browsePost(1)], exhausted: true));
      await first;
      expect(old.items, isEmpty);
      expect(current.phase, FrostLoadPhase.empty);
      current.dispose();
    },
  );
  test('dispose removes listeners before a pending failure finishes', () async {
    final pending = Completer<PostPage>();
    final source = PostListSource(key(), loader: (_, _) => pending.future);
    final task = source.refresh();
    var notifications = 0;
    source.addListener(() => notifications++);
    source.dispose();
    pending.completeError(StateError('stale'));
    await task;
    expect(notifications, 0);
    expect(source.lastError, isNull);
  });
  test(
    'non-advancing and cyclic cursors are errors, never infinite loops',
    () async {
      for (final cyclic in [false, true]) {
        final source = PostListSource(
          key(),
          loader: (_, cursor) async => cyclic
              ? page(
                  next: cursor == null
                      ? 'a'
                      : cursor == 'a'
                      ? 'b'
                      : 'a',
                )
              : page(),
        );
        expect(await source.refresh(), isFalse);
        expect(source.lastError, isA<StateError>());
        source.dispose();
      }
    },
  );
  test('refresh keeps content and successful revision on failure', () async {
    var calls = 0;
    final source = PostListSource(
      key(ratings: []),
      loader: (_, _) async {
        if (++calls == 2) throw StateError('failed');
        return PostPage(items: [browsePost(calls)], exhausted: true);
      },
    );
    await source.refresh();
    expect(source.refreshRevision, 1);
    expect(await source.refresh(), isFalse);
    expect(source.items.single.id, '1');
    expect(source.refreshRevision, 1);
    await source.errorRefresh();
    expect(source.items.single.id, '3');
    expect(source.refreshRevision, 2);
    source.dispose();
  });
  test(
    'global ratings intersect supported source ratings without falling back',
    () {
      expect(
        ratingsForSource(key(ratings: []), [ContentRating.general]),
        isEmpty,
      );
      expect(
        ratingsForSource(
          key(ratings: [ContentRating.general, ContentRating.sensitive]),
          [ContentRating.general],
        ),
        [ContentRating.general],
      );
      expect(
        () => ratingsForSource(key(ratings: [ContentRating.explicit]), [
          ContentRating.general,
        ]),
        throwsA(isA<NoSupportedRatings>()),
      );
    },
  );
  test('an empty tag query does not call the loader', () async {
    var calls = 0;
    final source = PostListSource(
      key(request: TagSearchCollectionRequest([' '])),
      loader: (_, _) async {
        calls++;
        return page(exhausted: true);
      },
    );
    await source.refresh();
    expect(calls, 0);
    expect(source.items, isEmpty);
    source.dispose();
  });
  test('disposing an all-filtered source stops its backfill loop', () async {
    final pageReady = Completer<PostPage>();
    var calls = 0;
    final source = PostListSource(
      key(),
      loader: (_, _) {
        calls++;
        return pageReady.future;
      },
    );
    final pending = source.refresh();
    source.dispose();
    pageReady.complete(page(next: 'more'));
    await pending;
    expect(calls, 1);
    expect(source.items, isEmpty);
  });
}
