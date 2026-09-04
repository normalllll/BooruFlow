import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:booruflow/core/data_list_source.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

part 'logic.g.dart';

class PostListState {
  final List<String> tags;

  final PostListSource source;

  PostListState({required this.tags, required this.source});

  PostListState copyWith({List<String>? tags, PostListSource? source}) {
    return PostListState(
      tags: tags ?? this.tags,
      source: source ?? this.source,
    );
  }
}

class PostListSource extends DataListSource<Post> {
  final String sourceId;
  final List<String> tags;
  String? _cursor;
  bool _exhausted = false;

  PostListSource({required this.sourceId, this.tags = const []});

  @override
  Future<bool> refresh([bool notifyStateChanged = false, bool auto = true]) {
    _cursor = null;
    _exhausted = false;
    return super.refresh(notifyStateChanged, auto);
  }

  @override
  Future<List<Post>> fetchList(int page, int limit) async {
    if (_exhausted) return const [];
    final source = BooruService.instance.sourceById(sourceId);
    final ratings = SettingsService.ratings
        .where(source.capabilities.ratings.contains)
        .toList(growable: false);
    final result = await BooruService.instance.engine.search(
      request: SearchRequestDto(
        sourceId: sourceId,
        queryText: tags.join(' '),
        ratings: ratings,
        pageSize: limit,
        cursor: _cursor,
        contentPolicy: SettingsService.contentPolicy,
      ),
    );
    _cursor = result.nextCursor;
    _exhausted = result.exhausted || result.nextCursor == null;
    return result.items.map(Post.new).toList(growable: false);
  }
}

@Riverpod(keepAlive: true)
class PostList extends _$PostList {
  @override
  PostListState build(
    Type type, {
    required String sourceId,
    required List<String> tags,
  }) {
    return PostListState(
      tags: tags,
      source: PostListSource(sourceId: sourceId, tags: tags),
    );
  }

  void onTagsChanged(List<String> tags) {
    state.source.clear();
    state = state.copyWith(
      tags: tags,
      source: PostListSource(sourceId: state.source.sourceId, tags: tags),
    );
    state.source.refresh(true);
  }
}

@riverpod
Future<List<Post>> getSimilar(
  Ref ref, {
  required String sourceId,
  required String id,
}) async {
  final source = BooruService.instance.sourceById(sourceId);
  if (!source.capabilities.supportsRelatedPosts) return const [];
  final posts = await BooruService.instance.engine.relatedPosts(
    sourceId: sourceId,
    postId: id,
  );
  return posts.map(Post.new).toList(growable: false);
}
