import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

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
    Future<PostPageDto> Function(CollectionKey key, String? cursor);

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

Future<PostPageDto> loadCollection(CollectionKey key, String? cursor) {
  final engine = BooruService.instance.engine;
  final ratings = ratingsForSource(
    key,
    BooruService.instance.sourceById(key.sourceId).capabilities.ratings,
  );
  return switch (key.request) {
    FeedCollectionRequest(:final kind, :final range, :final date) =>
      engine.feed(
        request: FeedRequestDto(
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
      request: SearchRequestDto(
        sourceId: key.sourceId,
        queryText: tags.join(' '),
        ratings: ratings,
        pageSize: 40,
        cursor: cursor,
      ),
    ),
  };
}

/// One state machine for feeds and searches. No page-number arithmetic in Dart.
class PostCollectionController extends ChangeNotifier {
  PostCollectionController(this.key, {CollectionLoader? loader})
    : _loader = loader ?? loadCollection;
  final CollectionKey key;
  final CollectionLoader _loader;
  List<Post> items = const [];
  String? cursor;
  bool exhausted = false;
  bool loading = false;
  bool initialized = false;
  Object? error;
  bool refreshFailed = false;
  int imageRefreshRevision = 0;
  DateTime? updatedAt;
  double scrollOffset = 0;
  double? viewportWidth;
  int _generation = 0;
  bool _disposed = false;
  bool get stale =>
      updatedAt == null ||
      DateTime.now().difference(updatedAt!) > const Duration(minutes: 10);

  Future<void> load({bool refresh = false}) async {
    if (_disposed || (loading && !refresh) || (exhausted && !refresh)) return;
    final generation = ++_generation;
    if (refresh) imageRefreshRevision++;
    loading = true;
    error = null;
    notifyListeners();
    var next = refresh ? null : cursor;
    final collected = <Post>[];
    var ended = false;
    try {
      if (key.request is TagSearchCollectionRequest &&
          (key.request as TagSearchCollectionRequest).tags.isEmpty) {
        ended = true;
      } else {
        // Bounded work prevents an all-filtered source from looping forever.
        for (var attempt = 0; attempt < 3; attempt++) {
          final page = await _loader(key, next);
          if (_disposed || generation != _generation) return;
          if (!page.exhausted &&
              (page.nextCursor == null || page.nextCursor == next)) {
            throw StateError('Source returned a non-advancing cursor');
          }
          next = page.nextCursor;
          ended = page.exhausted;
          collected.addAll(page.items.map(Post.new));
          if (collected.isNotEmpty || ended) break;
        }
      }
      if (_disposed || generation != _generation) return;
      final merged = <String, Post>{
        for (final post in refresh ? <Post>[] : items) post.postKey: post,
      };
      for (final post in collected) {
        merged.putIfAbsent(post.postKey, () => post);
      }
      items = List.unmodifiable(merged.values);
      cursor = next;
      exhausted = ended;
      initialized = true;
      updatedAt = DateTime.now();
      refreshFailed = false;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      error = e;
      refreshFailed = refresh;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void cancelPending() {
    _generation++;
    loading = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

/// Retain a bounded set of inactive views; active routes are never evicted.
class CollectionCache {
  static final instance = CollectionCache();
  final _entries = <CollectionKey, PostCollectionController>{};
  final _leases = <CollectionKey, int>{};
  PostCollectionController acquire(CollectionKey key) {
    final controller = _entries.remove(key) ?? PostCollectionController(key);
    _entries[key] = controller;
    _leases[key] = (_leases[key] ?? 0) + 1;
    return controller;
  }

  void release(CollectionKey key) {
    final count = (_leases[key] ?? 1) - 1;
    if (count > 0) {
      _leases[key] = count;
      return;
    }
    _leases.remove(key);
    _entries[key]?.cancelPending();
    for (final old in _entries.keys.toList()) {
      if (_leases.containsKey(old)) continue;
      if (_entries.length <= 12 && old.revision == key.revision) continue;
      _entries.remove(old)?.dispose();
    }
  }
}
