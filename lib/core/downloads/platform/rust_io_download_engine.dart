import 'dart:async';
import 'dart:io';
import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_validator.dart';
import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:path/path.dart' as p;

final class RustIoDownloadEngine implements DownloadEngine {
  RustIoDownloadEngine({
    required this.type,
    BooruEngine Function()? engine,
    Future<Directory> Function()? temporaryDirectory,
    this.cache = const EncodedMediaCache(),
  }) : _engine = engine ?? (() => BooruService.instance.engine),
       _temporaryDirectory = temporaryDirectory ?? downloadTempDirectory;
  final EncodedMediaCache cache;
  final Future<Directory> Function() _temporaryDirectory;
  final BooruEngine Function() _engine;

  @override
  final DownloadEngineType type;

  @override
  DownloadCapabilities get capabilities {
    return const DownloadCapabilities(
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
  }

  final _events = StreamController<DownloadEngineEvent>.broadcast();
  final _running = <String, _RunningDownload>{};

  @override
  Stream<DownloadEngineEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start(List<DownloadJob> jobs) async {
    for (final job in jobs) {
      if (_running[job.id] case final running?) {
        if (running.paused) await resume(job.id);
        continue;
      }
      unawaited(_download(job));
    }
  }

  @override
  Future<void> pause(String jobId) async {
    final running = _running[jobId];
    if (running == null || running.cancelled) return;
    // Starting the FFI stream and registering its Rust control are asynchronous.
    // Do not lose a pause clicked during local directory/metadata preparation.
    await Future.any([running.started, running.finished]);
    if (running.cancelled || !_running.containsKey(jobId)) return;
    if (running.copyingCache) {
      if (!running.paused) {
        running.pauseLocal();
        _events.add(EnginePausedEvent(jobId: jobId));
      }
      return;
    }
    await running.engine.pauseDownload(
      sourceId: running.job.sourceId,
      postId: running.job.postId,
      variant: MediaVariantKind.values[running.job.variantIndex],
      ugoiraExport: running.job.ugoiraExport,
    );
  }

  @override
  Future<void> resume(String jobId) async {
    final running = _running[jobId];
    if (running == null || running.cancelled) return;
    if (running.copyingCache) {
      running.resumeLocal();
      _events.add(EngineResumedEvent(jobId: jobId, restarted: false));
      return;
    }
    await running.engine.resumeDownload(
      sourceId: running.job.sourceId,
      postId: running.job.postId,
      variant: MediaVariantKind.values[running.job.variantIndex],
      ugoiraExport: running.job.ugoiraExport,
    );
  }

  @override
  Future<void> cancel(String jobId) async {
    final running = _running[jobId];
    if (running == null) {
      return;
    }
    running.cancelled = true;
    running.resumeLocal();
    if (!running.copyingCache) {
      await running.engine.cancelDownload(
        sourceId: running.job.sourceId,
        postId: running.job.postId,
        variant: MediaVariantKind.values[running.job.variantIndex],
        ugoiraExport: running.job.ugoiraExport,
      );
    }
    running.completeWithError(const DownloadException('Download cancelled'));
    await running.cancelSubscription();
    await running.finished;
  }

  @override
  Future<List<DownloadEngineSnapshot>> syncActiveTasks() async {
    return [
      for (final running in _running.values)
        DownloadEngineSnapshot(
          jobId: running.job.id,
          status: running.paused
              ? DownloadStatus.paused
              : DownloadStatus.running,
          saveState: SaveState.none,
          receivedBytes: running.receivedBytes,
          totalBytes: running.totalBytes,
          progress: running.progress,
        ),
    ];
  }

  @override
  Future<void> acknowledge(Set<String> jobIds) async {}

  @override
  Future<void> dispose() async {
    final running = _running.values.toList(growable: false);
    for (final item in running) {
      await cancel(item.job.id);
    }
    await Future.wait(running.map((item) => item.finished));
    await _events.close();
  }

  Future<bool> _copyCached(
    DownloadJob job,
    _RunningDownload running,
    File destination,
  ) async {
    final mime = encodedImageMimeForExtension(p.extension(job.filename));
    if (mime == null ||
        job.ugoiraExport != null ||
        !downloadContentTypeMatches(mime, job.validation.allowedContentTypes)) {
      return false;
    }
    var copied = false;
    try {
      final request = await running.engine.prepareMediaUrl(
        sourceId: job.sourceId,
        postId: job.postId,
        variant: MediaVariantKind.values[job.variantIndex],
        url: job.url.toString(),
        allowDiskCache: true,
      );
      final checksum = job.validation.checksum;
      copied = await cache.copyOriginal(
        request,
        destination,
        mimeType: mime,
        expectedBytes: job.validation.expectedBytes,
        md5: checksum?.algorithm == DownloadChecksumAlgorithm.md5
            ? checksum!.value
            : null,
        sha256: checksum?.algorithm == DownloadChecksumAlgorithm.sha256
            ? checksum!.value
            : null,
        onCopyStarted: () {
          running.copyingCache = true;
          running.markStarted();
        },
      );
      if (copied) {
        final current = await running.engine.prepareMediaUrl(
          sourceId: job.sourceId,
          postId: job.postId,
          variant: request.variant,
          url: job.url.toString(),
          allowDiskCache: true,
        );
        if (current.cacheKey != request.cacheKey || !current.allowDiskCache) {
          await deleteFileIfExists(destination);
          copied = false;
        }
      }
    } catch (_) {
      // Preparation/revalidation can fail after a successful copy as well.
      // In every case the optional cache must fall back to the real request.
      copied = false;
      await deleteFileIfExists(destination);
    }
    if (running.copyingCache) {
      await running.waitForLocalResume();
      if (!copied) running.copyingCache = false;
    }
    if (running.cancelled) throw const DownloadException('Download cancelled');
    return copied;
  }

  Future<void> _download(DownloadJob job) async {
    final running = _RunningDownload(job: job, engine: _engine());
    _running[job.id] = running;

    File? partialFile;
    File? downloadedFile;
    try {
      final tempDirectory = await _temporaryDirectory();
      final jobDirectory = Directory(p.join(tempDirectory.path, job.id));
      await jobDirectory.create(recursive: true);
      final filename = safeDownloadFilename(job.filename);
      partialFile = File(p.join(jobDirectory.path, '$filename.part'));
      final destination = File(p.join(jobDirectory.path, filename));
      await deleteFileIfExists(partialFile);
      await deleteFileIfExists(destination);

      var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
      final cached = await _copyCached(job, running, partialFile);
      final downloadedPath = cached
          ? partialFile.path
          : await running.download(
              job,
              jobDirectory.path,
              onPaused: () => _events.add(EnginePausedEvent(jobId: job.id)),
              onResumed: (restarted) {
                if (restarted) {
                  running.receivedBytes = 0;
                  running.progress = 0;
                }
                _events.add(
                  EngineResumedEvent(jobId: job.id, restarted: restarted),
                );
              },
              onProgress: (receivedBytes, totalBytes, progress) {
                running.receivedBytes = receivedBytes;
                running.totalBytes = totalBytes;
                running.progress = progress;

                final now = DateTime.now();
                if (now.difference(lastEmit).inMilliseconds >= 300 ||
                    running.progress >= 1) {
                  lastEmit = now;
                  _events.add(
                    EngineProgressEvent(
                      jobId: job.id,
                      receivedBytes: running.receivedBytes,
                      totalBytes: running.totalBytes,
                      progress: running.progress,
                    ),
                  );
                }
              },
            );

      downloadedFile = File(downloadedPath);
      if (running.cancelled) {
        throw const DownloadException('Download cancelled');
      }
      if (!await downloadedFile.exists()) {
        throw DownloadException(
          'Downloaded file does not exist: $downloadedPath',
        );
      }

      final bytesWritten = await downloadedFile.length();
      running.receivedBytes = bytesWritten;
      running.totalBytes = bytesWritten;
      running.progress = 1;
      await deleteFileIfExists(destination);
      final savedTempFile = await downloadedFile.rename(destination.path);
      _events.add(
        EngineProgressEvent(
          jobId: job.id,
          receivedBytes: running.receivedBytes,
          totalBytes: running.totalBytes,
          progress: 1,
        ),
      );
      _events.add(
        EngineCompletedEvent(
          jobId: job.id,
          localPath: savedTempFile.path,
          bytesWritten: running.receivedBytes,
        ),
      );
    } catch (error, stackTrace) {
      if (partialFile != null && await partialFile.exists()) {
        await partialFile.delete();
      }
      if (downloadedFile != null &&
          downloadedFile.path != partialFile?.path &&
          await downloadedFile.exists()) {
        await downloadedFile.delete();
      }

      if (running.cancelled) {
        _events.add(EngineCancelledEvent(jobId: job.id));
      } else {
        _events.add(
          EngineFailedEvent(
            jobId: job.id,
            error:
                'Rust download failed.\n'
                'source=${job.sourceId} post=${job.postId}\n'
                'filename=${job.filename}\n'
                'partialPath=${partialFile?.path ?? '<null>'}\n'
                'downloadedPath=${downloadedFile?.path ?? '<null>'}\n'
                'validation=${job.validation.toJson()}\n'
                'error=${describeBooruError(error)}\n'
                'stackTrace=$stackTrace',
          ),
        );
      }
    } finally {
      _running.remove(job.id);
      await running.cancelSubscription();
      running.completeFinished();
    }
  }
}

class _RunningDownload {
  _RunningDownload({required this.job, required this.engine});
  final BooruEngine engine;

