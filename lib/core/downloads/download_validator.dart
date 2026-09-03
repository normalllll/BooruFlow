import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'download_models.dart';

Future<void> validateDownloadedFile(
  File file, {
  required DownloadValidationOptions validation,
}) async {
  if (!await file.exists()) {
    throw DownloadException('Downloaded file does not exist: ${file.path}');
  }
  final bytesWritten = await file.length();
  _validateLength(bytesWritten, validation.expectedBytes);
  final checksum = validation.checksum;
  if (checksum == null) {
    return;
  }
  final digest = await _digestStream(file.openRead(), checksum.algorithm);
  _validateDigest(digest, checksum);
}

Future<void> validateDownloadedBytes(
  Uint8List bytes, {
  required DownloadValidationOptions validation,
}) async {
  _validateLength(bytes.lengthInBytes, validation.expectedBytes);
  final checksum = validation.checksum;
  if (checksum == null) {
    return;
  }
  final digest = _digestBytes(bytes, checksum.algorithm);
  _validateDigest(digest, checksum);
}

bool downloadContentTypeMatches(
  String? contentType,
  List<String> allowedContentTypes,
) {
  if (allowedContentTypes.isEmpty) {
    return true;
  }
  final actual = contentType?.split(';').first.trim().toLowerCase();
  if (actual == null || actual.isEmpty) {
    return false;
  }
  return allowedContentTypes.any((allowed) {
    final normalized = allowed.trim().toLowerCase();
    if (normalized.endsWith('/*')) {
      return actual.startsWith(normalized.substring(0, normalized.length - 1));
    }
    return actual == normalized;
  });
}

void _validateLength(int actual, int? expected) {
  if (actual <= 0) {
    throw const DownloadException('Downloaded file is empty.');
  }
  if (expected != null && actual != expected) {
    throw DownloadException(
      'Downloaded byte count mismatch: expected $expected, got $actual.',
    );
  }
}

Future<String> _digestStream(
  Stream<List<int>> stream,
  DownloadChecksumAlgorithm algorithm,
) async {
  final digests = switch (algorithm) {
    DownloadChecksumAlgorithm.md5 => crypto.md5.bind(stream),
    DownloadChecksumAlgorithm.sha256 => crypto.sha256.bind(stream),
  };
  return (await digests.first).toString();
}

String _digestBytes(List<int> bytes, DownloadChecksumAlgorithm algorithm) {
  return switch (algorithm) {
    DownloadChecksumAlgorithm.md5 => crypto.md5.convert(bytes).toString(),
    DownloadChecksumAlgorithm.sha256 => crypto.sha256.convert(bytes).toString(),
  };
}

void _validateDigest(String actual, DownloadChecksum expected) {
  if (actual.toLowerCase() != expected.value.toLowerCase()) {
    throw DownloadException(
      'Downloaded ${expected.algorithm.name} checksum mismatch: expected ${expected.value}, got $actual.',
    );
  }
}
