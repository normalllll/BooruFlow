import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:extended_image/extended_image.dart'
    show cacheImageFolderName, keyToMd5;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Encoded images shared by display, original-file saving and the clipboard.
/// The Rust cache key includes the URL, account and route revisions. Metadata
/// contains only a byte fingerprint and MIME type; credentials are never stored.
class EncodedMediaCache {
  const EncodedMediaCache({this.file, this.temporaryDirectory});
  final File? file;
  final Future<Directory> Function()? temporaryDirectory;
  Future<File> _file(MediaRequest request) async {
    if (file != null) return file!;
    final temp = await (temporaryDirectory?.call() ?? getTemporaryDirectory());
    final directory = Directory(path.join(temp.path, cacheImageFolderName));
    await directory.create(recursive: true);
    return File(path.join(directory.path, keyToMd5(request.cacheKey)));
  }

  Future<Uint8List?> read(MediaRequest request) async {
    if (!request.allowDiskCache) return null;
    try {
      final source = await _file(request);
      final proof = jsonDecode(
        await File('${source.path}.verified').readAsString(),
      );
      if (proof is! Map ||
          proof['version'] != 1 ||
          proof['complete'] != true ||
          proof['length'] != await source.length()) {
        return null;
      }
      return await source.readAsBytes();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<void> remove(MediaRequest request) async {
    if (!request.allowDiskCache) return;
    try {
      final source = await _file(request);
      for (final item in [File('${source.path}.verified'), source]) {
        if (await item.exists()) await item.delete();
      }
    } on FileSystemException {
      /* A cache miss must not prevent a retry. */
    }
  }

  /// Called only after a complete transfer and a successful first-frame decode.
  Future<void> write(MediaRequest request, Uint8List bytes) async {
    if (!request.allowDiskCache) return;
    Directory? staging;
    try {
      final destination = await _file(request);
      staging = await destination.parent.createTemp('.image-');
      final temporary = File(path.join(staging.path, 'data'));
      await temporary.writeAsBytes(bytes, flush: true);
      final location = temporary.path;
      final fingerprint = await Isolate.run(() => _fingerprint(location));
      final metadata = File(path.join(staging.path, 'verified'));
      await metadata.writeAsString(jsonEncode(fingerprint), flush: true);
      await temporary.rename(destination.path);
      // Publish the fingerprint last. A concurrent replacement can only cause
      // a cache miss; it cannot make mismatched bytes pass validation.
      await metadata.rename('${destination.path}.verified');
    } on FileSystemException {
      /* Display success does not depend on caching. */
    } finally {
      if (staging != null) {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException {
          /* Best effort. */
        }
      }
    }
  }

  /// Copies original encoded bytes without decoding or re-encoding. Legacy
  /// display cache entries without a fingerprint are not trusted for export.
  /// The destination is validated on a worker after the asynchronous OS copy.
  Future<bool> copyOriginal(
    MediaRequest request,
    File destination, {
    required String mimeType,
    int? expectedBytes,
    String? md5,
    String? sha256,
    void Function()? onCopyStarted,
  }) async {
    if (!request.allowDiskCache) return false;
    try {
      final source = await _file(request);
      final metadata =
          jsonDecode(await File('${source.path}.verified').readAsString())
              as Map<String, Object?>;
      if (metadata['mime'] != mimeType ||
          metadata['version'] != 1 ||
          metadata['complete'] != true) {
        return false;
      }
      onCopyStarted?.call();
      await source.copy(destination.path);
      final copiedPath = destination.path;
      final valid = await Isolate.run(() async {
        final actual = await _fingerprint(copiedPath);
        if (actual['length'] != metadata['length'] ||
            actual['sha256'] != metadata['sha256'] ||
            actual['mime'] != mimeType) {
          return false;
        }
        if (expectedBytes != null && actual['length'] != expectedBytes) {
          return false;
        }
        if (sha256 != null && actual['sha256'] != sha256.toLowerCase()) {
          return false;
        }
        if (md5 != null &&
            (await crypto.md5.bind(File(copiedPath).openRead()).first)
                    .toString() !=
                md5.toLowerCase()) {
          return false;
        }
        return true;
      });
      if (valid) return true;
    } on FileSystemException {
      /* Missing/evicted entries fall back to transport. */
    } on FormatException {
      /* Old or interrupted metadata is a cache miss. */
    } on TypeError {
      /* Malformed cache metadata is a cache miss. */
    }
    if (await destination.exists()) await destination.delete();
    return false;
  }

  /// A PNG accepted by the clipboard can bypass another engine PNG encode.
  /// Validation runs in the worker; no full-byte work is done on the UI isolate.
  Future<Uint8List?> readPng(MediaRequest request) async {
    if (!request.allowDiskCache) return null;
    try {
      final source = await _file(request);
      final location = source.path;
      final transferred = await Isolate.run(() async {
        final metadata =
            jsonDecode(await File('$location.verified').readAsString())
                as Map<String, Object?>;
        if (metadata['version'] != 1 ||
            metadata['mime'] != 'image/png' ||
            metadata['complete'] != true) {
          return null;
        }
        final bytes = await File(location).readAsBytes();
        if (bytes.length != metadata['length'] ||
            crypto.sha256.convert(bytes).toString() != metadata['sha256'] ||
            _imageMime(bytes) != 'image/png') {
          return null;
        }
        return TransferableTypedData.fromList([bytes]);
      });
      return transferred?.materialize().asUint8List();
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

Future<Map<String, Object?>> _fingerprint(String location) async {
  final file = File(location);
  final length = await file.length();
  final header = await file.open();
  late Uint8List bytes, tail;
  try {
    bytes = await header.read(32);
    await header.setPosition(length > 12 ? length - 12 : 0);
    tail = await header.read(12);
  } finally {
    await header.close();
  }
  final mime = _imageMime(bytes);
  return {
    'version': 1,
    'length': length,
    'mime': mime,
    'complete': _completeImage(mime, bytes, tail, length),
    'sha256': (await crypto.sha256.bind(file.openRead()).first).toString(),
  };
}

String? _imageMime(Uint8List bytes) {
  bool starts(List<int> magic) =>
      bytes.length >= magic.length &&
      Iterable<int>.generate(magic.length).every((i) => bytes[i] == magic[i]);
  if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
  if (starts([255, 216, 255])) return 'image/jpeg';
  if (starts([71, 73, 70, 56])) return 'image/gif';
  if (starts([82, 73, 70, 70]) &&
      bytes.length >= 12 &&
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
    return 'image/webp';
  }
  if (starts([66, 77])) return 'image/bmp';
  if (bytes.length >= 12 &&
      ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp' &&
      {
        'avif',
        'avis',
      }.contains(ascii.decode(bytes.sublist(8, 12), allowInvalid: true))) {
    return 'image/avif';
  }
  return null;
}

/// The expected format comes from the download filename, never a preview codec.
String? encodedImageMimeForExtension(String extension) =>
    switch (extension.toLowerCase()) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.avif' => 'image/avif',
      '.bmp' => 'image/bmp',
      _ => null,
    };

bool _completeImage(String? mime, Uint8List head, Uint8List tail, int length) {
  bool ends(List<int> marker) =>
      tail.length >= marker.length &&
      Iterable<int>.generate(
        marker.length,
      ).every((i) => tail[tail.length - marker.length + i] == marker[i]);
  return switch (mime) {
    'image/jpeg' => ends([255, 217]),
    'image/png' => ends([0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130]),
    'image/gif' => ends([59]),
    'image/webp' =>
      head.length >= 12 &&
          ByteData.sublistView(head).getUint32(4, Endian.little) + 8 == length,
    'image/bmp' =>
      head.length >= 6 &&
          ByteData.sublistView(head).getUint32(2, Endian.little) == length,
    _ => false,
  };
}
