import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';

/// Runs [action] for every task of [items] that matches. The ones that fail
/// stay where they are and are counted in one message.
Future<void> eachDownload(
  DownloadManager manager,
  Iterable<BooruDownloadItem> items,
  bool Function(DownloadTaskSnapshot) matches,
  Future<void> Function(DownloadManager, DownloadTaskSnapshot) action,
) async {
  var failed = 0;
  Object? first;
  for (final item in List.of(items)) {
    if (!matches(item.snapshot)) continue;
    try {
      await action(manager, item.snapshot);
    } catch (error) {
      failed++;
      first ??= error;
    }
  }
  if (failed > 0) {
    AppToast.errorWithCause(
      t.downloads.partialFailed(n: failed, count: formatCount(failed)),
      first!,
    );
  }
}

/// Retries one task: a failed save saves again, any other failure downloads
/// again.
Future<void> retryDownload(
  DownloadManager manager,
  DownloadTaskSnapshot task,
) => task.saveState == SaveState.failed
    ? manager.retrySave(task.id)
    : manager.retry(task.id);

Future<void> retryFailedDownloads(
  DownloadManager manager,
  Iterable<BooruDownloadItem> items,
) => eachDownload(manager, items, downloadFailed, retryDownload);

Future<void> clearCompletedDownloads(
  DownloadManager manager,
  Iterable<BooruDownloadItem> items,
) => eachDownload(
  manager,
  items,
  downloadCompleted,
  (manager, task) => manager.deleteTask(task.id),
);
