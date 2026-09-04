import 'dart:io';
import 'dart:typed_data';

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const appDownloadDirectoryName = 'BooruFlow';
const downloadMediaDirectoryName = 'images';
const downloadTempDirectoryName = 'booruflow_downloads';
const fallbackDownloadFilename = 'download';

String resourceDownloadFilename({
  required int resourceId,
  required int variantIndex,
  required Uri sourceUrl,
}) {
  final extension = p.extension(sourceUrl.path).toLowerCase();
  final safeExtension = RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(extension)
      ? extension
      : '';
  return '${resourceId}_v$variantIndex$safeExtension';
}

String safeDownloadFilename(String filename) {
  var sanitized = filename
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .trim();
  sanitized = sanitized.replaceAll(RegExp(r'[. ]+$'), '');
  if (sanitized.isEmpty) {
    return fallbackDownloadFilename;
  }

  final dotIndex = sanitized.indexOf('.');
  final stem = (dotIndex < 0 ? sanitized : sanitized.substring(0, dotIndex))
      .toUpperCase();
  const reservedNames = {
    'CON',
    'PRN',
    'AUX',
    'NUL',
    'COM1',
    'COM2',
    'COM3',
    'COM4',
    'COM5',
    'COM6',
    'COM7',
    'COM8',
    'COM9',
    'LPT1',
    'LPT2',
    'LPT3',
    'LPT4',
    'LPT5',
    'LPT6',
    'LPT7',
    'LPT8',
    'LPT9',
  };
  if (reservedNames.contains(stem)) {
    sanitized = '_$sanitized';
  }
  return sanitized;
}

Future<String> resolveDesktopDownloadDirectory({
  String? explicitDirectory,
}) async {
  final customDirectory = explicitDirectory ?? SettingsService.downloadPath;
  if (customDirectory != null && customDirectory.isNotEmpty) {
    return p.join(
      customDirectory,
      appDownloadDirectoryName,
      downloadMediaDirectoryName,
    );
  }

  final downloads = await getDownloadsDirectory();
  if (downloads != null) {
    return p.join(
      downloads.path,
      appDownloadDirectoryName,
      downloadMediaDirectoryName,
    );
  }

  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return p.join(
      home,
      'Downloads',
      appDownloadDirectoryName,
      downloadMediaDirectoryName,
    );
  }

  return p.join(
    Directory.current.path,
    appDownloadDirectoryName,
    downloadMediaDirectoryName,
  );
}

Future<String> prepareDesktopCustomDownloadDirectory(
  String selectedDirectory,
) async {
  final directory = Directory(
    p.join(
      selectedDirectory,
      appDownloadDirectoryName,
      downloadMediaDirectoryName,
    ),
  );
  await ensureWritableDirectory(directory);
  return directory.path;
}

Future<Directory> downloadTempDirectory() async {
  final temp = await getTemporaryDirectory();
  final directory = Directory(p.join(temp.path, downloadTempDirectoryName));
  await directory.create(recursive: true);
  return directory;
}

Future<void> ensureWritableDirectory(Directory directory) async {
  try {
    await directory.create(recursive: true);
    final probe = File(
      p.join(
        directory.path,
        '.booruflow-write-test-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await probe.writeAsString('ok', flush: true);
    await probe.delete();
  } catch (error) {
    throw DownloadException('Download directory is not writable', error);
  }
}

Future<void> deleteFileIfExists(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}

Future<File> moveFileWithFallback({
  required File source,
  required File destination,
}) async {
  if (p.equals(source.path, destination.path)) {
    return source;
  }

  await deleteFileIfExists(destination);
  try {
    return await source.rename(destination.path);
  } on FileSystemException catch (renameError) {
    final staging = File(
      p.join(
        destination.parent.path,
        '.${p.basename(destination.path)}.booruflow-${DateTime.now().microsecondsSinceEpoch}.part',
      ),
    );
    try {
      await deleteFileIfExists(staging);
      final copied = await source.copy(staging.path);
      await deleteFileIfExists(destination);
      final saved = await copied.rename(destination.path);
      try {
        await source.delete();
      } catch (_) {
        // The destination is already saved; temp cleanup should not fail the save.
      }
      return saved;
    } catch (copyError) {
      if (await staging.exists()) {
        await staging.delete();
      }
      throw DownloadException(
        'Failed to move file. '
        'source=${source.path}, destination=${destination.path}, staging=${staging.path}, renameError=$renameError, copyError=$copyError',
      );
    }
  }
}

Future<DownloadedFile> writeBytesAtomically({
  required Uint8List bytes,
  required Directory directory,
  required String filename,
}) async {
  await ensureWritableDirectory(directory);

  final destination = File(
    p.join(directory.path, safeDownloadFilename(filename)),
  );
  final partial = File('${destination.path}.part');
  IOSink? sink;
  try {
    await deleteFileIfExists(partial);
    sink = partial.openWrite();
    sink.add(bytes);
    await sink.flush();
    await sink.close();
    sink = null;

    await deleteFileIfExists(destination);
    final saved = await partial.rename(destination.path);
    return DownloadedFile(path: saved.path, bytesWritten: bytes.lengthInBytes);
  } catch (error) {
    if (sink != null) {
      await sink.close();
    }
    if (await partial.exists()) {
      await partial.delete();
    }
    throw DownloadException('Failed to save file', error);
  }
}
