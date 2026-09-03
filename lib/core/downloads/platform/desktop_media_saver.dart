import 'dart:io';
import 'dart:typed_data';

import 'package:yande_gui/core/downloads/download_file_system.dart';
import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/core/downloads/media_saver.dart';
import 'package:path/path.dart' as p;

final class DesktopMediaSaver implements MediaSaver {
  const DesktopMediaSaver();

  @override
  Future<SaveResult> saveDownloadedFile({
    required DownloadJob job,
    required DownloadedFile file,
  }) async {
    final destinationDirectory = Directory(await _resolveDirectory(job));
    await ensureWritableDirectory(destinationDirectory);

    final source = File(file.path);
    if (!await source.exists()) {
      throw DownloadException(
        'Downloaded temp file does not exist: ${file.path}',
      );
    }

    final destination = File(
      p.join(destinationDirectory.path, safeDownloadFilename(job.filename)),
    );
    final moved = await moveFileWithFallback(
      source: source,
      destination: destination,
    );
    return SaveResult(path: moved.path, bytesWritten: file.bytesWritten);
  }

  @override
  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  }) async {
    final destinationDirectory = Directory(await _resolveDirectory(job));
    final saved = await writeBytesAtomically(
      bytes: bytes,
      directory: destinationDirectory,
      filename: job.filename,
    );
    return SaveResult(path: saved.path, bytesWritten: saved.bytesWritten);
  }

  Future<String> _resolveDirectory(DownloadJob job) async {
    return resolveDesktopDownloadDirectory(
      explicitDirectory: job.saveTarget.directory,
    );
  }
}
