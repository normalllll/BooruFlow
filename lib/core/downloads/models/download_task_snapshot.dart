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
    required this.localPath,
    required this.error,
    required this.log,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.galleryAssetId,
  });

  final String id;
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
  final String? localPath;
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
