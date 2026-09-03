import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

class YandeDownloadItem {
  const YandeDownloadItem({required this.snapshot, this.post});

  final DownloadTaskSnapshot snapshot;
  final Post? post;
}
