import 'dart:async';

import 'download_models.dart';

class DownloadCapabilities {
  const DownloadCapabilities({
    required this.supportsBackground,
    required this.supportsCancel,
    required this.supportsPauseResume,
    required this.handlesSaving,
    required this.supportsHeaders,
    required this.supportsProxy,
    required this.supportsHostOverride,
    required this.supportsCertificateBypass,
    required this.supportsValidation,
  });

  final bool supportsBackground;
  final bool supportsCancel;
  final bool supportsPauseResume;
  final bool handlesSaving;
  final bool supportsHeaders;
  final bool supportsProxy;
  final bool supportsHostOverride;
  final bool supportsCertificateBypass;
  final bool supportsValidation;
}

abstract interface class DownloadEngine {
  DownloadEngineType get type;

  DownloadCapabilities get capabilities;

  Stream<DownloadEngineEvent> get events;

  Future<void> initialize();

  Future<void> start(List<DownloadJob> jobs);

  Future<void> pause(String jobId);

  Future<void> resume(String jobId);

  Future<void> cancel(String jobId);

  Future<List<DownloadEngineSnapshot>> syncActiveTasks();

  /// Releases terminal snapshots retained by a background engine after their
  /// state has been durably recorded by the manager.
  Future<void> acknowledge(Set<String> jobIds);

  Future<void> dispose();
}

class DownloadEngineSnapshot {
  const DownloadEngineSnapshot({
    required this.jobId,
    required this.status,
    required this.saveState,
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
    this.localPath,
    this.galleryAssetId,
    this.error,
  });

  final String jobId;
  final DownloadStatus status;
  final SaveState saveState;
  final int receivedBytes;
  final int? totalBytes;
  final double progress;
  final String? localPath;
  final String? galleryAssetId;
  final String? error;
}

sealed class DownloadEngineEvent {
  const DownloadEngineEvent(this.jobId);

  final String jobId;
}

class EngineProgressEvent extends DownloadEngineEvent {
  const EngineProgressEvent({
    required String jobId,
    required this.receivedBytes,
    required this.totalBytes,
    required this.progress,
  }) : super(jobId);

  final int receivedBytes;
  final int? totalBytes;
  final double progress;
}

class EngineCompletedEvent extends DownloadEngineEvent {
  const EngineCompletedEvent({
    required String jobId,
    required this.localPath,
    required this.bytesWritten,
  }) : super(jobId);

  final String localPath;
  final int bytesWritten;
}

class EngineFailedEvent extends DownloadEngineEvent {
  const EngineFailedEvent({required String jobId, required this.error})
    : super(jobId);

  final String error;
}

class EnginePausedEvent extends DownloadEngineEvent {
  const EnginePausedEvent({required String jobId}) : super(jobId);
}

class EngineCancelledEvent extends DownloadEngineEvent {
  const EngineCancelledEvent({required String jobId}) : super(jobId);
}

class EngineSaveCompletedEvent extends DownloadEngineEvent {
  const EngineSaveCompletedEvent({
    required String jobId,
    required this.path,
    this.galleryAssetId,
  }) : super(jobId);

  final String path;
  final String? galleryAssetId;
}

class EngineSaveFailedEvent extends DownloadEngineEvent {
  const EngineSaveFailedEvent({
    required String jobId,
    required this.error,
    this.localPath,
  }) : super(jobId);

  final String error;
  final String? localPath;
}
