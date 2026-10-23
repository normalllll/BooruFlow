import 'dart:convert';

import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'collection_logic.g.dart';

sealed class PostCollectionRequest {
  const PostCollectionRequest();
  List<Object?> get identity;
}

final class FeedCollectionRequest extends PostCollectionRequest {
  const FeedCollectionRequest({
    this.kind = FeedKind.latest,
    this.range,
    this.date,
  });
  final FeedKind kind;
  final PopularRange? range;
  final String? date;
  @override
  List<Object?> get identity => ['feed', kind.name, range?.name, date];
}

final class TagSearchCollectionRequest extends PostCollectionRequest {
  TagSearchCollectionRequest(Iterable<String> tags)
    : tags = List.unmodifiable(
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty),
      );
  final List<String> tags;
  @override
  List<Object?> get identity => ['search', ...tags];
}

final class CollectionKey {
  CollectionKey({
    required this.sourceId,
    required this.request,
    required Iterable<ContentRating> ratings,
    required this.revision,
  }) : ratings = List.unmodifiable(
         ratings.toSet().toList()..sort((a, b) => a.index.compareTo(b.index)),
       );
  final String sourceId;
  final PostCollectionRequest request;
  final List<ContentRating> ratings;
  final int revision;
  String get value => jsonEncode([
    sourceId,
    request.identity,
    ratings.map((r) => r.name).toList(),
    revision,
  ]);
  @override
  bool operator ==(Object other) =>
      other is CollectionKey && value == other.value;
  @override
  int get hashCode => value.hashCode;
}

typedef CollectionLoader =
    Future<PostPage> Function(CollectionKey key, String? cursor);

class NoSupportedRatings implements Exception {}

List<ContentRating> ratingsForSource(
  CollectionKey key,
  Iterable<ContentRating> supported,
) {
  if (key.ratings.isEmpty) {
    return const []; // Engine resolves the session default.
  }
  final values = key.ratings.where(supported.contains).toList();
  if (values.isEmpty) {
    throw NoSupportedRatings();
  }
  return values;
}

Future<PostPage> loadCollection(
  CollectionKey key,
  String? cursor, {
  BooruService? service,
}) {
  service ??= BooruService.instance;
  final engine = service.engine;
  final ratings = ratingsForSource(
    key,
    service.sourceById(key.sourceId).capabilities.ratings,
  );
  return switch (key.request) {
    FeedCollectionRequest(:final kind, :final range, :final date) =>
      engine.feed(
        request: FeedRequest(
          sourceId: key.sourceId,
          kind: kind,
          range: range,
          date: date,
          ratings: ratings,
          pageSize: 40,
          cursor: cursor,
        ),
      ),
    TagSearchCollectionRequest(:final tags) => engine.search(
      request: SearchRequest(
        sourceId: key.sourceId,
        queryText: tags.join(' '),
        ratings: ratings,
        pageSize: 40,
        cursor: cursor,
      ),
    ),
  };
}

typedef CollectionIdentity = ({CollectionKey key, CollectionLoader? loader});
@Riverpod(keepAlive: true)
CollectionLoader collectionLoader(Ref ref) {
  final service = ref.watch(booruServiceProvider);
  return (key, cursor) => loadCollection(key, cursor, service: service);
}

/// The page owns this source. Switching collection identity creates a new
/// instance; returning from detail keeps the existing page/source/scroll alive.
class PostListSource extends FrostListSource<Post> {
  PostListSource(this.key, {required this.loader});
  final CollectionKey key;
  final CollectionLoader loader;
  String? _cursor;
  bool _exhausted = false;

  @override
  Future<List<Post>> initList() => _fetch(null);
  @override
  Future<List<Post>> nextList() =>
      _exhausted ? Future.value([]) : _fetch(_cursor);
  @override
  bool hasMoreByResult(List<Post> list) => !_exhausted;

  Future<List<Post>> _fetch(String? cursor) async {
    if (key.request case TagSearchCollectionRequest(tags: [])) {
      _exhausted = true;
      return [];
    }
    var next = cursor;
    final visited = <String?>{};
    final seen = cursor == null
        ? <String>{}
        : items.map((post) => post.postKey).toSet();
    try {
      while (!isDisposed) {
        if (!visited.add(next)) {
          throw StateError('Source returned a cyclic cursor');
        }
        final page = await loader(key, next);
        if (isDisposed) return [];
        if (!page.exhausted &&
            (page.nextCursor == null || page.nextCursor == next)) {
          throw StateError('Source returned a non-advancing cursor');
        }
        final posts = [
          for (final item in page.items)
            if ((key.ratings.isEmpty || key.ratings.contains(item.rating)) &&
                seen.add(item.postKey))
              Post(item),
        ];
        next = page.nextCursor;
        if (posts.isNotEmpty || page.exhausted) {
          // Commit cursor state only with the page handed to FrostListSource.
          // An all-filtered page continues fetching instead of exposing a
          // second paging state or a manual 'continue' button to the view.
          _cursor = next;
          _exhausted = page.exhausted;
          return posts;
        }
      }
      return [];
    } catch (error) {
      throw makeBooruErrorReadable(error);
    }
  }
}
