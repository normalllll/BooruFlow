import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/post.dart';

typedef PostDetailResult = ({Post? value, AsyncValue<void> request});

typedef PostIdentity = ({String sourceId, String postId});
PostIdentity postIdentity(Post post) =>
    (sourceId: post.sourceId, postId: post.id);

/// Request results belong to one open detail page, not a global provider cache.
/// This owns no image handles, decoded-image budget, or disk-cache entries.
class PostDetailSession extends ChangeNotifier {
  PostDetailSession({
    required Post initial,
    required Iterable<Post> knownPosts,
    required this.loadPost,
    required this.loadFamily,
  }) : _initial = initial {
    for (final post in knownPosts) {
      _posts[postIdentity(post)] = (
        value: post,
        request: const AsyncData<void>(null),
      );
    }
    _posts.putIfAbsent(
      postIdentity(initial),
      () => (value: initial, request: const AsyncData<void>(null)),
    );
  }
  final Post _initial;
  final Future<Post> Function(PostIdentity) loadPost;
  final Future<List<Post>> Function(PostIdentity) loadFamily;
  final _posts = <PostIdentity, PostDetailResult>{};
  final _postRequests = <PostIdentity, Future<void>>{};
  final _families = <PostIdentity, PostFamily>{};
  bool _disposed = false;
  PostDetailResult detail(Post post) =>
      _posts[postIdentity(post)] ??
      (value: post, request: const AsyncData<void>(null));
  Post? lookup(PostIdentity key) => _posts[key]?.value;

  void start() {
    unawaited(_requestPost(postIdentity(_initial)));
    select(_initial);
  }

  void select(Post post) {
    final key = postIdentity(post);
    _posts.putIfAbsent(
      key,
      () => (value: post, request: const AsyncData<void>(null)),
    );
    if (post.hasChildren || post.parentId != null) _ensureFamily(post);
  }

  PostIdentity _root(Post post) {
    var key = postIdentity(post);
    final seen = <PostIdentity>{};
    while (seen.add(key)) {
      final parent = lookup(key)?.parentId;
      if (parent == null) return key;
      key = (sourceId: post.sourceId, postId: parent);
    }
    return key;
  }

  PostFamily? family(Post post) => _families[_root(post)];

  void _mergeKnown(PostFamily family) {
    final keys = <PostIdentity>{family.root, ...family.keys};
    var changed = true;
    while (changed) {
      changed = false;
      for (final entry in _posts.entries) {
        final post = entry.value.value;
        if (post == null || post.sourceId != family.root.sourceId) continue;
        final parent = post.parentId;
        if (entry.key == family.root ||
            parent != null &&
                keys.contains((sourceId: post.sourceId, postId: parent))) {
          if (keys.add(entry.key)) changed = true;
        }
      }
    }
    final children = keys.where((key) => key != family.root).toList()
      ..sort((a, b) {
        final left = BigInt.tryParse(a.postId),
            right = BigInt.tryParse(b.postId);
        return left != null && right != null
            ? left.compareTo(right)
            : a.postId.compareTo(b.postId);
      });
    family._keys = List.unmodifiable([family.root, ...children]);
  }

  void _ensureFamily(Post post) {
    final root = _root(post);
    if (_families.containsKey(root)) return;
    final family = PostFamily(root);
    _families[root] = family;
    _mergeKnown(family);
    if (lookup(root) == null) unawaited(_requestPost(root));
    unawaited(_requestFamily(family));
  }

  Future<void> _requestPost(PostIdentity key) =>
      _postRequests.putIfAbsent(key, () async {
        final previous = _posts[key];
        _posts[key] = (value: previous?.value, request: const AsyncLoading());
        try {
          final post = await loadPost(key);
          if (_disposed) return;
          _posts[key] = (value: post, request: const AsyncData<void>(null));
          if (post.hasChildren || post.parentId != null) _ensureFamily(post);
        } catch (error, stack) {
          if (_disposed) return;
          _posts[key] = (
            value: _posts[key]?.value ?? previous?.value,
            request: AsyncError(error, stack),
          );
        }
        if (_disposed) return;
        for (final family in _families.values) {
          _mergeKnown(family);
        }
        notifyListeners();
      });
  Future<void> _requestFamily(PostFamily family) async {
    try {
      final posts = await loadFamily(family.root);
      if (_disposed) return;
      for (final post in posts) {
        final key = postIdentity(post);
        if (_posts[key]?.value == null) {
          _posts[key] = (value: post, request: const AsyncData<void>(null));
        }
      }
      _mergeKnown(family);
      family._request = const AsyncData(null);
    } catch (error, stack) {
      if (_disposed) return;
      family._request = AsyncError(error, stack);
    }
    if (!_disposed) notifyListeners();
  }

  void retry(Post post) {
    final key = postIdentity(post);
    _postRequests.remove(key);
    unawaited(_requestPost(key));
  }

  void retryFamily(PostFamily family) {
    if (family.loading) return;
    family._request = const AsyncLoading();
    unawaited(_requestFamily(family));
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _posts.clear();
    _postRequests.clear();
    _families.clear();
    super.dispose();
  }
}

class PostFamily {
  PostFamily(this.root);
  final PostIdentity root;
  List<PostIdentity> _keys = const [];
  List<PostIdentity> get keys => _keys;
  AsyncValue<void> _request = const AsyncLoading();
  bool get loading => _request.isLoading;
  Object? get error => _request.error;
}
