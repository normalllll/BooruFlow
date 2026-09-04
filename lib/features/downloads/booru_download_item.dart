import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/posts/models/post.dart';

class BooruDownloadItem {
  const BooruDownloadItem({required this.snapshot, this.post});

  final DownloadTaskSnapshot snapshot;
  final Post? post;
}
