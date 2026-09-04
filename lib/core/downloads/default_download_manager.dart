// Public dependency-injection parameter names intentionally differ from the
// private backing fields.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:booruflow/core/downloads/download_engine.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/core/downloads/download_store.dart';
import 'package:booruflow/core/downloads/download_validator.dart';
import 'package:booruflow/core/downloads/media_saver.dart';
import 'package:booruflow/core/downloads/platform/desktop_media_saver.dart';
import 'package:booruflow/core/downloads/platform/native_download_engine.dart';
import 'package:booruflow/core/downloads/platform/rust_io_download_engine.dart';

final class DefaultDownloadManager implements DownloadManager {
  DefaultDownloadManager({
    required DownloadManagerConfiguration configuration,
    DownloadStore? store,
    DownloadEngine? engine,
    MediaSaver? mediaSaver,
    DownloadPermissionGuard? permissionGuard,
  }) : _configuration = configuration,
       _store = store,
       _engine = engine,
       _mediaSaver = mediaSaver,
       _permissionGuard = permissionGuard;

  final DownloadManagerConfiguration _configuration;
  DownloadStore? _store;
  DownloadEngine? _engine;
  MediaSaver? _mediaSaver;
  DownloadPermissionGuard? _permissionGuard;
  StreamSubscription<void>? _engineSubscription;
  Future<void>? _initializing;
  bool _initialized = false;
  bool _pumpingQueue = false;
  bool _queuePumpRequested = false;
  bool _ownsStore = false;
  bool _disposed = false;
  final _jobs = <String, DownloadJob>{};
  final _waiters = <String, Completer<DownloadedFile>>{};

  @override
  Future<void> initialize() {
    if (_disposed) {
      return Future<void>.error(
        StateError('DownloadManager has been disposed.'),
      );
    }
    if (_initialized) {
      return Future<void>.value();
    }
    return _initializing ??= _initializeWithReset();
  }

