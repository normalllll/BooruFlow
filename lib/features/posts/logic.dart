import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@riverpod
Future<Post> postAttributionDetail(
  Ref ref,
  ({String sourceId, String postId}) key,
) async {
  return Post(
    await ref
        .read(booruServiceProvider)
        .engine
        .getPost(sourceId: key.sourceId, postId: key.postId),
  );
}

@riverpod
Future<List<Post>> getSimilar(
  Ref ref, {
  required String sourceId,
  required String id,
}) async {
  final source = ref.read(booruServiceProvider).sourceById(sourceId);
  if (!source.capabilities.supportsRelatedPosts) return const [];
  final posts = await ref
      .read(booruServiceProvider)
      .engine
      .relatedPosts(sourceId: sourceId, postId: id);
  return posts.map(Post.new).toList(growable: false);
}
