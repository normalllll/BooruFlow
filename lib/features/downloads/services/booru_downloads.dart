import 'dart:async';
import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/download_notifications.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:path/path.dart' as path;

class BooruDownloads {
  BooruDownloads({BooruService? service})
    : _service = service ?? BooruService.instance;

  static final instance = BooruDownloads();

  final BooruService _service;
  final _submittingBatches = <String>{};
  final _reportedBatches = <String>{};

  final _posts = <int, Post>{};
  final _lastStates = <String, (DownloadStatus, SaveState)>{};
  final _itemsController =
      StreamController<List<BooruDownloadItem>>.broadcast();
  StreamSubscription<List<DownloadTaskSnapshot>>? _subscription;
  List<BooruDownloadItem> _currentItems = const [];
  Future<void>? _initializing;
  Timer? _itemsUpdate;
  List<DownloadTaskSnapshot>? _pendingSnapshots;

  Stream<List<BooruDownloadItem>> get watchItems => _itemsController.stream;
  List<BooruDownloadItem> get currentItems => _currentItems;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    await initializeDownloadManager();
    final initial = await downloadManager.listTasks();
    for (final batch in initial.map((task) => task.batchId).nonNulls.toSet()) {
      if (initial.where((task) => task.batchId == batch).every(_settled)) {
        _reportedBatches.add(batch);
      }
    }
    _replaceItems(initial, notifyTransitions: false);
    _subscription = downloadManager.watchTasks().listen((snapshots) {
      _pendingSnapshots = snapshots;
      // Sample rather than debounce: continuous progress must still reach UI.
      _itemsUpdate ??= Timer(const Duration(milliseconds: 200), () {
        _itemsUpdate = null;
        final latest = _pendingSnapshots;
        _pendingSnapshots = null;
        if (latest != null) _replaceItems(latest, notifyTransitions: true);
      });
    });
  }

  Future<bool> add(Post post) async {
    try {
      await initialize();
      final job = await prepare(post);
      await downloadManager.enqueue([job]);
      notifyDownloadAdded(taskId: job.id, name: '#${post.id}');
      return true;
    } on DuplicateDownloadException {
      AppToast.show(t.downloads.messages.downloadTaskExists);
      return false;
    } catch (error) {
      notifyDownloadEnqueueFailure(
        name: '#${post.id}',
        error: error,
        retry: () => add(post),
      );
      return false;
    }
  }

  /// Prepare a task without showing per-image UI or hiding errors from callers.
  Future<DownloadJob> prepare(
    Post post, {
    String? batchId,
    SaveTarget? saveTarget,
  }) async {
    final prepared = await _service.engine.prepareDownload(
      sourceId: post.sourceId,
      postId: post.id,
      variant: MediaVariantKind.original,
    );
    final uri = Uri.parse(prepared.url);
    final expectedBytes = int.tryParse(prepared.expectedBytesDecimal ?? '');
    final preparedChecksum = prepared.checksum;
    final checksum = switch (preparedChecksum) {
      null => null,
      _ => DownloadChecksum(
        algorithm: switch (preparedChecksum.algorithm) {
          ChecksumAlgorithm.md5 => DownloadChecksumAlgorithm.md5,
          ChecksumAlgorithm.sha256 => DownloadChecksumAlgorithm.sha256,
        },
        value: preparedChecksum.value,
      ),
    };
    final ugoira = path.extension(prepared.filename).toLowerCase() == '.zip';
    final export = ugoira ? SettingsService.ugoiraExport : null;
    final job = DownloadJob.create(
      batchId: batchId,
      resourceId: post.resourceId,
      sourceId: post.sourceId,
      postId: post.id,
      variantIndex: MediaVariantKind.original.index,
      url: uri,
      filename: export == UgoiraExport.losslessWebp
          ? path.setExtension(prepared.filename, '.webp')
          : prepared.filename,
      ugoiraExport: export,
      // Rust resolves current cookies and browser identity when the job runs.
      // Download history must not become a second credential store.
      networkOptions: const DownloadNetworkOptions(),
      validation: DownloadValidationOptions(
        expectedBytes: expectedBytes != null && expectedBytes > 0
            ? expectedBytes
            : null,
        allowedContentTypes: [
          for (final kind in prepared.allowedMediaKinds) '${kind.name}/*',
        ],
        checksum: checksum,
      ),
      saveTarget:
          saveTarget ?? SaveTarget.downloadsFolder(subdirectory: post.sourceId),
      thumbnailUrl: postImageVariants(post).firstOrNull?.url,
      title: '${_service.sourceById(post.sourceId).displayName} #${post.id}',
    );

    _posts[post.resourceId] = post;
    return job;
  }

  void beginBatch(String batchId) {
    _submittingBatches.add(batchId);
    _reportedBatches.remove(batchId);
  }

  void endBatch(String batchId) {
    _itemsUpdate?.cancel();
    _itemsUpdate = null;
    final pending = _pendingSnapshots;
    _pendingSnapshots = null;
    if (pending != null) _replaceItems(pending, notifyTransitions: true);
    _submittingBatches.remove(batchId);
    _reportBatches(_currentItems.map((item) => item.snapshot).toList());
  }

  Future<void> retry(String jobId) async {
    final name = _currentItems
        .where((item) => item.snapshot.id == jobId)
        .map((item) => item.snapshot.filename)
        .firstOrNull;
    try {
      await initialize();
      await downloadManager.retry(jobId);
      AppToast.show(
        t.downloads.messages.downloadRetryWith(name: name ?? jobId),
      );
    } catch (error) {
      AppToast.errorWithCause(
        t.downloads.messages.downloadFailedWith(name: name ?? jobId),
        error,
      );
    }
  }

  Future<void> retryAll() async {
    await initialize();
    final tasks = await downloadManager.listTasks();
    for (final task in tasks) {
      if (task.status == DownloadStatus.failed ||
          task.status == DownloadStatus.cancelled ||
          task.saveState == SaveState.failed) {
        try {
          await downloadManager.retry(task.id);
        } catch (_) {
          // One broken task must not prevent the remaining tasks from retrying.
        }
      }
    }
  }

  Future<void> cancel(String jobId) => downloadManager.cancel(jobId);

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _itemsUpdate?.cancel();
    _itemsUpdate = null;
    _pendingSnapshots = null;
    await _itemsController.close();
    await downloadManager.dispose();
  }

  void _replaceItems(
    List<DownloadTaskSnapshot> snapshots, {
    required bool notifyTransitions,
  }) {
    final next = <BooruDownloadItem>[
      for (final snapshot in snapshots)
        BooruDownloadItem(
          snapshot: snapshot,
          post: _posts[snapshot.resourceId],
        ),
    ];
    if (notifyTransitions) {
      for (final snapshot in snapshots) {
        final previous = _lastStates[snapshot.id];
        final current = (snapshot.status, snapshot.saveState);
        if (previous != current && snapshot.batchId == null) {
          if (snapshot.saveState == SaveState.saved) {
            AppToast.success(
              t.downloads.messages.downloadCompletedWith(
                name: snapshot.filename,
              ),
            );
          } else if (snapshot.status == DownloadStatus.failed ||
              snapshot.saveState == SaveState.failed) {
            notifyDownloadFailure(task: snapshot, manager: downloadManager);
          }
        }
      }
      _reportBatches(snapshots);
    }
    _lastStates
      ..clear()
      ..addEntries(
        snapshots.map(
          (snapshot) =>
              MapEntry(snapshot.id, (snapshot.status, snapshot.saveState)),
        ),
      );
    _currentItems = List.unmodifiable(next);
    _itemsController.add(_currentItems);
  }

  static bool _settled(DownloadTaskSnapshot task) =>
      task.saveState == SaveState.saved ||
      task.saveState == SaveState.failed ||
      task.status == DownloadStatus.failed ||
      task.status == DownloadStatus.cancelled;

  void _reportBatches(List<DownloadTaskSnapshot> snapshots) {
    final groups = <String, List<DownloadTaskSnapshot>>{};
    for (final task in snapshots) {
      if (task.batchId case final batch?) (groups[batch] ??= []).add(task);
    }
    for (final entry in groups.entries) {
      if (_submittingBatches.contains(entry.key) ||
          _reportedBatches.contains(entry.key) ||
          !entry.value.every(_settled)) {
        continue;
      }
      _reportedBatches.add(entry.key);
      final saved = entry.value
          .where((task) => task.saveState == SaveState.saved)
          .length;
      AppToast.show(
        t.batchDownload.completed(
          saved: formatCount(saved),
          failed: formatCount(entry.value.length - saved),
        ),
      );
    }
  }
}
