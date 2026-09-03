import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yande_gui/core/downloads/download_file_system.dart';
import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/core/downloads/download_validator.dart';

void main() {
  test('generic filenames retain the resource and variant identifiers', () {
    expect(
      resourceDownloadFilename(
        resourceId: 123456,
        variantIndex: 2,
        sourceUrl: Uri.parse('https://example.test/random-token.JPG?x=1'),
      ),
      '123456_v2.jpg',
    );
  });

  group('DownloadNetworkOptions', () {
    test('normalizes headers and preserves the original host', () {
      final options = const DownloadNetworkOptions(
        headers: {' Referer ': ' https://example.test/ ', 'X-Test': 'one'},
        connectHost: '203.0.113.10',
        disableTlsSni: true,
      ).normalizedFor(Uri.parse('https://images.example.test/path/image.jpg'));

      expect(options.headers, {
        'referer': 'https://example.test/',
        'x-test': 'one',
      });
      expect(options.connectHost, '203.0.113.10');
      expect(options.hostHeader, 'images.example.test');
      expect(options.disableTlsSni, isTrue);
    });

    test('keeps a non-default original port in the Host header', () {
      final options = const DownloadNetworkOptions(
        connectHost: '203.0.113.10',
      ).normalizedFor(Uri.parse('https://images.example.test:8443/file'));
      expect(options.hostHeader, 'images.example.test:8443');
    });

    test('rejects SNI bypass without an explicit connection host', () {
      expect(
        () => const DownloadNetworkOptions(
          disableTlsSni: true,
        ).normalizedFor(Uri.parse('https://example.test/file')),
        throwsArgumentError,
      );
    });

    test('rejects proxy credentials for cross-platform consistency', () {
      expect(
        () => const DownloadNetworkOptions(
          proxyUrl: 'http://user:secret@127.0.0.1:8080',
        ).normalizedFor(Uri.parse('https://example.test/file')),
        throwsArgumentError,
      );
    });
  });

  group('DownloadValidationOptions', () {
    test('rejects malformed checksums before starting', () {
      expect(
        () => const DownloadValidationOptions(
          checksum: DownloadChecksum(
            algorithm: DownloadChecksumAlgorithm.sha256,
            value: 'not-a-sha256',
          ),
        ).normalized(),
        throwsArgumentError,
      );
    });

    test('validates byte count and sha256', () async {
      final bytes = Uint8List.fromList(utf8.encode('freepiv'));
      const checksum =
          '0658cfdbd64fbf6c720f93e5d2ee9fe0ddf5373de3e572b900d539949cc3ff84';
      await validateDownloadedBytes(
        bytes,
        validation: const DownloadValidationOptions(
          expectedBytes: 7,
          checksum: DownloadChecksum(
            algorithm: DownloadChecksumAlgorithm.sha256,
            value: checksum,
          ),
        ),
      );
    });

    test('matches exact and wildcard MIME types', () {
      expect(
        downloadContentTypeMatches('image/jpeg; charset=binary', const [
          'image/*',
        ]),
        isTrue,
      );
      expect(
        downloadContentTypeMatches('application/json', const ['image/*']),
        isFalse,
      );
      expect(downloadContentTypeMatches(null, const ['image/jpeg']), isFalse);
    });
  });
}
