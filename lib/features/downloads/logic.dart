import 'dart:async';

import 'package:yande_gui/core/downloads/download_manager.dart';
import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/features/downloads/yande_download_item.dart';
import 'package:yande_gui/features/downloads/yande_download_naming.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/shared/app_toast.dart';
import 'package:yande_gui/features/posts/network/yande_network_policy.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

final class YandeDownloads {
  YandeDownloads._();

  static final instance = YandeDownloads._();

  final _posts = <int, Post>{};
  final _lastStates = <String, (DownloadStatus, SaveState)>{};
  final _itemsController =
      StreamController<List<YandeDownloadItem>>.broadcast();
  StreamSubscription<List<DownloadTaskSnapshot>>? _subscription;
  List<YandeDownloadItem> _currentItems = const [];
  Future<void>? _initializing;

  Stream<List<YandeDownloadItem>> get watchItems => _itemsController.stream;
  List<YandeDownloadItem> get currentItems => _currentItems;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    await YandeNetworkPolicy.initialize();
    await initializeDownloadManager();
    final initial = await downloadManager.listTasks();
    _replaceItems(initial, notifyTransitions: false);
    _subscription = downloadManager.watchTasks().listen(
      (snapshots) => _replaceItems(snapshots, notifyTransitions: true),
    );
  }

  Future<void> add(Post post) async {
    var filename = 'Yande #${post.id}';
    try {
      await initialize();
      final source = post.fileUrl ?? post.jpegUrl ?? post.previewUrl;
      final uri = Uri.parse(source);
      final usesOriginal = post.fileUrl != null && source == post.fileUrl;
      final expectedBytes = usesOriginal
          ? post.fileSize
          : post.jpegUrl != null && source == post.jpegUrl
          ? post.jpegFileSize
          : null;
      final checksum =
          usesOriginal && RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(post.md5)
          ? DownloadChecksum(
              algorithm: DownloadChecksumAlgorithm.md5,
              value: post.md5,
            )
          : null;
      filename = yandePostDownloadFilename(
        postId: post.id,
        variantIndex: 0,
        sourceUrl: uri,
        declaredExtension: usesOriginal ? post.fileExt : null,
      );
      final job = DownloadJob.create(
        resourceId: post.id,
        variantIndex: 0,
        url: uri,
        filename: filename,
        networkOptions: DownloadNetworkOptions(
          headers: YandeNetworkPolicy.imageHeaders,
        ),
        validation: DownloadValidationOptions(
          expectedBytes: expectedBytes != null && expectedBytes > 0
              ? expectedBytes
              : null,
          allowedContentTypes: const ['image/*'],
          checksum: checksum,
        ),
        saveTarget: const SaveTarget.downloadsFolder(),
        thumbnailUrl: post.previewUrl,
        title: 'Yande #${post.id}',
      );

      _posts[post.id] = post;
      await downloadManager.enqueue([job]);
      AppToast.show(t.downloads.messages.downloadStartWith(name: filename));
    } on DownloadException catch (error) {
      if (error.message.contains('already')) {
        AppToast.show(t.downloads.messages.downloadTaskExists);
        return;
      }
      AppToast.error(t.downloads.messages.downloadFailedWith(name: filename));
    } catch (_) {
      AppToast.error(t.downloads.messages.downloadFailedWith(name: filename));
    }
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
    } catch (_) {
      AppToast.error(
        t.downloads.messages.downloadFailedWith(name: name ?? jobId),
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
    await _itemsController.close();
    await downloadManager.dispose();
  }

  void _replaceItems(
    List<DownloadTaskSnapshot> snapshots, {
    required bool notifyTransitions,
  }) {
    final next = <YandeDownloadItem>[
      for (final snapshot in snapshots)
        YandeDownloadItem(
          snapshot: snapshot,
          post: _posts[snapshot.resourceId],
        ),
    ];
    if (notifyTransitions) {
      for (final snapshot in snapshots) {
        final previous = _lastStates[snapshot.id];
        final current = (snapshot.status, snapshot.saveState);
        if (previous != current) {
          if (snapshot.saveState == SaveState.saved) {
            AppToast.success(
              t.downloads.messages.downloadCompletedWith(
                name: snapshot.filename,
              ),
            );
          } else if (snapshot.status == DownloadStatus.failed ||
              snapshot.saveState == SaveState.failed) {
            AppToast.error(
              t.downloads.messages.downloadFailedWith(name: snapshot.filename),
            );
          }
        }
      }
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
}
