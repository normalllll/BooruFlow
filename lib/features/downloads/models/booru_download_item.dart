import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/posts/models/post.dart';

class BooruDownloadItem {
  const BooruDownloadItem({required this.snapshot, this.post});

  final DownloadTaskSnapshot snapshot;
  final Post? post;
  String? get sourceId => post?.sourceId ?? snapshot.sourceId;
  String? get postId => post?.id ?? snapshot.postId;
  bool get canOpenPost =>
      sourceId != null &&
      sourceId!.isNotEmpty &&
      sourceId != 'direct' &&
      postId != null &&
      postId!.isNotEmpty;
}
