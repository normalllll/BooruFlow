import 'dart:convert';

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
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

@Riverpod(keepAlive: true)
CollectionRetention collectionRetention(Ref ref) => CollectionRetention();

class PostCollectionState {
  const PostCollectionState({
    this.items = const [],
    this.cursor,
    this.exhausted = false,
    this.loading = false,
    this.initialized = false,
    this.error,
    this.refreshFailed = false,
    this.imageRefreshRevision = 0,
    this.updatedAt,
  });
  final List<Post> items;
  final String? cursor;
  final bool exhausted, loading, initialized, refreshFailed;
  final Object? error;
  final int imageRefreshRevision;
  final DateTime? updatedAt;
  PostCollectionState copyWith({
    bool? loading,
    Object? error,
    bool clearError = false,
    bool? refreshFailed,
    int? imageRefreshRevision,
  }) => PostCollectionState(
    items: items,
    cursor: cursor,
    exhausted: exhausted,
    initialized: initialized,
    updatedAt: updatedAt,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    refreshFailed: refreshFailed ?? this.refreshFailed,
    imageRefreshRevision: imageRefreshRevision ?? this.imageRefreshRevision,
  );
}

/// Provider lifetimes retain at most twelve inactive collections; active routes
/// remain alive regardless of the cache limit.
class CollectionRetention {
  final _entries = <CollectionIdentity, void Function()>{};
  final _active = <CollectionIdentity>{};
  void activate(CollectionIdentity key, void Function() close) {
    _entries.remove(key);
    _entries[key] = close;
    _active.add(key);
  }

  void deactivate(CollectionIdentity key) {
    _active.remove(key);
    for (final old in _entries.keys.toList()) {
      if (_active.contains(old)) continue;
      if (_entries.length <= 12 && old.key.revision == key.key.revision) {
        continue;
      }
      _entries.remove(old)?.call();
    }
  }

  void remove(CollectionIdentity key) {
    _entries.remove(key);
    _active.remove(key);
  }
}

@riverpod
/// One state machine for feeds and searches. No page-number arithmetic in Dart.
class PostCollection extends _$PostCollection {
  CollectionKey get key => identity.key;
  CollectionLoader get _loader =>
      identity.loader ?? ref.read(collectionLoaderProvider);
  List<Post> get items => state.items;
  String? get cursor => state.cursor;
  bool get exhausted => state.exhausted;
  bool get loading => state.loading;
  bool get initialized => state.initialized;
  Object? get error => state.error;
  bool get refreshFailed => state.refreshFailed;
  int get imageRefreshRevision => state.imageRefreshRevision;
  DateTime? get updatedAt => state.updatedAt;
  double scrollOffset = 0;
  double? viewportWidth;
  int _generation = 0;
  bool _inactive = false;
  bool get _disposed => !ref.mounted;
  bool get stale =>
      updatedAt == null ||
      DateTime.now().difference(updatedAt!) > const Duration(minutes: 10);

  @override
  PostCollectionState build(CollectionIdentity identity) {
    final retention = ref.read(collectionRetentionProvider);
    final link = ref.keepAlive();
    retention.activate(identity, link.close);
    ref.onCancel(() {
      _inactive = true;
      _generation++;
      Future.microtask(() {
        if (!ref.mounted || !_inactive) return;
        state = state.copyWith(loading: false);
        retention.deactivate(identity);
      });
    });
    ref.onResume(() {
      _inactive = false;
      retention.activate(identity, link.close);
      final generation = _generation;
      // Riverpod also forbids reading state inside lifecycle callbacks.
      Future.microtask(() {
        if (!ref.mounted || _inactive || generation != _generation) return;
        if (state.loading) load(refresh: true);
      });
    });
    ref.onDispose(() {
      _generation++;
      retention.remove(identity);
    });
    return const PostCollectionState();
  }

  Future<void> load({bool refresh = false}) async {
    if (_disposed || (loading && !refresh) || (exhausted && !refresh)) return;
    final generation = ++_generation;
    state = state.copyWith(
      loading: true,
      clearError: true,
      imageRefreshRevision: imageRefreshRevision + (refresh ? 1 : 0),
    );
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
      state = PostCollectionState(
        items: List.unmodifiable(merged.values),
        cursor: next,
        exhausted: ended,
        initialized: true,
        loading: true,
        updatedAt: DateTime.now(),
        imageRefreshRevision: imageRefreshRevision,
      );
    } catch (e) {
      if (_disposed || generation != _generation) return;
      state = state.copyWith(error: e, refreshFailed: refresh);
    } finally {
      if (!_disposed && generation == _generation) {
        state = state.copyWith(loading: false);
      }
    }
  }
}
