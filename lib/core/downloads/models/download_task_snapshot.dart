import 'package:booruflow/core/file_paths.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;

import 'download_enums.dart';

class DownloadTaskSnapshot {
  const DownloadTaskSnapshot({
    required this.id,
    required this.resourceId,
    required this.variantIndex,
    required this.title,
    required this.filename,
    required this.status,
    required this.saveState,
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    required this._localPath,
    required this.error,
    required this.log,
    required this.createdAt,
    required this.updatedAt,
    this.sourceId,
    this.postId,
    this.thumbnailUrl,
    this.galleryAssetId,
    this.batchId,
    this.batchName,
    this.ugoiraExport,
  });

  final UgoiraExport? ugoiraExport;
  final String id;
  final String? sourceId;
  final String? postId;
  final String? batchId;

  /// The chosen batch folder name, recovered from existing job metadata.
  final String? batchName;
  final int resourceId;
  final int variantIndex;
  final String title;
  final String filename;
  final String? thumbnailUrl;
  final DownloadStatus status;
  final SaveState saveState;
  final int receivedBytes;
  final int? totalBytes;
  final double progress;
  final String? _localPath;
  String? get localPath =>
      _localPath == null ? null : normalizeLocalPath(_localPath);
  final String? galleryAssetId;
  final String? error;
  final String? log;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal {
    return status == DownloadStatus.downloaded ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.cancelled;
  }
}
