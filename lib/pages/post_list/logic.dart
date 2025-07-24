import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yande_gui/data_list_source.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

part 'logic.g.dart';

class PostListState {
  final List<String> tags;

  final PostListSource source;

  PostListState({required this.tags, required this.source});

  PostListState copyWith({List<String>? tags, PostListSource? source}) {
    return PostListState(tags: tags ?? this.tags, source: source ?? this.source);
  }
}

class PostListSource extends DataListSource<Post> {
  final List<String> tags;

  PostListSource({this.tags = const []});

  @override
  Future<List<Post>> fetchList(int page, int limit) {
    return yandeClient.getPosts(tags: tags, limit: limit, page: page);
  }
}

@Riverpod(keepAlive: true)
class PostList extends _$PostList {
  @override
  PostListState build(Type type, {required List<String> tags}) {
    return PostListState(tags: tags, source: PostListSource(tags: tags));
  }

  void onTagsChanged(List<String> tags) {
    state.source.clear();
    state = state.copyWith(tags: tags, source: PostListSource(tags: tags));
    state.source.refresh(true);
  }
}
