import 'package:booruflow/core/downloads/default_download_manager.dart';
import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:booruflow/core/downloads/media_saver.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('booruflow/download_engine');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late DefaultDownloadManager manager;
  late DriftDownloadStore store;
  late List<String> calls;
  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    store = DriftDownloadStore(
      DownloadDatabase(executor: NativeDatabase.memory()),
    );
    manager = DefaultDownloadManager(
      configuration: DownloadManagerConfiguration(
        maxConcurrentDownloads: () => 2,
      ),
      store: store,
      engine: _IdleEngine(),
      mediaSaver: _Saver(),
      permissionGuard: const NativeDownloadPermissionGuard(),
      platform: DownloadPlatform.fromTargetPlatform(TargetPlatform.iOS),
    );
  });
  tearDown(() async {
    await manager.dispose();
    await store.close();
    messenger.setMockMethodCallHandler(channel, null);
  });
  for (final extension in ['webp', 'zip', 'png', 'mp4']) {
    test(
      'saving $extension bytes requests only the relevant iOS permission',
      () async {
        await manager.saveBytes(
          resourceId: 1,
          variantIndex: 0,
          bytes: Uint8List.fromList([1, 2, 3]),
          sourceUrl: Uri.parse('https://example.com/1.$extension'),
          filename: '1.$extension',
        );
        expect(
          calls,
          ['png', 'mp4'].contains(extension) ? ['prepareForDownload'] : isEmpty,
        );
      },
    );
    for (final batch in [false, true]) {
      test(
        'enqueue $extension batch=$batch does not broaden single-photo access',
        () async {
          await manager.enqueue([
            DownloadJob.create(
              resourceId: 1,
              variantIndex: 0,
              batchId: batch ? 'batch' : null,
              url: Uri.parse('https://example.com/1.$extension'),
              filename: '1.$extension',
              saveTarget: const SaveTarget.photos(subdirectory: 'batch'),
            ),
          ]);
          expect(
            calls,
            ['png', 'mp4'].contains(extension)
                ? [batch ? 'prepareForBatchDownload' : 'prepareForDownload']
                : isEmpty,
          );
        },
      );
    }
  }
}

class _IdleEngine extends Fake implements DownloadEngine {
  @override
  DownloadEngineType get type => DownloadEngineType.iosUrlSession;
  @override
  DownloadCapabilities get capabilities => const DownloadCapabilities(
    supportsBackground: false,
    supportsCancel: true,
    supportsPauseResume: false,
    handlesSaving: false,
    supportsHeaders: true,
    supportsProxy: true,
    supportsHostOverride: true,
    supportsCertificateBypass: true,
    supportsValidation: true,
  );
  @override
  Stream<DownloadEngineEvent> get events => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async => [];
  @override
  Future<void> acknowledge(Set<String> jobIds) async {}
  @override
  Future<void> start(List<DownloadJob> jobs) async {}
  @override
  Future<void> dispose() async {}
}

class _Saver extends Fake implements MediaSaver {
  @override
  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  }) async => SaveResult(path: 'saved', bytesWritten: bytes.length);
}
