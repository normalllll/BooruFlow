import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/media_saver.dart';
import 'package:crypto/crypto.dart';
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

    if (job.batchId != null) {
      return _withUniqueDestination(
        destinationDirectory,
        job.filename,
        (destination) async {
          final moved = await moveFileWithFallback(
            source: source,
            destination: destination,
          );
          return SaveResult(path: moved.path, bytesWritten: file.bytesWritten);
        },
        matches: (destination) async {
          final same = await Isolate.run(
            () => _sameFile(source.path, destination.path),
          );
          if (same && !p.equals(source.path, destination.path)) {
            // A cleanup failure must not turn a successfully reused image into a
            // save failure and trigger another download.
            try {
              await source.delete();
            } on FileSystemException {
              /* Temp cleanup is best effort. */
            }
          }
          return same;
        },
        bytesWritten: file.bytesWritten,
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
    if (job.batchId != null) {
      await ensureWritableDirectory(destinationDirectory);
      return _withUniqueDestination(
        destinationDirectory,
        job.filename,
        (destination) async {
          final saved = await writeBytesAtomically(
            bytes: bytes,
            directory: destinationDirectory,
            filename: p.basename(destination.path),
          );
          return SaveResult(path: saved.path, bytesWritten: saved.bytesWritten);
        },
        matches: (destination) => Isolate.run(() async {
          if (await destination.length() != bytes.length) return false;
          return await sha256.bind(destination.openRead()).first ==
              sha256.convert(bytes);
        }),
        bytesWritten: bytes.length,
      );
    }
    final saved = await writeBytesAtomically(
      bytes: bytes,
      directory: destinationDirectory,
      filename: job.filename,
    );
    return SaveResult(path: saved.path, bytesWritten: saved.bytesWritten);
  }

  Future<String> _resolveDirectory(DownloadJob job) async {
    final root = await resolveDesktopDownloadDirectory(
      explicitDirectory: job.saveTarget.directory,
    );
    final child = job.saveTarget.subdirectory;
    return child == null || child.isEmpty ? root : p.join(root, child);
  }
}

// Keep the reservation until the move finishes: concurrent downloads can have
// the same filename even within a single batch. A stale reservation only causes
// a suffix to be skipped after a crash, never an existing image to be replaced.
Future<SaveResult> _withUniqueDestination(
  Directory directory,
  String filename,
  Future<SaveResult> Function(File destination) save, {
  required Future<bool> Function(File destination) matches,
  required int bytesWritten,
}) async {
  final safe = safeDownloadFilename(filename);
  final stem = p.basenameWithoutExtension(safe);
  final extension = p.extension(safe);
  for (var suffix = 0; ; suffix++) {
    final name = suffix == 0 ? safe : '$stem ($suffix)$extension';
    final destination = File(p.join(directory.path, name));
    final reservation = File('${destination.path}.booruflow-reservation');
    if (await destination.exists()) {
      if (await matches(destination)) {
        return SaveResult(path: destination.path, bytesWritten: bytesWritten);
      }
      continue;
    }
    try {
      await reservation.create(exclusive: true);
    } on FileSystemException {
      if (await reservation.exists()) continue;
      rethrow;
    }
    try {
      if (await destination.exists()) {
        if (await matches(destination)) {
          return SaveResult(path: destination.path, bytesWritten: bytesWritten);
        }
        continue;
      }
      return await save(destination);
    } finally {
      await reservation.delete();
    }
  }
}

Future<bool> _sameFile(String sourcePath, String destinationPath) async {
  final source = File(sourcePath), destination = File(destinationPath);
  if (await source.length() != await destination.length()) return false;
  return await sha256.bind(source.openRead()).first ==
      await sha256.bind(destination.openRead()).first;
}
