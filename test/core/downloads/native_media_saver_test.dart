import 'dart:io';

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/downloads/platform/native_download_engine.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('booruflow/download_engine');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  DownloadJob job(String ext, {UgoiraExport? format}) => DownloadJob.create(
    resourceId: 1,
    variantIndex: 0,
    url: Uri.parse('https://cdn.example/source.$ext'),
    filename: '1.$ext',
    ugoiraExport: format,
    saveTarget: const SaveTarget.mediaStore(),
    validation: const DownloadValidationOptions(
      expectedBytes: 1000,
      checksum: DownloadChecksum(
        algorithm: DownloadChecksumAlgorithm.md5,
        value: '9936e9e3a38869ebe2a2dfbc507c5323',
      ),
    ),
  );
  test(
    'converted WebP uses output length; original ZIP and video keep source validation',
    () async {
      for (final format in [
        UgoiraExport.losslessWebp,
        UgoiraExport.originalZip,
        null,
      ]) {
        final task = job(
          format == UgoiraExport.losslessWebp
              ? 'webp'
              : format == null
              ? 'mp4'
              : 'zip',
          format: format,
        );
        messenger.setMockMethodCallHandler(channel, (call) async {
          final value = (call.arguments as Map)['job'] as Map;
          final validation = value['validation'] as Map;
          expect(
            validation['expectedBytes'],
            format == UgoiraExport.losslessWebp ? 500 : 1000,
          );
          if (format == UgoiraExport.losslessWebp) {
            expect(validation['checksum'], isNull);
          } else {
            expect(validation['checksum'], isNotNull);
          }
          return {'path': 'content://result', 'bytesWritten': 500};
        });
        final result = await NativeMediaSaver().saveDownloadedFile(
          job: task,
          file: const DownloadedFile(path: 'test-file', bytesWritten: 500),
        );
        expect(result.bytesWritten, 500);
      }
    },
  );
  test(
    'iOS archives and explicit animation exports use Files; MP4 remains media',
    () {
      for (final ext in ['zip', 'webm', 'swf', 'bin', 'webp', 'unknown']) {
        expect(DownloadPlatform.ios.usesFiles(job(ext)), true);
      }
      expect(
        DownloadPlatform.ios.usesFiles(
          job('webp', format: UgoiraExport.losslessWebp),
        ),
        true,
      );
      for (final ext in ['mp4', 'png', 'gif', 'jpg']) {
        expect(DownloadPlatform.ios.usesFiles(job(ext)), false);
      }
    },
  );
  for (final access in IosPhotosReadAccess.values) {
    test(
      'single iOS photo observes $access without requesting read access',
      () async {
        final calls = <String>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'photosReadAccess') return access.name;
          expect(call.method, 'saveFile');
          expect(
            ((call.arguments as Map)['job'] as Map)['prefersDefaultAlbum'],
            access == IosPhotosReadAccess.authorized,
          );
          return {'path': 'ph://saved', 'bytesWritten': 500};
        });
        await NativeMediaSaver(
          platform: DownloadPlatform.fromTargetPlatform(TargetPlatform.iOS),
        ).saveDownloadedFile(
          job: job('png'),
          file: const DownloadedFile(path: 'photo', bytesWritten: 500),
        );
        expect(calls, ['photosReadAccess', 'saveFile']);
      },
    );
  }
  test(
    'iOS original-file save never queries or requests Photos permission',
    () async {
      final root = await Directory.systemTemp.createTemp('r7-ios-files-');
      addTearDown(() => root.delete(recursive: true));
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return null;
      });
      for (final ext in ['webp', 'zip', 'webm', 'swf', 'unknown']) {
        final source = File('${root.path}/source.$ext');
        await source.writeAsBytes([1, 2, 3]);
        final result =
            await NativeMediaSaver(
              platform: DownloadPlatform.ios,
              documentsDirectory: () async =>
                  Directory('${root.path}/Documents'),
            ).saveDownloadedFile(
              job: job(ext),
              file: DownloadedFile(path: source.path, bytesWritten: 3),
            );
        expect(await File(result.path).readAsBytes(), [1, 2, 3]);
        expect(result.path, contains('BooruFlow'));
      }
      expect(calls, 0);
    },
  );
  test(
    'denied add-only request does not escalate or open settings implicitly',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'prepareForDownload') {
          throw PlatformException(code: 'permission_denied');
        }
        return true;
      });
      const guard = NativeDownloadPermissionGuard();
      for (var i = 0; i < 2; i++) {
        await expectLater(
          guard.ensureReadyForDownload(),
          throwsA(isA<DownloadPermissionDenied>()),
        );
      }
      expect(calls, ['prepareForDownload', 'prepareForDownload']);
      await NativeDownloadPermissionGuard.openAppSettings();
      expect(calls.last, 'openAppSettings');
    },
  );
}
