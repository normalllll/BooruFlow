import 'dart:typed_data';

import 'download_models.dart';

class SaveResult {
  const SaveResult({
    required this.path,
    required this.bytesWritten,
    this.galleryAssetId,
  });

  final String path;
  final int bytesWritten;
  final String? galleryAssetId;
}

abstract interface class MediaSaver {
  Future<SaveResult> saveDownloadedFile({
    required DownloadJob job,
    required DownloadedFile file,
  });

  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  });
}

class UnsupportedMediaSaver implements MediaSaver {
  const UnsupportedMediaSaver();

  @override
  Future<SaveResult> saveDownloadedFile({
    required DownloadJob job,
    required DownloadedFile file,
  }) {
    throw UnsupportedError(
      'Saving downloaded files is not implemented on this platform.',
    );
  }

  @override
  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  }) {
    throw UnsupportedError(
      'Saving downloaded files is not implemented on this platform.',
    );
  }
}
