import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/platform/rust_io_download_engine.dart';
import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_test/flutter_test.dart';

const originalRequest = MediaRequest(
  sourceId: 'source',
  postId: '1',
  variant: MediaVariantKind.original,
  url: 'https://cdn.example/1.png',
  headers: [],
  routeKey: 'route',
  cacheKey: 'account0-route0',
  authRevision: 0,
  routeRevision: '0',
  allowDiskCache: true,
);

class _Rust extends Fake implements BooruEngine {
  _Rust(this.png);
  final Uint8List png;
  int requests = 0, prepared = 0, pauses = 0, resumes = 0, cancels = 0;
  bool changeAccount = false;
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) async {
    prepared++;
    return changeAccount && prepared > 1
        ? const MediaRequest(
            sourceId: 'source',
            postId: '1',
            variant: MediaVariantKind.original,
            url: 'https://cdn.example/1.png',
            headers: [],
            routeKey: 'route',
            cacheKey: 'account1-route0',
            authRevision: 1,
            routeRevision: '0',
            allowDiskCache: true,
          )
        : originalRequest;
  }

  @override
  Stream<DownloadEvent> downloadToFileStream({
    required DownloadRequest request,
  }) async* {
    requests++;
    final file = File('${request.downloadRoot}/rust-original.png');
    await file.writeAsBytes(png);
    yield DownloadEvent.done(path: file.path);
  }

  @override
  Future<void> pauseDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    UgoiraExport? ugoiraExport,
  }) async {
    pauses++;
  }

  @override
  Future<void> resumeDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    UgoiraExport? ugoiraExport,
  }) async {
    resumes++;
  }

  @override
  Future<void> cancelDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    UgoiraExport? ugoiraExport,
  }) async {
    cancels++;
  }
}

class _CopyGate extends EncodedMediaCache {
  _CopyGate(this.png);
  final Uint8List png;
  final started = Completer<void>(), finish = Completer<void>();
  @override
  Future<bool> copyOriginal(
    MediaRequest request,
    File destination, {
    required String mimeType,
    int? expectedBytes,
    String? md5,
    String? sha256,
    void Function()? onCopyStarted,
  }) async {
    onCopyStarted?.call();
    started.complete();
    await finish.future;
    await destination.writeAsBytes(png);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  late Directory temp;
  late _Rust rust;
  late EncodedMediaCache cache;
  late RustIoDownloadEngine engine;
  late List<DownloadEngineEvent> events;
  late StreamSubscription<DownloadEngineEvent> subscription;
  final job = DownloadJob.create(
    resourceId: 1,
    sourceId: 'source',
    postId: '1',
    variantIndex: MediaVariantKind.original.index,
    url: Uri.parse(originalRequest.url),
    filename: '1.png',
    saveTarget: const SaveTarget.downloadsFolder(),
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('download-cache-');
    rust = _Rust(png);
    cache = EncodedMediaCache(temporaryDirectory: () async => temp);
    events = [];
  });
  void bind() {
    engine = RustIoDownloadEngine(
      type: DownloadEngineType.desktopRust,
      engine: () => rust,
      temporaryDirectory: () async => temp,
      cache: cache,
    );
    subscription = engine.events.listen(events.add);
  }

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(condition(), true);
  }

  tearDown(() async {
    await engine.dispose();
    await subscription.cancel();
    await temp.delete(recursive: true);
  });
  test(
    'a loaded original uses exact cached bytes, no transport, then the normal save event',
    () async {
      await cache.write(originalRequest, png);
      bind();
      await engine.start([job]);
      await until(() => events.whereType<EngineCompletedEvent>().isNotEmpty);
      final event = events.whereType<EngineCompletedEvent>().single;
      expect(await File(event.localPath).readAsBytes(), png);
      expect(await cache.read(originalRequest), png);
      expect(rust.requests, 0);
      expect(rust.prepared, 2);
      expect(events.whereType<EngineProgressEvent>().last.progress, 1);
    },
  );
  for (final kind in ['missing', 'wrong format', 'account changed']) {
    test('$kind cache uses the real transport path', () async {
      if (kind != 'missing') await cache.write(originalRequest, png);
      rust.changeAccount = kind == 'account changed';
      bind();
      await engine.start([
        kind == 'wrong format' ? job.copyWith(filename: '1.avif') : job,
      ]);
      await until(() => events.whereType<EngineCompletedEvent>().isNotEmpty);
      expect(rust.requests, 1);
      expect(events.whereType<EngineFailedEvent>(), isEmpty);
    });
  }
  test(
    'pause during a local copy holds completion and resume never calls Rust controls',
    () async {
      final gate = _CopyGate(png);
      cache = gate;
      bind();
      await engine.start([job]);
      await gate.started.future;
      await engine.pause(job.id);
      await until(() => events.whereType<EnginePausedEvent>().isNotEmpty);
      gate.finish.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(events.whereType<EngineCompletedEvent>(), isEmpty);
      expect(
        (await engine.syncActiveTasks()).single.status,
        DownloadStatus.paused,
      );
      await engine.resume(job.id);
      await until(() => events.whereType<EngineCompletedEvent>().isNotEmpty);
      expect((rust.requests, rust.pauses, rust.resumes), (0, 0, 0));
      expect(events.whereType<EngineResumedEvent>().single.restarted, false);
    },
  );
  test(
    'cancel during a local copy discards its result and removes the partial file',
    () async {
      final gate = _CopyGate(png);
      cache = gate;
      bind();
      await engine.start([job]);
      await gate.started.future;
      final cancelling = engine.cancel(job.id);
      gate.finish.complete();
      await cancelling;
      await until(() => events.whereType<EngineCancelledEvent>().isNotEmpty);
      expect(events.whereType<EngineCompletedEvent>(), isEmpty);
      expect((rust.requests, rust.cancels), (0, 0));
      expect(await File('${temp.path}/${job.id}/1.png.part').exists(), false);
    },
  );
}
