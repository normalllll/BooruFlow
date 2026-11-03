import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:booruflow/core/downloads/default_download_manager.dart';
import 'package:booruflow/core/downloads/download_database.dart'
    hide DownloadJob;
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:booruflow/core/downloads/media_saver.dart';
import 'package:booruflow/core/downloads/platform/rust_io_download_engine.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Follows the Rust engine's contract: a job it does not hold is a no-op.
class _Engine extends Fake implements DownloadEngine {
  final changes = StreamController<DownloadEngineEvent>.broadcast();
  final running = <String, DownloadStatus>{};
  final acknowledged = <String>{};
  Set<String>? kept;
  Completer<void>? holdStart;

  @override
  DownloadCapabilities get capabilities => const DownloadCapabilities(
    supportsBackground: false,
    supportsCancel: true,
    supportsPauseResume: true,
    handlesSaving: false,
    supportsHeaders: true,
    supportsProxy: true,
    supportsHostOverride: true,
    supportsCertificateBypass: true,
    supportsValidation: true,
  );
  @override
  Stream<DownloadEngineEvent> get events => changes.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> acknowledge(Set<String> jobIds) async =>
      acknowledged.addAll(jobIds);
  @override
  Future<void> removeLeftovers(Set<String> keepJobIds) async =>
      kept = keepJobIds;
  @override
  Future<void> dispose() => changes.close();
  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async => [
    for (final entry in running.entries)
      DownloadEngineSnapshot(
        jobId: entry.key,
        status: entry.value,
        saveState: SaveState.none,
        receivedBytes: 1,
        totalBytes: 10,
        progress: .1,
      ),
  ];
  @override
  Future<void> start(List<DownloadJob> jobs) async {
    await holdStart?.future;
    for (final job in jobs) {
      if (running[job.id] == DownloadStatus.paused) {
        changes.add(EngineResumedEvent(jobId: job.id, restarted: false));
      }
      running[job.id] = DownloadStatus.running;
    }
  }

  @override
  Future<void> pause(String jobId) async {
    if (!running.containsKey(jobId)) return;
    running[jobId] = DownloadStatus.paused;
    changes.add(EnginePausedEvent(jobId: jobId));
  }

  @override
  Future<void> cancel(String jobId) async {
    if (running.remove(jobId) == null) return;
    changes.add(EngineCancelledEvent(jobId: jobId));
  }

  void complete(String id, {String? path}) {
    running.remove(id);
    changes.add(
      EngineCompletedEvent(
        jobId: id,
        localPath: path ?? '/tmp/$id',
        bytesWritten: 10,
      ),
    );
  }

  void progress(String id, double value) => changes.add(
    EngineProgressEvent(
      jobId: id,
      receivedBytes: 5,
      totalBytes: 10,
      progress: value,
    ),
  );
}

class _Saver implements MediaSaver {
  final holds = <String, Completer<void>>{};
  final names = <String>[];
  @override
  Future<SaveResult> saveDownloadedFile({
    required DownloadJob job,
    required DownloadedFile file,
  }) async {
    names.add(job.filename);
    await holds[job.id]?.future;
    return SaveResult(path: '/saved/${job.id}', bytesWritten: 10);
  }

  @override
  Future<SaveResult> saveBytes({
    required DownloadJob job,
    required Uint8List bytes,
  }) async => SaveResult(path: '/saved/${job.id}', bytesWritten: bytes.length);
}

class _Ready implements DownloadPermissionGuard {
  @override
  Future<void> ensureReadyForDownload() async {}
}

class _NoBooru extends Fake implements BooruEngine {}