  final DownloadJob job;
  StreamSubscription<DownloadEvent>? subscription;
  Completer<String>? _pathCompleter;
  final _finishedCompleter = Completer<void>();
  final _startedCompleter = Completer<void>();
  Future<void> get started => _startedCompleter.future;
  bool cancelled = false, paused = false, copyingCache = false;
  Completer<void>? _localResume;
  void markStarted() {
    if (!_startedCompleter.isCompleted) _startedCompleter.complete();
  }

  void pauseLocal() {
    paused = true;
    _localResume ??= Completer<void>();
  }

  void resumeLocal() {
    paused = false;
    final resume = _localResume;
    _localResume = null;
    resume?.complete();
  }

  Future<void> waitForLocalResume() async {
    if (_localResume case final pending?) await pending.future;
  }

  int receivedBytes = 0;
  int? totalBytes;
  double progress = 0;

  Future<String> download(
    DownloadJob job,
    String downloadRoot, {
    required void Function(int receivedBytes, int? totalBytes, double progress)
    onProgress,
    required void Function() onPaused,
    required void Function(bool restarted) onResumed,
  }) {
    if (cancelled) {
      return Future<String>.error(
        const DownloadException('Download cancelled'),
      );
    }
    final completer = Completer<String>();
    _pathCompleter = completer;
    subscription = engine
        .downloadToFileStream(
          request: DownloadRequest(
            sourceId: job.sourceId,
            postId: job.postId,
            variant:
                job.variantIndex >= 0 &&
                    job.variantIndex < MediaVariantKind.values.length
                ? MediaVariantKind.values[job.variantIndex]
                : MediaVariantKind.original,
            downloadRoot: downloadRoot,
            ugoiraExport: job.ugoiraExport,
          ),
        )
        .listen(
          (event) {
            if (!_startedCompleter.isCompleted) _startedCompleter.complete();
            if (cancelled) {
              return;
            }
            switch (event) {
              case DownloadEvent_Failed(:final error):
                completeWithError(error);
              case DownloadEvent_Paused():
                paused = true;
                onPaused();
              case DownloadEvent_Resumed(:final restarted):
                paused = false;
                onResumed(restarted);
              case DownloadEvent_Progress(
                :final receivedBytesDecimal,
                :final totalBytesDecimal,
                :final progress,
              ):
                onProgress(
                  int.tryParse(receivedBytesDecimal) ?? 0,
                  int.tryParse(totalBytesDecimal ?? ''),
                  job.ugoiraExport == UgoiraExport.losslessWebp
                      ? progress * .9
                      : progress,
                );
              case DownloadEvent_Encoding(
                :final completedFrames,
                :final totalFrames,
              ):
                onProgress(
                  receivedBytes,
                  totalBytes,
                  .9 + .1 * completedFrames / totalFrames,
                );
              case DownloadEvent_Done(:final path):
                complete(path);
            }
          },
          onError: completeWithError,
          onDone: () {
            if (!completer.isCompleted) {
              completer.completeError(
                const DownloadException(
                  'Download completed without file path.',
                ),
              );
            }
          },
          cancelOnError: true,
        );
    return completer.future;
  }

  Future<void> get finished => _finishedCompleter.future;

  void completeFinished() {
    if (!_finishedCompleter.isCompleted) {
      _finishedCompleter.complete();
    }
  }

  void complete(String path) {
    final completer = _pathCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(path);
  }

  void completeWithError(Object error, [StackTrace? stackTrace]) {
    final completer = _pathCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.completeError(error, stackTrace);
  }

  Future<void> cancelSubscription() async {
    final current = subscription;
    subscription = null;
    if (current == null) return;
    try {
      await current.cancel();
    } catch (_) {
      // The request error has already been delivered through the stream.
      // Cancellation is cleanup and must not surface it a second time.
    }
  }
}
