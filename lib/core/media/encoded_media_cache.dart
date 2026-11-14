import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:path/path.dart' as path;

/// The encoded images kept on disk between runs; trimmed from startup.
final appPictureStore = MediaDiskCache.forApp();

/// Encoded images shared by display, original-file saving and the clipboard,
/// kept in [store]. The Rust cache key includes the URL, account and route
/// revisions.
///
/// Display reads an image as it was written: the store publishes a file whole,
/// and one that fails to decode is removed by its reader. Saving and the
/// clipboard hand the bytes on without decoding them, so they also need the
/// proof written beside each image: a fingerprint of its bytes with its MIME
/// type, and never credentials. The proof is an entry of its own, so a trim
/// may remove it before its image; saving then fetches the file again.
class EncodedMediaCache {
  const EncodedMediaCache({this._store});
  final MediaDiskCache? _store;
  MediaDiskCache get store => _store ?? appPictureStore;

  static String _proofKey(MediaRequest request) =>
      '${request.cacheKey}.verified';

  Future<File> _file(MediaRequest request) async => File(
    path.join((await store.directory).path, store.fileNameOf(request.cacheKey)),
  );

  Future<Map<String, Object?>?> _proof(MediaRequest request) async {
    final bytes = await store.read(_proofKey(request));
    if (bytes == null) return null;
    final proof = jsonDecode(utf8.decode(bytes));
    return proof is Map<String, Object?> &&
            proof['version'] == 1 &&
            proof['complete'] == true
        ? proof
        : null;
  }

  Future<Uint8List?> read(MediaRequest request) async =>
      request.allowDiskCache ? store.read(request.cacheKey) : null;

  Future<void> remove(MediaRequest request) async {
    if (!request.allowDiskCache) return;
    await store.remove(_proofKey(request));
    await store.remove(request.cacheKey);
  }

  /// Called only after a complete transfer and a successful first-frame decode.
  Future<void> write(MediaRequest request, Uint8List bytes) async {
    if (!request.allowDiskCache) return;
    try {
      // A proof left by earlier bytes must not vouch for these.
      await store.remove(_proofKey(request));
      await store.write(request.cacheKey, bytes);
      final location = (await _file(request)).path;
      final fingerprint = await Isolate.run(() => _fingerprint(location));
      // Publish the fingerprint last. A concurrent replacement can only cause
      // a cache miss; it cannot make mismatched bytes pass validation.
      await store.write(
        _proofKey(request),
        utf8.encode(jsonEncode(fingerprint)),
      );
    } on FileSystemException {
      /* Display success does not depend on caching. */
    }
  }

  /// Copies original encoded bytes without decoding or re-encoding. An image
  /// without its proof is not trusted for export. The destination is validated
  /// on a worker after the asynchronous OS copy.
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
      final metadata = await _proof(request);
      if (metadata == null || metadata['mime'] != mimeType) return false;
      final source = await _file(request);
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
      /* An interrupted proof is a cache miss. */
    }
    if (await destination.exists()) await destination.delete();
    return false;
  }

  /// A PNG accepted by the clipboard can bypass another engine PNG encode.
  /// Validation runs in the worker; no full-byte work is done on the UI isolate.
  Future<Uint8List?> readPng(MediaRequest request) async {
    if (!request.allowDiskCache) return null;
    try {
      final metadata = await _proof(request);
      if (metadata == null || metadata['mime'] != 'image/png') return null;
      final location = (await _file(request)).path;
      final transferred = await Isolate.run(() async {
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
      Iterable<int>.generate(marker.length)
          .every((i) => tail[tail.length - marker.length + i] == marker[i]);
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
