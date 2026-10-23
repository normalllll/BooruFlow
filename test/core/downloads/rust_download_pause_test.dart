import 'dart:async';
import 'dart:io';
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/platform/rust_io_download_engine.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter_test/flutter_test.dart';

class _Rust extends Fake implements BooruEngine {
  _Rust({this.acknowledge = true});
  final bool acknowledge;
  final stream = StreamController<DownloadEvent>.broadcast();
  final started = Completer<void>();
  int pauses = 0, resumes = 0, cancels = 0;
  @override
  Stream<DownloadEvent> downloadToFileStream({
    required DownloadRequest request,
  }) {
    started.complete();
    if (acknowledge) {
      scheduleMicrotask(
        () => stream.add(
          const DownloadEvent.progress(receivedBytesDecimal: '0', progress: 0),
        ),
      );
    }
    return stream.stream;
  }

  @override
  Future<void> pauseDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    UgoiraExport? ugoiraExport,
  }) async {
    pauses++;
    stream.add(const DownloadEvent.paused());
  }

  @override
  Future<void> resumeDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    UgoiraExport? ugoiraExport,
  }) async {
    resumes++;
    stream.add(const DownloadEvent.resumed(restarted: true));
  }

  @override
  Future<void> cancelDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    UgoiraExport? ugoiraExport,
  }) async {
    cancels++;
    stream.addError(StateError('cancelled transfer'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _Rust rust;
  late RustIoDownloadEngine engine;
  late List<DownloadEngineEvent> events;
  late StreamSubscription<DownloadEngineEvent> subscription;
  final job = DownloadJob.create(
    resourceId: 1,
    variantIndex: 0,
    url: Uri.parse('https://cdn.example/1.png'),
    filename: '1.png',
    saveTarget: const SaveTarget.downloadsFolder(),
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('booru-pause-');
    rust = _Rust();
    engine = RustIoDownloadEngine(
      type: DownloadEngineType.desktopRust,
      engine: () => rust,
      temporaryDirectory: () async => directory,
    );
    events = [];
    subscription = engine.events.listen(events.add);
  });
  tearDown(() async {
    await engine.dispose();
    await subscription.cancel();
    await rust.stream.close();
    await directory.delete(recursive: true);
  });
  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(condition(), true);
  }

  test(
    'pause/resume/cancel are real engine calls and retain the owning engine',
    () async {
      expect(engine.capabilities.supportsPauseResume, true);
      final owner = rust;
      await engine.start([job]);
      await owner.started.future;
      owner.stream.add(
        const DownloadEvent.progress(
          receivedBytesDecimal: '400',
          totalBytesDecimal: '1000',
          progress: .4,
        ),
      );
      await until(() => events.whereType<EngineProgressEvent>().isNotEmpty);
      await engine.pause(job.id);
      await until(() => events.whereType<EnginePausedEvent>().isNotEmpty);
      expect(
        (await engine.syncActiveTasks()).single.status,
        DownloadStatus.paused,
      );
      rust =
          _Rust(); // Reconfiguration cannot redirect an active job's commands.
      await engine.start([job]);
      await until(() => events.whereType<EngineResumedEvent>().isNotEmpty);
      expect(owner.resumes, 1);
      expect(rust.resumes, 0);
      expect(events.whereType<EngineResumedEvent>().single.restarted, true);
      expect((await engine.syncActiveTasks()).single.receivedBytes, 0);
      await engine.cancel(job.id);
      await until(() => events.whereType<EngineCancelledEvent>().isNotEmpty);
      expect(owner.cancels, 1);
      expect(await engine.syncActiveTasks(), isEmpty);
      expect(events.whereType<EngineFailedEvent>(), isEmpty);
      await owner.stream.close();
    },
  );
  test(
    'pause requested before Rust registration waits instead of disappearing',
    () async {
      await rust.stream.close();
      rust = _Rust(acknowledge: false);
      await engine.start([job]);
      final pause = engine.pause(job.id);
      await rust.started.future;
      expect(rust.pauses, 0);
      rust.stream.add(
        const DownloadEvent.progress(receivedBytesDecimal: '0', progress: 0),
      );
      await pause;
      await until(() => events.whereType<EnginePausedEvent>().isNotEmpty);
      expect(rust.pauses, 1);
    },
  );
  test('stream failure is handled once without an uncaught Future', () async {
    await engine.start([job]);
    await rust.started.future;
    rust.stream.add(
      const DownloadEvent.failed(
        error: BooruError(
          code: BooruErrorCode.network,
          userMessageKey: 'booru.error.network',
          diagnosticId: 'upstream-failure',
        ),
      ),
    );
    await until(() => events.whereType<EngineFailedEvent>().isNotEmpty);
    await until(() => events.whereType<EngineFailedEvent>().length == 1);
    expect(
      events.whereType<EngineFailedEvent>().single.error,
      contains('upstream-failure'),
    );
    expect(await engine.syncActiveTasks(), isEmpty);
  });
  test('disposing paused transfer cancels it and finishes cleanly', () async {
    await engine.start([job]);
    await rust.started.future;
    await engine.pause(job.id);
    await until(() => events.whereType<EnginePausedEvent>().isNotEmpty);
    await engine.dispose();
    expect(rust.cancels, 1);
    expect(await engine.syncActiveTasks(), isEmpty);
  });
}
