import 'dart:typed_data';

import 'download_models.dart';

abstract interface class DownloadManager {
  Future<void> initialize();

  Future<void> ensureReadyForDownloads();

  Future<int> enqueue(List<DownloadJob> jobs);

  Future<void> refreshQueue();

  Future<DownloadedFile> download({
    required int resourceId,
    required int variantIndex,
    required Uri url,
    String? filename,
    DownloadNetworkOptions networkOptions = const DownloadNetworkOptions(),
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? title,
    String? thumbnailUrl,
  });

  Future<DownloadedFile> saveBytes({
    required int resourceId,
    required int variantIndex,
    required Uint8List bytes,
    required Uri sourceUrl,
    String? filename,
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? title,
    String? thumbnailUrl,
  });

  Future<void> pause(String jobId);

  Future<void> resume(String jobId);

  Future<void> cancel(String jobId);

  Future<void> deleteTask(String jobId);

  Future<void> retry(String jobId);

  Future<void> retrySave(String jobId);

  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  });

  Stream<List<DownloadTaskSnapshot>> watchTasks({int? resourceId});

  Stream<DownloadTaskSnapshot?> watchTask(String jobId);

  Stream<DownloadSummary> watchSummary({int? resourceId});

  Future<void> sync();

  Future<void> dispose();
}
