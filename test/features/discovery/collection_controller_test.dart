import 'dart:async';

import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  test('keys distinguish feed, query, filters and revision by value', () {
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
  });

  test('filtered empty pages retain cursor after bounded backfill', () async {
    final cursors = <String?>[];
    final controller = createController(
      key(),
      loader: (_, cursor) async {
        cursors.add(cursor);
        return page(next: '${cursors.length}');
      },
    );
    await controller.load();
    expect(cursors, [null, '1', '2']);
    expect(controller.cursor, '3');
    expect(controller.exhausted, isFalse);
    expect(controller.error, isNull);
    disposeController(controller);
  });

  test('finite empty ranking stops without making another request', () async {
    var calls = 0;
    final controller = createController(
      key(),
      loader: (_, _) async {
        calls++;
        return page(exhausted: true);
      },
    );
    await controller.load();
    await controller.load();
    expect(calls, 1);
    expect(controller.exhausted, isTrue);
    disposeController(controller);
  });

  test(
    'refresh supersedes pending load and ignores its later failure',
    () async {
      final old = Completer<PostPage>();
      var calls = 0;
      final controller = createController(
        key(),
        loader: (_, _) =>
            ++calls == 1 ? old.future : Future.value(page(exhausted: true)),
      );
      final first = controller.load();
      await controller.load(refresh: true);
      old.completeError(StateError('stale request'));
      await first;
      expect(controller.error, isNull);
      expect(controller.loading, isFalse);
      expect(controller.exhausted, isTrue);
      disposeController(controller);
    },
  );

  test('dispose prevents pending request from publishing', () async {
    final response = Completer<PostPage>();
    final controller = createController(
      key(),
      loader: (_, _) => response.future,
    );
    var published = controller.initialized;
    final container = _containers[controller]!;
    container.listen(
      postCollectionProvider(controller.identity),
      (_, next) => published = next.initialized,
    );
    final pending = controller.load();
    disposeController(controller);
    response.complete(page(exhausted: true));
    await pending;
    expect(published, isFalse);
  });

  test(
    'non-advancing cursors become an error, never an infinite loop',
    () async {
      final controller = createController(
        key(),
        loader: (_, _) async => page(),
      );
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.exhausted, isFalse);
      disposeController(controller);
    },
  );

  test('no selected ratings still loads the default feed', () async {
    var calls = 0;
    final controller = createController(
      key(ratings: []),
      loader: (key, _) async {
        expect(key.ratings, isEmpty);
        calls++;
        return page(exhausted: true);
      },
    );
    await controller.load();
    expect(calls, 1);
    disposeController(controller);
  });

  test(
    'global ratings intersect without turning unsupported selections into defaults',
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

  test('empty query never reaches the engine', () async {
    var calls = 0;
    for (final requestKey in [
      key(request: TagSearchCollectionRequest([' '])),
    ]) {
      final controller = createController(
        requestKey,
        loader: (_, _) async {
          calls++;
          return page(exhausted: true);
        },
      );
      await controller.load();
      expect(controller.items, isEmpty);
      disposeController(controller);
    }
    expect(calls, 0);
  });
}

final _containers = <PostCollection, ProviderContainer>{};
PostCollection createController(
  CollectionKey key, {
  required CollectionLoader loader,
}) {
  final container = ProviderContainer();
  final provider = postCollectionProvider((key: key, loader: loader));
  container.listen(provider, (_, _) {});
  final controller = container.read(provider.notifier);
  _containers[controller] = container;
  return controller;
}

void disposeController(PostCollection controller) =>
    _containers.remove(controller)!.dispose();
