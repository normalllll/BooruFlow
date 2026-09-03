import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:yande_gui/core/downloads/download_engine.dart';
import 'package:yande_gui/core/downloads/download_file_system.dart';
import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/core/downloads/media_saver.dart';
import 'package:path/path.dart' as p;

final class NativeDownloadEngine implements DownloadEngine {
  NativeDownloadEngine({
    required this.type,
    this.channelNamespace = 'yande_gui',
  });

  final String channelNamespace;

  late final _methodChannel = MethodChannel(
    '$channelNamespace/download_engine',
  );
  late final _eventChannel = EventChannel(
    '$channelNamespace/download_engine/events',
  );

  @override
  final DownloadEngineType type;

  @override
  DownloadCapabilities get capabilities {
    return DownloadCapabilities(
      supportsBackground: true,
      supportsCancel: true,
      supportsPauseResume: false,
      handlesSaving: true,
      supportsHeaders: true,
      supportsProxy: true,
      supportsHostOverride: true,
      supportsCertificateBypass: true,
      supportsValidation: true,
    );
  }

  late final Stream<DownloadEngineEvent> _events = _eventChannel
      .receiveBroadcastStream()
      .map(_eventFromNative)
      .where((event) => event != null)
      .cast<DownloadEngineEvent>()
      .asBroadcastStream();

  @override
  Stream<DownloadEngineEvent> get events => _events;

  @override
  Future<void> initialize() async {
    await _methodChannel.invokeMethod<void>('initialize');
  }

  @override
  Future<void> start(List<DownloadJob> jobs) async {
    await _methodChannel.invokeMethod<void>('start', {
      'jobs': jobs.map((job) => job.toPlatformJson()).toList(growable: false),
    });
  }

  @override
  Future<void> pause(String jobId) {
    throw UnsupportedError(
      'Pause is not supported by the native download engine yet.',
    );
  }

  @override
  Future<void> resume(String jobId) {
    throw UnsupportedError(
      'Resume is not supported by the native download engine yet.',
    );
  }

  @override
  Future<void> cancel(String jobId) async {
    await _methodChannel.invokeMethod<void>('cancel', {'jobId': jobId});
  }

  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async {
    final response = await _methodChannel.invokeMethod<List<Object?>>('sync');
    return [
      for (final item in response ?? const <Object?>[])
        if (item is Map) _snapshotFromNative(item.cast<String, Object?>()),
    ];
  }

  @override
  Future<void> acknowledge(Set<String> jobIds) async {
    if (jobIds.isEmpty) {
      return;
    }
    await _methodChannel.invokeMethod<void>('acknowledge', {
      'jobIds': jobIds.toList(growable: false),
    });
  }

  @override
  Future<void> dispose() async {}

  DownloadEngineEvent? _eventFromNative(Object? event) {
    if (event is! Map) {
      return null;
    }
    final map = event.cast<String, Object?>();
    final type = map['type'] as String?;
    final jobId = map['jobId'] as String?;
    if (type == null || jobId == null) {
      return null;
    }

    return switch (type) {
      'progress' => EngineProgressEvent(
        jobId: jobId,
        receivedBytes: _intValue(map['receivedBytes']),
        totalBytes: _nullableIntValue(map['totalBytes']),
        progress: _doubleValue(map['progress']).clamp(0, 1),
      ),
      'completed' => EngineCompletedEvent(
        jobId: jobId,
        localPath: map['localPath'] as String? ?? '',
        bytesWritten: _intValue(map['bytesWritten']),
      ),
      'failed' => EngineFailedEvent(
        jobId: jobId,
        error: map['error'] as String? ?? 'Download failed',
      ),
      'cancelled' => EngineCancelledEvent(jobId: jobId),
      'saved' => EngineSaveCompletedEvent(
        jobId: jobId,
        path:
            (map['path'] as String?) ??
            (map['galleryAssetId'] as String?) ??
            '',
        galleryAssetId: map['galleryAssetId'] as String?,
      ),
      'saveFailed' => EngineSaveFailedEvent(
        jobId: jobId,
        error: map['error'] as String? ?? 'Save failed',
        localPath: map['localPath'] as String?,
      ),
      _ => null,
    };
  }

  DownloadEngineSnapshot _snapshotFromNative(Map<String, Object?> map) {
    return DownloadEngineSnapshot(
      jobId: map['jobId'] as String? ?? '',
      status: _enumValue(
        DownloadStatus.values,
        map['status'] as String?,
        DownloadStatus.failed,
      ),
      saveState: _enumValue(
        SaveState.values,
        map['saveState'] as String?,
        SaveState.none,
      ),
      receivedBytes: _intValue(map['receivedBytes']),
      totalBytes: _nullableIntValue(map['totalBytes']),
      progress: _doubleValue(map['progress']).clamp(0, 1),
      localPath: map['localPath'] as String?,
      galleryAssetId: map['galleryAssetId'] as String?,
      error: map['error'] as String?,
    );
  }
}

final class NativeMediaSaver implements MediaSaver {
  NativeMediaSaver({this.channelNamespace = 'yande_gui'});

  final String channelNamespace;

  late final _methodChannel = MethodChannel(
    '$channelNamespace/download_engine',
  );

  @override
  Future<SaveResult> saveDownloadedFile({
    required DownloadJob job,
    required DownloadedFile file,
  }) async {
    final response = await _methodChannel
        .invokeMethod<Map<Object?, Object?>>('saveFile', {
          'job': job.toPlatformJson(),
          'path': file.path,
          'bytesWritten': file.bytesWritten,
        });
    return _saveResultFromNative(response, fallbackBytes: file.bytesWritten);
  }

  @override
  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  }) async {
    final tempFile = await _writeTempBytes(job, bytes);
    final response = await _methodChannel
        .invokeMethod<Map<Object?, Object?>>('saveFile', {
          'job': job.toPlatformJson(),
          'path': tempFile.path,
          'bytesWritten': bytes.lengthInBytes,
        });
    return _saveResultFromNative(response, fallbackBytes: bytes.lengthInBytes);
  }

  Future<File> _writeTempBytes(DownloadJob job, Uint8List bytes) async {
    final directory = await downloadTempDirectory();
    final file = File(
      p.join(directory.path, '${job.id}-${safeDownloadFilename(job.filename)}'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  SaveResult _saveResultFromNative(
    Map<Object?, Object?>? response, {
    required int fallbackBytes,
  }) {
    if (response == null) {
      throw const DownloadException('Native save did not return a result.');
    }
    final path =
        (response['path'] as String?) ??
        (response['galleryAssetId'] as String?);
    if (path == null || path.isEmpty) {
      throw const DownloadException('Native save returned an empty path.');
    }
    return SaveResult(
      path: path,
      bytesWritten: _intValue(
        response['bytesWritten'],
        fallback: fallbackBytes,
      ),
      galleryAssetId: response['galleryAssetId'] as String?,
    );
  }
}

int _intValue(Object? value, {int fallback = 0}) {
  return switch (value) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value) ?? fallback,
    _ => fallback,
  };
}

int? _nullableIntValue(Object? value) {
  if (value == null) {
    return null;
  }
  return _intValue(value);
}

double _doubleValue(Object? value, {double fallback = 0}) {
  return switch (value) {
    double value => value,
    num value => value.toDouble(),
    String value => double.tryParse(value) ?? fallback,
    _ => fallback,
  };
}

T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
