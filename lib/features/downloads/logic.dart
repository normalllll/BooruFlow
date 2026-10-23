import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_path_reveal.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@riverpod
DownloadPathRevealer downloadPathRevealer(Ref ref) => DownloadPathRevealer();

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

/// Weighted determinate progress; unknown sizes keep the count but no ring.
@riverpod
({int count, double? progress}) downloadActivity(Ref ref) {
  final active = ref
      .watch(downloadItemsProvider)
      .where(
        (item) => switch (item.snapshot.status) {
          DownloadStatus.queued ||
          DownloadStatus.running ||
          DownloadStatus.paused => true,
          _ => item.snapshot.saveState == SaveState.saving,
        },
      )
      .toList();
  if (active.isEmpty) return (count: 0, progress: null);
  if (active.any((item) => (item.snapshot.totalBytes ?? 0) <= 0)) {
    return (count: active.length, progress: null);
  }
  final total = active.fold<int>(
    0,
    (sum, item) => sum + item.snapshot.totalBytes!,
  );
  final received = active.fold<int>(
    0,
    (sum, item) =>
        sum + item.snapshot.receivedBytes.clamp(0, item.snapshot.totalBytes!),
  );
  return (count: active.length, progress: (received / total).clamp(0.0, 1.0));
}

/// Presentation rates come from consecutive engine snapshots, never an assumed
/// connection speed. No persistence or competing task state is introduced.
@riverpod
class DownloadTransferRates extends _$DownloadTransferRates {
  final _samples = <String, (int, DateTime)>{};
  @override
  Map<String, double> build() {
    _samples.clear();
    for (final item in ref.read(downloadItemsProvider)) {
      if (item.snapshot.status == DownloadStatus.running) {
        _samples[item.snapshot.id] = (
          item.snapshot.receivedBytes,
          item.snapshot.updatedAt,
        );
      }
    }
    ref.listen(downloadItemsProvider, (_, items) {
      final rates = <String, double>{};
      final current = <String, (int, DateTime)>{};
      for (final item in items) {
        final task = item.snapshot;
        if (task.status != DownloadStatus.running) continue;
        final previous = _samples[task.id];
        current[task.id] = (task.receivedBytes, task.updatedAt);
        if (previous == null) continue;
        final elapsed = task.updatedAt.difference(previous.$2).inMicroseconds;
        final delta = task.receivedBytes - previous.$1;
        if (elapsed > 0 && delta >= 0) {
          rates[task.id] = delta * Duration.microsecondsPerSecond / elapsed;
        } else if (elapsed == 0 && delta == 0 && state[task.id] != null) {
          rates[task.id] = state[task.id]!;
        }
      }
      _samples
        ..clear()
        ..addAll(current);
      state = Map.unmodifiable(rates);
    });
    return const {};
  }
}
