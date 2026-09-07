import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/features/discovery/logic.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

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

PostPageDto page({String? next, bool exhausted = false}) =>
    PostPageDto(items: const [], nextCursor: next, exhausted: exhausted);

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
    final controller = PostCollectionController(
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
    controller.dispose();
  });

  test('finite empty ranking stops without making another request', () async {
    var calls = 0;
    final controller = PostCollectionController(
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
    controller.dispose();
  });

  test(
    'refresh supersedes pending load and ignores its later failure',
    () async {
      final old = Completer<PostPageDto>();
      var calls = 0;
      final controller = PostCollectionController(
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
      controller.dispose();
    },
  );

  test('dispose prevents pending request from publishing', () async {
    final response = Completer<PostPageDto>();
    final controller = PostCollectionController(
      key(),
      loader: (_, _) => response.future,
    );
    final pending = controller.load();
    controller.dispose();
    response.complete(page(exhausted: true));
    await pending;
    expect(controller.initialized, isFalse);
  });

  test(
    'non-advancing cursors become an error, never an infinite loop',
    () async {
      final controller = PostCollectionController(
        key(),
        loader: (_, _) async => page(),
      );
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.exhausted, isFalse);
      controller.dispose();
    },
  );

  test('no selected ratings still loads the default feed', () async {
    var calls = 0;
    final controller = PostCollectionController(
      key(ratings: []),
      loader: (key, _) async {
        expect(key.ratings, isEmpty);
        calls++;
        return page(exhausted: true);
      },
    );
    await controller.load();
    expect(calls, 1);
    controller.dispose();
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
      final controller = PostCollectionController(
        requestKey,
        loader: (_, _) async {
          calls++;
          return page(exhausted: true);
        },
      );
      await controller.load();
      expect(controller.items, isEmpty);
      controller.dispose();
    }
    expect(calls, 0);
  });
}
