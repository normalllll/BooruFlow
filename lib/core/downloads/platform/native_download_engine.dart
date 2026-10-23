import 'dart:io';

import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/downloads/media_saver.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'desktop_media_saver.dart';

final class NativeMediaSaver implements MediaSaver {
  NativeMediaSaver({
    this.channelNamespace = 'booruflow',
    DownloadPlatform? platform,
    Future<Directory> Function()? documentsDirectory,
  }) : _platform = platform ?? DownloadPlatform.current,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final DownloadPlatform _platform;
  final Future<Directory> Function() _documentsDirectory;

  final String channelNamespace;

  late final _methodChannel = MethodChannel(
    '$channelNamespace/download_engine',
  );

  @override
  Future<SaveResult> saveDownloadedFile({
    required DownloadJob job,
    required DownloadedFile file,
  }) async {
    // Rust verified the source before conversion. Its checksum/length describe
    // the ZIP, so this local boundary validates the exported output length.
    final saveJob = job.ugoiraExport == UgoiraExport.losslessWebp
        ? job.copyWith(
            validation: DownloadValidationOptions(
              expectedBytes: file.bytesWritten,
            ),
          )
        : job;
    if (_platform.usesFiles(saveJob)) {
      final documents = await _documentsDirectory();
      return const DesktopMediaSaver().saveDownloadedFile(
        job: saveJob.copyWith(
          saveTarget: SaveTarget.downloadsFolder(
            directory: p.join(documents.path, appDownloadDirectoryName),
            subdirectory: saveJob.saveTarget.subdirectory,
          ),
        ),
        file: file,
      );
    }
    var prefersDefaultAlbum = false;
    if (_platform == DownloadPlatform.ios && saveJob.batchId == null) {
      final access = IosPhotosReadAccess.parse(
        await _methodChannel.invokeMethod<String>('photosReadAccess'),
      );
      prefersDefaultAlbum = access.mayUseDefaultAlbum;
    }
    final response = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
      'saveFile',
      {
        'job': {
          ...saveJob.toPlatformJson(),
          'prefersDefaultAlbum': prefersDefaultAlbum,
        },
        'path': file.path,
        'bytesWritten': file.bytesWritten,
      },
    );
    return _saveResultFromNative(response, fallbackBytes: file.bytesWritten);
  }

  @override
  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  }) async {
    final tempFile = await _writeTempBytes(job, bytes);
    return saveDownloadedFile(
      job: job,
      file: DownloadedFile(
        path: tempFile.path,
        bytesWritten: bytes.lengthInBytes,
      ),
    );
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