Future<void> _settle([int milliseconds = 120]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DriftDownloadStore store;
  late _Engine engine;
  late _Saver saver;
  late DefaultDownloadManager manager;

  DefaultDownloadManager create(int slots) => DefaultDownloadManager(
    configuration: DownloadManagerConfiguration(
      maxConcurrentDownloads: () => slots,
    ),
    store: store,
    engine: engine,
    mediaSaver: saver,
    permissionGuard: _Ready(),
  );

  setUp(() {
    store = DriftDownloadStore(
      DownloadDatabase(executor: NativeDatabase.memory()),
    );
    engine = _Engine();
    saver = _Saver();
  });
  tearDown(() async {
    await manager.dispose();
    await store.close();
  });

  Future<void> make(int slots) async {
    manager = create(slots);
    await manager.initialize();
  }

  DownloadJob job(int id) => DownloadJob.create(
    resourceId: id,
    variantIndex: 0,
    url: Uri.parse('https://cdn.example/$id.png'),
    filename: '$id.png',
    saveTarget: const SaveTarget.downloadsFolder(),
  );
  Future<DownloadStatus?> status(DownloadJob value) async =>
      (await store.getTask(value.id))?.status;

  test('events keep flowing after a save completes', () async {
    await make(2);
    final first = job(1), second = job(2);
    await manager.enqueue([first, second]);
    engine.complete(first.id);
    await _settle();
    engine.progress(second.id, .5);
    await _settle();
    expect((await store.getTask(second.id))?.progress, .5);
    engine.complete(second.id);
    await _settle();
    expect((await store.getTask(second.id))?.saveState, SaveState.saved);
  });

  test('a long save does not hold up other tasks', () async {
    await make(2);
    final first = job(1), second = job(2);
    await manager.enqueue([first, second]);
    final hold = Completer<void>();
    saver.holds[first.id] = hold;
    engine.complete(first.id);
    await _settle();
    engine.progress(second.id, .5);
    await _settle();
    expect((await store.getTask(second.id))?.progress, .5);
    hold.complete();
  });

  test('sync leaves a finished task alone while its event waits', () async {
    await make(2);
    final first = job(1), second = job(2);
    await manager.enqueue([first, second]);
    final hold = Completer<void>();
    saver.holds[first.id] = hold;
    engine.complete(first.id);
    engine.complete(second.id);
    await manager.sync();
    hold.complete();
    await _settle(250);
    expect(await status(second), DownloadStatus.downloaded);
    expect((await store.getTask(second.id))?.saveState, SaveState.saved);
  });

  test('sync leaves a task alone while it is starting', () async {
    await make(1);
    final only = job(1);
    engine.holdStart = Completer<void>();
    unawaited(manager.enqueue([only]));
    await _settle();
    await manager.sync();
    expect(await status(only), DownloadStatus.running);
    engine.holdStart!.complete();
    await _settle();
  });

  test('launch still fails a running row left by the old process', () async {
    final stale = job(1);
    await store.upsertJob(stale);
    await store.updateStatus(stale.id, DownloadStatus.running);
    await make(1);
    expect(await status(stale), DownloadStatus.failed);
  });

  test('a queued task can be paused and resumed', () async {
    await make(1);
    final first = job(1), second = job(2);
    await manager.enqueue([first, second]);
    await manager.pause(second.id);
    expect(await status(second), DownloadStatus.paused);
    await manager.resume(second.id);
    expect(await status(second), DownloadStatus.queued);
  });

  group('a resumed task waiting for a slot', () {
    late DownloadJob first, second;
    setUp(() async {
      await make(1);
      first = job(1);
      second = job(2);
      await manager.enqueue([first, second]);
      await manager.pause(first.id);
      await _settle();
      await manager.resume(first.id);
      await _settle();
    });

    test('cancel ends the transfer and stays cancelled', () async {
      await manager.cancel(first.id);
      await _settle();
      expect(engine.running.containsKey(first.id), isFalse);
      await manager.sync();
      await _settle();
      expect(await status(first), DownloadStatus.cancelled);
    });

    test('delete ends the transfer', () async {
      await manager.deleteTask(first.id);
      await _settle();
      expect(engine.running.containsKey(first.id), isFalse);
      expect(engine.acknowledged, contains(first.id));
    });

    test('sync does not undo the resume', () async {
      await manager.sync();
      await _settle();
      expect(await status(first), DownloadStatus.queued);
    });
  });

  test('cancel works on a task paused before a restart', () async {
    final paused = job(1);
    await store.upsertJob(paused);
    await store.updateStatus(paused.id, DownloadStatus.paused);
    await make(1);
    await manager.cancel(paused.id);
    expect(await status(paused), DownloadStatus.cancelled);
  });

  test('a failed saveBytes leaves no task to download', () async {
    await make(1);
    await expectLater(
      manager.saveBytes(
        resourceId: 9,
        variantIndex: 0,
        bytes: Uint8List(3),
        sourceUrl: Uri.parse('https://cdn.example/9.png'),
        filename: '9.png',
        validation: const DownloadValidationOptions(expectedBytes: 10),
      ),
      throwsA(anything),
    );
    expect(await store.listTasks(), isEmpty);
  });

  test('one media item transfers once; the other job waits', () async {
    await make(2);
    DownloadJob same(String? batch) => DownloadJob.create(
      resourceId: 1,
      sourceId: 'yande',
      postId: '7',
      variantIndex: 0,
      url: Uri.parse('https://cdn.example/7.png'),
      filename: '7.png',
      saveTarget: const SaveTarget.downloadsFolder(),
      batchId: batch,
    );
    final single = same(null), batched = same('b1');
    await manager.enqueue([single, batched]);
    expect(engine.running.keys, [single.id]);
    expect(await status(batched), DownloadStatus.queued);
    engine.complete(single.id);
    await _settle();
    expect(engine.running.keys, [batched.id]);
  });

  test('a saved task releases its temporary files', () async {
    await make(1);
    final only = job(1);
    await manager.enqueue([only]);
    engine.complete(only.id);
    await _settle();
    expect(engine.acknowledged, contains(only.id));
  });

  test('launch keeps only the files of saves still to finish', () async {
    final waiting = job(1), retry = job(2), done = job(3);
    for (final value in [waiting, retry, done]) {
      await store.upsertJob(value);
      await store.updateStatus(value.id, DownloadStatus.downloaded);
    }
    await store.updateSaveState(retry.id, SaveState.failed, localPath: '/t/r');
    await store.updateSaveState(done.id, SaveState.saved, localPath: '/d/x');
    await store.updateSaveState(waiting.id, SaveState.saving);
    await make(1);
    await _settle();
    expect(engine.kept, contains(retry.id));
    expect(engine.kept, isNot(contains(done.id)));
  });

  test('the verified file type names the saved file', () async {
    await make(1);
    final only = job(1);
    await manager.enqueue([only]);
    engine.complete(only.id, path: '/tmp/${only.id}/1.jpg');
    await _settle();
    expect(saver.names, ['1.jpg']);
  });

  group('without the manager', () {
    setUp(() => make(1));

    test('downloadedFilename treats both JPEG spellings as one', () {
      expect(downloadedFilename('a.jpeg', '/t/a.jpg'), 'a.jpeg');
      expect(downloadedFilename('a.jpg', '/t/a.png'), 'a.png');
      expect(downloadedFilename('a.png', '/t/a.png.part'), 'a.png');
      expect(downloadedFilename('a.png', '/t/a'), 'a.png');
    });

    test('a failed move keeps the existing file', () async {
      final directory = await Directory.systemTemp.createTemp('bf-move-');
      addTearDown(() => directory.delete(recursive: true));
      final destination = File(p.join(directory.path, 'a.png'))
        ..writeAsStringSync('old');
      await expectLater(
        moveFileWithFallback(
          source: File(p.join(directory.path, 'missing.tmp')),
          destination: destination,
        ),
        throwsA(anything),
      );
      expect(destination.readAsStringSync(), 'old');
    });

    test('a successful move replaces the existing file', () async {
      final directory = await Directory.systemTemp.createTemp('bf-move-');
      addTearDown(() => directory.delete(recursive: true));
      final source = File(p.join(directory.path, 'new.tmp'))
        ..writeAsStringSync('new');
      final destination = File(p.join(directory.path, 'a.png'))
        ..writeAsStringSync('old');
      await moveFileWithFallback(source: source, destination: destination);
      expect(destination.readAsStringSync(), 'new');
      expect(source.existsSync(), isFalse);
    });

  });

  group('the Rust engine', () {
    late Directory root;
    late RustIoDownloadEngine rust;
    setUp(() async {
      await make(1);
      root = await Directory.systemTemp.createTemp('bf-engine-');
      rust = RustIoDownloadEngine(
        type: DownloadEngineType.desktopRust,
        engine: _NoBooru.new,
        temporaryDirectory: () async => root,
      );
    });
    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    test('a locked partial file still reports the failure', () async {
      final only = job(1);
      final directory = Directory(p.join(root.path, only.id))..createSync();
      final locked = File(p.join(directory.path, '1.png.part'))
        ..writeAsStringSync('x');
      final handle = locked.openSync(mode: FileMode.append);
      addTearDown(handle.closeSync);
      final events = <DownloadEngineEvent>[];
      final subscription = rust.events.listen(events.add);
      addTearDown(subscription.cancel);
      await rust.start([only]);
      await _settle(400);
      expect(events.whereType<EngineFailedEvent>(), hasLength(1));
    }, skip: Platform.isWindows ? false : 'Only Windows locks open files');

    test('acknowledge removes the job directory', () async {
      final directory = Directory(p.join(root.path, 'job'))..createSync();
      File(p.join(directory.path, 'a.png')).writeAsStringSync('x');
      await rust.acknowledge({'job'});
      expect(directory.existsSync(), isFalse);
    });

    test('removeLeftovers spares the kept jobs', () async {
      final kept = Directory(p.join(root.path, 'keep'))..createSync();
      final keptBytes = File(p.join(root.path, 'keep-a.png'))
        ..writeAsStringSync('x');
      final stale = Directory(p.join(root.path, 'stale'))..createSync();
      await rust.removeLeftovers({'keep'});
      expect(kept.existsSync(), isTrue);
      expect(keptBytes.existsSync(), isTrue);
      expect(stale.existsSync(), isFalse);
    });
  });
}