  Future<void> _initializeWithReset() async {
    try {
      await _initialize();
    } catch (_) {
      await _engineSubscription?.cancel();
      _engineSubscription = null;
      _initialized = false;
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }

    final components = _createPlatformComponents();
    if (_store == null) {
      _store = DriftDownloadStore.open();
      _ownsStore = true;
    }
    _engine ??= components.engine;
    _mediaSaver ??= components.mediaSaver;
    _permissionGuard ??= components.permissionGuard;
    await _activeEngine.initialize();
    _engineSubscription = _activeEngine.events
        .asyncMap(_handleEngineEvent)
        .listen(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            // An event failure must not terminate processing of later native events.
            Zone.current.handleUncaughtError(error, stackTrace);
          },
        );
    _initialized = true;
    await sync();
  }

  @override
  Future<void> ensureReadyForDownloads() async {
    await _ensureInitialized();
    await _activePermissionGuard.ensureReadyForDownload();
  }

  @override
  Future<int> enqueue(List<DownloadJob> jobs) async {
    await _ensureInitialized();
    final normalizedJobs = [for (final job in jobs) _prepareStoredJob(job)];
    if (normalizedJobs.isEmpty) {
      return 0;
    }
    await _activePermissionGuard.ensureReadyForDownload();
    var enqueued = 0;
    for (final job in normalizedJobs) {
      final activeTask = await _activeTaskForJob(job);
      if (activeTask != null) {
        continue;
      }
      _jobs[job.id] = job;
      await _activeStore.upsertJob(job);
      enqueued += 1;
    }

    if (enqueued == 0) {
      throw const DownloadException(
        'This image is already queued or downloading.',
      );
    }

    await _pumpQueue();
    return enqueued;
  }

  @override
  Future<void> refreshQueue() async {
    await _ensureInitialized();
    await _pumpQueue();
  }

  @override
  Future<DownloadedFile> download({
    required int resourceId,
    required int variantIndex,
    required Uri url,
    String? filename,
    DownloadNetworkOptions networkOptions = const DownloadNetworkOptions(),
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? title,
    String? thumbnailUrl,
  }) async {
    await _ensureInitialized();
    final job = DownloadJob.create(
      resourceId: resourceId,
      variantIndex: variantIndex,
      url: url,
      filename:
          filename ??
          resourceDownloadFilename(
            resourceId: resourceId,
            variantIndex: variantIndex,
            sourceUrl: url,
          ),
      networkOptions: networkOptions,
      validation: validation,
      saveTarget: _defaultSaveTarget(),
      title: title,
      thumbnailUrl: thumbnailUrl,
    );
    final waiter = Completer<DownloadedFile>();
    _waiters[job.id] = waiter;
    try {
      await enqueue([job]);
    } catch (_) {
      _waiters.remove(job.id);
      rethrow;
    }
    return waiter.future;
  }

  @override
  Future<DownloadedFile> saveBytes({
    required int resourceId,
    required int variantIndex,
    required Uint8List bytes,
    required Uri sourceUrl,
    String? filename,
    DownloadValidationOptions validation = const DownloadValidationOptions(),
    String? title,
    String? thumbnailUrl,
  }) async {
    await _ensureInitialized();
    await _activePermissionGuard.ensureReadyForDownload();
    final job = DownloadJob.create(
      resourceId: resourceId,
      variantIndex: variantIndex,
      url: sourceUrl,
      filename:
          filename ??
          resourceDownloadFilename(
            resourceId: resourceId,
            variantIndex: variantIndex,
            sourceUrl: sourceUrl,
          ),
      validation: validation,
      saveTarget: _defaultSaveTarget(),
      title: title,
      thumbnailUrl: thumbnailUrl,
    );
    final activeTask = await _activeTaskForJob(job);
    if (activeTask != null) {
      throw const DownloadException(
        'This image is already queued or downloading.',
      );
    }

    _jobs[job.id] = job;
    await _activeStore.upsertJob(job);
    await validateDownloadedBytes(bytes, validation: job.validation);
    await _activeStore.updateStatus(job.id, DownloadStatus.running);
    await _activeStore.updateProgress(
      job.id,
      receivedBytes: bytes.lengthInBytes,
      totalBytes: bytes.lengthInBytes,
      progress: 1,
    );
    await _activeStore.updateStatus(job.id, DownloadStatus.downloaded);
    await _activeStore.updateSaveState(job.id, SaveState.saving);
    try {
      final result = await _activeMediaSaver.saveBytes(job: job, bytes: bytes);
      await _activeStore.updateSaveState(
        job.id,
        SaveState.saved,
        localPath: result.path,
        galleryAssetId: result.galleryAssetId,
      );
      return DownloadedFile(
        path: result.path,
        bytesWritten: result.bytesWritten,
      );
    } catch (error, stackTrace) {
      await _activeStore.appendLog(
        job.id,
        'Save bytes failed.\n'
        'sourceUrl=$sourceUrl\n'
        'bytes=${bytes.lengthInBytes}\n'
        'filename=${job.filename}\n'
        'saveTarget=${job.saveTarget.toJson()}\n'
        'error=$error\n'
        'stackTrace=$stackTrace',
      );
      await _activeStore.updateSaveState(
        job.id,
        SaveState.failed,
        error: error.toString(),
      );
      throw DownloadException('Failed to save downloaded file', error);
    }
  }

  @override
  Future<void> pause(String jobId) async {
    await _ensureInitialized();
    await _activeEngine.pause(jobId);
  }

  @override
  Future<void> resume(String jobId) async {
    await _ensureInitialized();
    await _activeEngine.resume(jobId);
  }

  @override
  Future<void> cancel(String jobId) async {
    await _ensureInitialized();
    final task = await _activeStore.getTask(jobId);
    if (task == null ||
        task.status == DownloadStatus.failed ||
        task.status == DownloadStatus.cancelled ||
        task.status == DownloadStatus.downloaded ||
        task.saveState == SaveState.saving ||
        task.saveState == SaveState.saved) {
      return;
    }
    if (task.status == DownloadStatus.queued) {
      await _activeStore.updateStatus(jobId, DownloadStatus.cancelled);
      _completeWithError(jobId, const DownloadException('Download cancelled'));
      await _pumpQueue();
      return;
    }
    await _activeEngine.cancel(jobId);
  }

  @override
  Future<void> deleteTask(String jobId) async {
    await _ensureInitialized();
    final task = await _activeStore.getTask(jobId);
    if (task == null) {
      return;
    }

    if (task.status == DownloadStatus.running ||
        task.status == DownloadStatus.paused) {
      await _activeEngine.cancel(jobId);
    }

    _jobs.remove(jobId);
    _completeWithError(jobId, const DownloadException('Download task deleted'));
    await _activeStore.deleteTask(jobId);
    await _pumpQueue();
  }

  @override
  Future<void> retry(String jobId) async {
    await _ensureInitialized();
    final job = await _activeStore.getJob(jobId);
    if (job == null) {
      throw DownloadException('Download task does not exist: $jobId');
    }

    final task = await _activeStore.getTask(jobId);
    if (task?.status == DownloadStatus.downloaded &&
        task?.saveState == SaveState.failed) {
      final localPath = task?.localPath;
      if (localPath != null &&
          localPath.isNotEmpty &&
          await File(localPath).exists()) {
        await _activeStore.appendLog(
          jobId,
          'Retry requested for save failure. Local file exists, retrying save only. path=$localPath',
        );
        await retrySave(jobId);
        return;
      }
      await _activeStore.appendLog(
        jobId,
        'Retry requested for save failure, but the local file is missing. Re-downloading. path=${localPath ?? '<null>'}',
      );
    } else {
      await _activeStore.appendLog(
        jobId,
        'Retry requested. Re-queueing download.',
      );
    }

    await _activeStore.updateSaveState(jobId, SaveState.none);
    await enqueue([job]);
  }

  @override
  Future<void> retrySave(String jobId) async {
    await _ensureInitialized();
    final snapshot = await _activeStore.getTask(jobId);
    final job = await _activeStore.getJob(jobId);
    final localPath = snapshot?.localPath;
    if (snapshot == null ||
        job == null ||
        localPath == null ||
        localPath.isEmpty) {
      throw DownloadException(
        'Download task has no local file to save: $jobId',
      );
    }
    if (!await File(localPath).exists()) {
      await _activeStore.appendLog(
        jobId,
        'Save retry could not use local file because it no longer exists. path=$localPath',
      );
      throw DownloadException(
        'Downloaded local file does not exist: $localPath',
      );
    }

    await _activePermissionGuard.ensureReadyForDownload();
    await _activeStore.appendLog(
      jobId,
      'Retrying save only. path=$localPath target=${job.saveTarget.toJson()}',
    );
    await _saveCompletedFile(
      job,
      DownloadedFile(path: localPath, bytesWritten: snapshot.receivedBytes),
    );
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async {
    await _ensureInitialized();
    return _activeStore.listTasks(
      resourceId: resourceId,
      status: status,
      saveState: saveState,
    );
  }

  @override
  Stream<List<DownloadTaskSnapshot>> watchTasks({int? resourceId}) {
    return _activeStore.watchTasks(resourceId: resourceId);
  }

  @override
  Stream<DownloadTaskSnapshot?> watchTask(String jobId) {
    return _activeStore.watchTask(jobId);
  }

  @override
  Stream<DownloadSummary> watchSummary({int? resourceId}) {
    return _activeStore.watchSummary(resourceId: resourceId);
  }

  @override
  Future<void> sync() async {
    await _ensureInitialized();
    final snapshots = await _activeEngine.syncActiveTasks();
    final activeIds = <String>{};
    final nativeSavingIds = <String>{};
    final terminalSnapshotIds = <String>{};
    for (final snapshot in snapshots) {
      if (snapshot.jobId.isEmpty) {
        continue;
      }
      if (snapshot.status == DownloadStatus.running ||
          snapshot.status == DownloadStatus.paused ||
          snapshot.saveState == SaveState.saving) {
        activeIds.add(snapshot.jobId);
      }
      if (snapshot.saveState == SaveState.saving) {
        nativeSavingIds.add(snapshot.jobId);
      }
      if (snapshot.status == DownloadStatus.failed ||
          snapshot.status == DownloadStatus.cancelled ||
          snapshot.saveState == SaveState.saved ||
          snapshot.saveState == SaveState.failed) {
        terminalSnapshotIds.add(snapshot.jobId);
      }
      await _activeStore.applyEngineSnapshot(snapshot);
    }
    await _activeEngine.acknowledge(terminalSnapshotIds);

    final recoverableTasks = await _activeStore.listRecoverableTasks();
    for (final task in recoverableTasks) {
      if (task.status == DownloadStatus.running &&
          !activeIds.contains(task.id)) {
        await _activeStore.updateStatus(
          task.id,
          DownloadStatus.failed,
          error: 'Download was interrupted.',
        );
      }
    }

    await _resumePendingSaves(skipJobIds: nativeSavingIds);
    await _pumpQueue();
  }

  Future<void> _handleEngineEvent(DownloadEngineEvent event) async {
    await _ensureInitialized();
    switch (event) {
      case EngineProgressEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task == null ||
            task.status != DownloadStatus.running ||
            event.progress < task.progress) {
          return;
        }
        await _activeStore.updateProgress(
          event.jobId,
          receivedBytes: event.receivedBytes,
          totalBytes: event.totalBytes,
          progress: event.progress,
        );
      case EngineCompletedEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task == null ||
            task.status == DownloadStatus.failed ||
            task.status == DownloadStatus.cancelled ||
            task.saveState == SaveState.saved) {
          return;
        }
        await _activeStore.updateProgress(
          event.jobId,
          receivedBytes: event.bytesWritten,
          progress: 1,
        );
        await _activeStore.updateStatus(event.jobId, DownloadStatus.downloaded);
        await _activeStore.updateSaveState(
          event.jobId,
          _activeEngine.capabilities.handlesSaving
              ? SaveState.saving
              : SaveState.pending,
          localPath: event.localPath,
        );
        if (!_activeEngine.capabilities.handlesSaving) {
          final job = await _jobFor(event.jobId);
          if (job != null) {
            await _saveCompletedFile(
              job,
              DownloadedFile(
                path: event.localPath,
                bytesWritten: event.bytesWritten,
              ),
            );
          }
        }
        await _pumpQueue();
      case EngineFailedEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task == null ||
            task.status == DownloadStatus.cancelled ||
            task.status == DownloadStatus.downloaded ||
            task.saveState == SaveState.saved) {
          await _activeEngine.acknowledge({event.jobId});
          return;
        }
        await _activeStore.appendLog(
          event.jobId,
          'Download engine failed.\nerror=${event.error}',
        );
        await _activeStore.updateStatus(
          event.jobId,
          DownloadStatus.failed,
          error: event.error,
        );
        _completeWithError(event.jobId, DownloadException(event.error));
        await _activeEngine.acknowledge({event.jobId});
        await _pumpQueue();
      case EnginePausedEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task?.status != DownloadStatus.running) {
          return;
        }
        await _activeStore.updateStatus(event.jobId, DownloadStatus.paused);
        await _pumpQueue();
      case EngineCancelledEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task == null ||
            task.status == DownloadStatus.downloaded ||
            task.saveState == SaveState.saved ||
            task.saveState == SaveState.saving) {
          await _activeEngine.acknowledge({event.jobId});
          return;
        }
        await _activeStore.updateStatus(event.jobId, DownloadStatus.cancelled);
        _completeWithError(
          event.jobId,
          const DownloadException('Download cancelled'),
        );
        await _activeEngine.acknowledge({event.jobId});
        await _pumpQueue();
      case EngineSaveCompletedEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task == null ||
            task.status == DownloadStatus.cancelled ||
            task.status == DownloadStatus.failed) {
          await _activeEngine.acknowledge({event.jobId});
          return;
        }
        await _activeStore.updateSaveState(
          event.jobId,
          SaveState.saved,
          localPath: event.path,
          galleryAssetId: event.galleryAssetId,
        );
        await _completeWithSnapshot(event.jobId);
        await _activeEngine.acknowledge({event.jobId});
      case EngineSaveFailedEvent():
        final task = await _activeStore.getTask(event.jobId);
        if (task == null ||
            task.status == DownloadStatus.cancelled ||
            task.saveState == SaveState.saved) {
          await _activeEngine.acknowledge({event.jobId});
          return;
        }
        await _activeStore.appendLog(
          event.jobId,
          'Native save failed.\nlocalPath=${event.localPath ?? '<null>'}\nerror=${event.error}',
        );
        await _activeStore.updateSaveState(
          event.jobId,
          SaveState.failed,
          localPath: event.localPath,
          error: event.error,
        );
        _completeWithError(event.jobId, DownloadException(event.error));
        await _activeEngine.acknowledge({event.jobId});
    }
  }

  Future<void> _saveCompletedFile(DownloadJob job, DownloadedFile file) async {
    await _activeStore.updateSaveState(
      job.id,
      SaveState.saving,
      localPath: file.path,
    );
    try {
      final result = await _activeMediaSaver.saveDownloadedFile(
        job: job,
        file: file,
      );
      await _activeStore.updateSaveState(
        job.id,
        SaveState.saved,
        localPath: result.path,
        galleryAssetId: result.galleryAssetId,
      );
      _complete(
        job.id,
        DownloadedFile(path: result.path, bytesWritten: result.bytesWritten),
      );
    } catch (error, stackTrace) {
      await _activeStore.appendLog(
        job.id,
        'Save downloaded file failed.\n'
        'sourcePath=${file.path}\n'
        'sourceExists=${await File(file.path).exists()}\n'
        'bytesWritten=${file.bytesWritten}\n'
        'filename=${job.filename}\n'
        'saveTarget=${job.saveTarget.toJson()}\n'
        'error=$error\n'
        'stackTrace=$stackTrace',
      );
      await _activeStore.updateSaveState(
        job.id,
        SaveState.failed,
        localPath: file.path,
        error: error.toString(),
      );
      _completeWithError(
        job.id,
        DownloadException('Failed to save downloaded file', error),
      );
    }
  }

  Future<void> _resumePendingSaves({
    Set<String> skipJobIds = const <String>{},
  }) async {
    final pendingTasks = await _activeStore.listPendingSaveTasks();
    for (final task in pendingTasks) {
      if (skipJobIds.contains(task.id)) {
        continue;
      }
      final job = await _jobFor(task.id);
      final localPath = task.localPath;
      if (job == null || localPath == null || localPath.isEmpty) {
        await _activeStore.appendLog(
          task.id,
          'Pending save cannot resume because job or local file path is missing. jobExists=${job != null} path=${localPath ?? '<null>'}',
        );
        await _activeStore.updateSaveState(
          task.id,
          SaveState.failed,
          error: 'Download task has no local file to save.',
        );
        continue;
      }
      if (!await File(localPath).exists()) {
        await _activeStore.appendLog(
          task.id,
          'Pending save cannot resume because local file is missing. path=$localPath',
        );
        await _activeStore.updateSaveState(
          task.id,
          SaveState.failed,
          error: 'Downloaded local file does not exist: $localPath',
        );
        continue;
      }
      await _saveCompletedFile(
        job,
        DownloadedFile(path: localPath, bytesWritten: task.receivedBytes),
      );
    }
  }

  Future<void> _pumpQueue() async {
    if (_pumpingQueue) {
      _queuePumpRequested = true;
      return;
    }

    _pumpingQueue = true;
    try {
      do {
        _queuePumpRequested = false;
        await _pumpQueueOnce();
      } while (_queuePumpRequested);
    } finally {
      _pumpingQueue = false;
    }
  }

  Future<void> _pumpQueueOnce() async {
    final runningTasks = await _activeStore.listTasks(
      status: DownloadStatus.running,
    );
    var availableSlots =
        _configuration.maxConcurrentDownloads().clamp(1, 64).toInt() -
        runningTasks.length;
    if (availableSlots <= 0) {
      return;
    }

    final queuedTasks = await _activeStore.listTasks(
      status: DownloadStatus.queued,
    );
    queuedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final task in queuedTasks) {
      if (availableSlots <= 0) {
        return;
      }

      final job = await _jobFor(task.id);
      if (job == null) {
        await _activeStore.appendLog(
          task.id,
          'Queued task failed because job data is missing.',
        );
        await _activeStore.updateStatus(
          task.id,
          DownloadStatus.failed,
          error: 'Download task has no job data.',
        );
        continue;
      }

      final runtimeJob = _prepareRuntimeJob(job);
      await _activeStore.updateStatus(job.id, DownloadStatus.running);
      try {
        await _activeEngine.start([runtimeJob]);
        availableSlots -= 1;
      } catch (error, stackTrace) {
        await _activeStore.appendLog(
          job.id,
          'Failed to start download.\n'
          'url=${runtimeJob.url}\n'
          'filename=${runtimeJob.filename}\n'
          'networkOptions=${runtimeJob.networkOptions.toJson()}\n'
          'validation=${runtimeJob.validation.toJson()}\n'
          'saveTarget=${runtimeJob.saveTarget.toJson()}\n'
          'error=$error\n'
          'stackTrace=$stackTrace',
        );
        await _activeStore.updateStatus(
          job.id,
          DownloadStatus.failed,
          error: error.toString(),
        );
        _completeWithError(
          job.id,
          DownloadException('Failed to start download', error),
        );
      }
    }
  }

  Future<void> _completeWithSnapshot(String jobId) async {
    final waiter = _waiters.remove(jobId);
    if (waiter == null || waiter.isCompleted) {
      return;
    }
    final snapshot = await _activeStore.getTask(jobId);
    final path = snapshot?.localPath ?? snapshot?.galleryAssetId;
    if (snapshot == null || path == null || path.isEmpty) {
      waiter.completeError(
        DownloadException('Download completed without a saved path: $jobId'),
      );
      return;
    }
    waiter.complete(
      DownloadedFile(path: path, bytesWritten: snapshot.receivedBytes),
    );
  }

  void _complete(String jobId, DownloadedFile file) {
    final waiter = _waiters.remove(jobId);
    if (waiter == null || waiter.isCompleted) {
      return;
    }
    waiter.complete(file);
  }

  void _completeWithError(String jobId, Object error) {
    final waiter = _waiters.remove(jobId);
    if (waiter == null || waiter.isCompleted) {
      return;
    }
    waiter.completeError(error);
  }

  Future<DownloadJob?> _jobFor(String jobId) async {
    return _jobs[jobId] ?? await _activeStore.getJob(jobId);
  }

  DownloadJob _prepareStoredJob(DownloadJob job) {
    return job.copyWith(
      saveTarget: _defaultSaveTarget(job.saveTarget),
      networkOptions: job.networkOptions.normalizedFor(job.url),
      validation: job.validation.normalized(),
    );
  }

  DownloadJob _prepareRuntimeJob(DownloadJob job) {
    return job.copyWith(
      networkOptions: _configuration
          .resolveNetworkOptions(job.url, job.networkOptions)
          .normalizedFor(job.url),
    );
  }

  bool _isActiveDownloadTask(DownloadTaskSnapshot task) {
    return task.status == DownloadStatus.queued ||
        task.status == DownloadStatus.running ||
        task.status == DownloadStatus.paused ||
        task.saveState == SaveState.pending ||
        task.saveState == SaveState.saving;
  }

  Future<DownloadTaskSnapshot?> _activeTaskForJob(DownloadJob job) async {
    final task = await _activeStore.getTask(job.id);
    if (task != null && _isActiveDownloadTask(task)) {
      return task;
    }

    return null;
  }

  SaveTarget _defaultSaveTarget([SaveTarget? requested]) {
    if (requested != null && requested.type != SaveTargetType.downloadsFolder) {
      return requested;
    }
    if (Platform.isAndroid) {
      return SaveTarget.mediaStore(subdirectory: requested?.subdirectory);
    }
    if (Platform.isIOS) {
      return SaveTarget.photos(subdirectory: requested?.subdirectory);
    }
    return requested ?? const SaveTarget.downloadsFolder();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  DownloadStore get _activeStore {
    final store = _store;
    if (store == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return store;
  }

  DownloadEngine get _activeEngine {
    final engine = _engine;
    if (engine == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return engine;
  }

  MediaSaver get _activeMediaSaver {
    final mediaSaver = _mediaSaver;
    if (mediaSaver == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return mediaSaver;
  }

  DownloadPermissionGuard get _activePermissionGuard {
    final permissionGuard = _permissionGuard;
    if (permissionGuard == null) {
      throw StateError('DownloadManager.initialize() has not completed.');
    }
    return permissionGuard;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _engineSubscription?.cancel();
    _engineSubscription = null;
    final engine = _engine;
    if (engine != null) {
      await engine.dispose();
    }
    final store = _store;
    if (_ownsStore && store != null) {
      await store.close();
    }
    for (final waiter in _waiters.values) {
      if (!waiter.isCompleted) {
        waiter.completeError(
          const DownloadException('Download manager disposed'),
        );
      }
    }
    _waiters.clear();
    _initialized = false;
    _initializing = null;
  }
}

_DownloadComponents _createPlatformComponents() {
  if (Platform.isAndroid) {
    return _DownloadComponents(
      engine: RustIoDownloadEngine(
        type: DownloadEngineType.androidOkHttpForeground,
      ),
      mediaSaver: NativeMediaSaver(),
      permissionGuard: const NativeDownloadPermissionGuard(),
    );
  }
  if (Platform.isIOS) {
    return _DownloadComponents(
      engine: RustIoDownloadEngine(type: DownloadEngineType.iosUrlSession),
      mediaSaver: NativeMediaSaver(),
      permissionGuard: const NativeDownloadPermissionGuard(),
    );
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return _DownloadComponents(
      engine: RustIoDownloadEngine(type: DownloadEngineType.desktopRust),
      mediaSaver: const DesktopMediaSaver(),
      permissionGuard: const DesktopDownloadPermissionGuard(),
    );
  }
  return _DownloadComponents(
    engine: RustIoDownloadEngine(type: DownloadEngineType.unsupported),
    mediaSaver: const UnsupportedMediaSaver(),
    permissionGuard: const UnsupportedDownloadPermissionGuard(),
  );
}

class _DownloadComponents {
  const _DownloadComponents({
    required this.engine,
    required this.mediaSaver,
    required this.permissionGuard,
  });

  final DownloadEngine engine;
  final MediaSaver mediaSaver;
  final DownloadPermissionGuard permissionGuard;
}
