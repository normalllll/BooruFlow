import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

final postAttributionDetailProvider = FutureProvider.autoDispose
    .family<Post, ({String sourceId, String postId})>((ref, key) async {
      return Post(
        await BooruService.instance.engine.getPost(
          sourceId: key.sourceId,
          postId: key.postId,
        ),
      );
    });

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
