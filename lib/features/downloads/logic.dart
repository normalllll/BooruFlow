import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@Riverpod(keepAlive: true)
BooruDownloads booruDownloads(Ref ref) => BooruDownloads.instance;
@Riverpod(keepAlive: true, name: 'downloadManagerProvider')
DownloadManager downloadManagerDependency(Ref ref) => downloadManager;

@Riverpod(keepAlive: true)
class DownloadItems extends _$DownloadItems {
  @override
  List<BooruDownloadItem> build() {
    final downloads = ref.watch(booruDownloadsProvider);
    final subscription = downloads.watchItems.listen(
      (items) => state = List.unmodifiable(items),
    );
    ref.onDispose(subscription.cancel);
    return List.unmodifiable(downloads.currentItems);
  }
}

@Riverpod(keepAlive: true)
class SessionDownloads extends _$SessionDownloads {
  final _startedAt = DateTime.now();
  final _ids = <String>{};

  @override
  List<BooruDownloadItem> build() {
    final initial = ref.read(downloadItemsProvider);
    ref.listen(downloadItemsProvider, (_, items) => state = _remember(items));
    return _remember(initial);
  }

  List<BooruDownloadItem> _remember(List<BooruDownloadItem> items) {
    for (final item in items) {
      final task = item.snapshot;
      if (!task.createdAt.isBefore(_startedAt) ||
          switch (task.status) {
            DownloadStatus.queued ||
            DownloadStatus.running ||
            DownloadStatus.failed => true,
            _ => false,
          } ||
          switch (task.saveState) {
            SaveState.pending || SaveState.saving || SaveState.failed => true,
            _ => false,
          }) {
        _ids.add(task.id);
      }
    }
    return List.unmodifiable(
      items.where((item) => _ids.contains(item.snapshot.id)),
    );
  }
}
