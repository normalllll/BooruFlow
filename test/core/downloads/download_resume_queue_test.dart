import 'dart:async';
import 'package:booruflow/core/downloads/default_download_manager.dart';
import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Engine extends Fake implements DownloadEngine {
  final changes = StreamController<DownloadEngineEvent>.broadcast();
  final states = <String, DownloadStatus>{};
  int resumes = 0, starts = 0;
  @override
  Stream<DownloadEngineEvent> get events => changes.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> acknowledge(Set<String> jobIds) async {}
  @override
  Future<void> dispose() => changes.close();
  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async => [
    for (final entry in states.entries)
      DownloadEngineSnapshot(
        jobId: entry.key,
        status: entry.value,
        saveState: SaveState.none,
        receivedBytes: 400,
        totalBytes: 1000,
        progress: .4,
      ),
  ];
  @override
  Future<void> start(List<DownloadJob> jobs) async {
    for (final job in jobs) {
      if (states[job.id] == DownloadStatus.paused) {
        await resume(job.id);
      } else {
        starts++;
        states[job.id] = DownloadStatus.running;
      }
    }
  }

  @override
  Future<void> pause(String jobId) async {
    states[jobId] = DownloadStatus.paused;
    changes.add(EnginePausedEvent(jobId: jobId));
  }

  @override
  Future<void> resume(String jobId) async {
    resumes++;
    states[jobId] = DownloadStatus.running;
    changes.add(EngineResumedEvent(jobId: jobId, restarted: true));
    changes.add(
      EngineProgressEvent(
        jobId: jobId,
        receivedBytes: 100,
        totalBytes: 1000,
        progress: .1,
      ),
    );
  }

  @override
  Future<void> cancel(String jobId) async {
    states.remove(jobId);
    changes.add(EngineCancelledEvent(jobId: jobId));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DriftDownloadStore store;
  late _Engine engine;
  late DefaultDownloadManager manager;
  setUp(() {
    store = DriftDownloadStore(
      DownloadDatabase(executor: NativeDatabase.memory()),
    );
    engine = _Engine();
    manager = DefaultDownloadManager(
      configuration: DownloadManagerConfiguration(
        maxConcurrentDownloads: () => 1,
      ),
      store: store,
      engine: engine,
      permissionGuard: _Ready(),
    );
  });
  tearDown(() async {
    await manager.dispose();
    await store.close();
  });
  DownloadJob job(int id) => DownloadJob.create(
    resourceId: id,
    variantIndex: 0,
    url: Uri.parse('https://cdn.example/$id.png'),
    filename: '$id.png',
    saveTarget: const SaveTarget.downloadsFolder(),
  );
  Future<void> status(String id, DownloadStatus expected) async {
    for (var i = 0; i < 200; i++) {
      if ((await store.getTask(id))?.status == expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect((await store.getTask(id))?.status, expected);
  }

  test(
    'resume respects concurrency and accepts honest restarted progress',
    () async {
      final first = job(1), second = job(2);
      await manager.enqueue([first, second]);
      await store.updateProgress(
        first.id,
        receivedBytes: 400,
        totalBytes: 1000,
        progress: .4,
      );
      await manager.pause(first.id);
      await status(first.id, DownloadStatus.paused);
      await status(second.id, DownloadStatus.running);
      await manager.resume(first.id);
      expect((await store.getTask(first.id))!.status, DownloadStatus.queued);
      expect(engine.resumes, 0);
      await manager.cancel(second.id);
      await status(first.id, DownloadStatus.running);
      for (
        var i = 0;
        i < 200 && (await store.getTask(first.id))!.progress != .1;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(engine.resumes, 1);
      expect((await store.getTask(first.id))!.progress, .1);
      expect((await store.getTask(first.id))!.receivedBytes, 100);
    },
  );
  test(
    'persisted paused job without a live transfer restarts through the queue',
    () async {
      final first = job(3);
      await store.upsertJob(first);
      await store.updateStatus(first.id, DownloadStatus.paused);
      await store.updateProgress(
        first.id,
        receivedBytes: 400,
        totalBytes: 1000,
        progress: .4,
      );
      await manager.initialize();
      await manager.resume(first.id);
      await status(first.id, DownloadStatus.running);
      expect(engine.starts, 1);
      expect((await store.getTask(first.id))!.receivedBytes, 0);
      expect((await store.getTask(first.id))!.progress, 0);
    },
  );
}

class _Ready implements DownloadPermissionGuard {
  @override
  Future<void> ensureReadyForDownload() async {}
}
