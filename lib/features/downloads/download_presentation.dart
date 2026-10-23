import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_path_reveal.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

enum DownloadFilter { all, active, failed, saved }

/// Persisted save failures take precedence over a completed network transfer.
bool downloadFailed(DownloadTaskSnapshot task) =>
    task.status == DownloadStatus.failed || task.saveState == SaveState.failed;
bool downloadActive(DownloadTaskSnapshot task) => switch (task.status) {
  DownloadStatus.queued ||
  DownloadStatus.running ||
  DownloadStatus.paused => true,
  _ =>
    task.saveState == SaveState.pending || task.saveState == SaveState.saving,
};
bool downloadCompleted(DownloadTaskSnapshot task) =>
    task.status == DownloadStatus.downloaded &&
    !downloadActive(task) &&
    !downloadFailed(task);
String downloadStatusLabel(DownloadTaskSnapshot task) =>
    switch ((task.status, task.saveState)) {
      (_, SaveState.failed) => t.downloads.saveFailed,
      (_, SaveState.saving) => t.downloads.saving,
      (_, SaveState.pending) => t.downloads.savePending,
      (_, SaveState.saved) => t.downloads.saved,
      (DownloadStatus.queued, _) => t.downloads.queued,
      (DownloadStatus.running, _) => t.downloads.running,
      (DownloadStatus.paused, _) => t.downloads.paused,
      (DownloadStatus.downloaded, _) => t.downloads.downloaded,
      (DownloadStatus.failed, _) => t.downloads.failed,
      (DownloadStatus.cancelled, _) => t.downloads.cancelled,
    };
String downloadBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.clamp(0, 1 << 60).toDouble(), unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${NumberFormat(unit == 0 ? '0' : '0.#', LocaleSettings.currentLocale.languageTag).format(value)} ${units[unit]}';
}

String downloadByteProgress(DownloadTaskSnapshot task) => [
  downloadBytes(task.receivedBytes),
  if (task.totalBytes case final total?) downloadBytes(total),
].join(' / ');

/// One feedback path for task menus, inspectors and directory settings.
Future<void> revealDownloadPath(
  String path, {
  required DownloadPathRevealer revealer,
  bool directory = false,
  Future<void> Function()? onRedownload,
}) async {
  try {
    final result = await revealer.reveal(path, directory: directory);
    if (result == DownloadRevealStatus.fileMissing) {
      FrostToast.info(t.downloads.fileMissing);
    } else if (result == DownloadRevealStatus.missing) {
      AppToast.error(
        t.downloads.locationMissing,
        actionLabel: onRedownload == null ? null : t.downloads.redownload,
        onAction: onRedownload == null
            ? null
            : () async {
                try {
                  await onRedownload();
                } catch (error) {
                  AppToast.errorWithCause(t.downloads.actionFailed, error);
                }
              },
      );
    }
  } catch (error) {
    AppToast.errorWithCause(t.downloads.actionFailed, error);
  }
}

bool get canRevealDownloads => DownloadPlatform.current.canRevealDirectory;

String downloadTaskTitle(BooruDownloadItem item) =>
    item.postId == null ? item.snapshot.filename : '#${item.postId}';

String? downloadSourceName(BooruDownloadItem item, List<BooruSource> sources) =>
    sources
        .where((source) => source.sourceId == item.sourceId)
        .firstOrNull
        ?.displayName;

String downloadDay(DateTime time, {DateTime? now}) {
  final local = time.toLocal(), today = (now ?? DateTime.now()).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final currentDay = DateTime(today.year, today.month, today.day);
  if (day == currentDay) return t.downloads.today;
  if (day == currentDay.subtract(const Duration(days: 1))) {
    return t.downloads.yesterday;
  }
  return DateFormat.yMd(LocaleSettings.currentLocale.languageTag).format(local);
}

String downloadTime(DateTime time, {bool full = false}) => [
  if (full) downloadDay(time),
  DateFormat.jm(
    LocaleSettings.currentLocale.languageTag,
  ).format(time.toLocal()),
].join(' ');

String downloadRate(double rate) =>
    t.downloads.transferRate(value: downloadBytes(rate.round()));

String? downloadRemaining(DownloadTaskSnapshot task, double? rate) {
  final total = task.totalBytes;
  if (total == null ||
      rate == null ||
      rate <= 0 ||
      total <= task.receivedBytes) {
    return null;
  }
  return downloadRemainingTime((total - task.receivedBytes) / rate);
}

String downloadRemainingTime(double seconds) {
  if (seconds >= Duration.secondsPerHour) {
    return t.downloads.remainingHours(
      count: formatCount((seconds / Duration.secondsPerHour).ceil()),
    );
  }
  if (seconds >= Duration.secondsPerMinute) {
    return t.downloads.remainingMinutes(
      count: formatCount((seconds / Duration.secondsPerMinute).ceil()),
    );
  }
  return t.downloads.remainingSeconds(count: formatCount(seconds.ceil()));
}

({int count, double? progress, double? rate, String? remaining})
downloadTransferSummary(
  List<BooruDownloadItem> items,
  Map<String, double> rates,
) {
  final active = items.where((item) => downloadActive(item.snapshot)).toList();
  if (active.isEmpty) {
    return (count: 0, progress: null, rate: null, remaining: null);
  }
  final knownSizes = active.every(
    (item) => (item.snapshot.totalBytes ?? 0) > 0,
  );
  final total = active.fold<int>(
    0,
    (sum, item) => sum + (item.snapshot.totalBytes ?? 0),
  );
  final received = active.fold<int>(
    0,
    (sum, item) =>
        sum +
        item.snapshot.receivedBytes.clamp(
          0,
          item.snapshot.totalBytes ?? item.snapshot.receivedBytes,
        ),
  );
  final knownRates = [for (final item in active) ?rates[item.snapshot.id]];
  final rate = knownRates.isEmpty
      ? null
      : knownRates.fold<double>(0, (sum, value) => sum + value);
  return (
    count: active.length,
    progress: knownSizes ? (received / total).clamp(0.0, 1.0) : null,
    rate: rate,
    remaining: knownSizes && rate != null && rate > 0 && received < total
        ? downloadRemainingTime((total - received) / rate)
        : null,
  );
}

/// Mutually exclusive persisted outcomes. A completed transfer is not a saved
/// file, and cancelled records are never invented as skipped or failed tasks.
String downloadBatchResult(List<BooruDownloadItem> items) {
  final counts = <String, int>{};
  for (final item in items) {
    final label = downloadStatusLabel(item.snapshot);
    counts.update(label, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts.entries
      .map((entry) => '${entry.key} ${formatCount(entry.value)}')
      .join(' · ');
}
