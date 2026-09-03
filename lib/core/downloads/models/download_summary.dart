import 'download_enums.dart';
import 'download_task_snapshot.dart';

class DownloadSummary {
  const DownloadSummary({
    required this.resourceId,
    required this.total,
    required this.queued,
    required this.running,
    required this.downloaded,
    required this.failed,
    required this.cancelled,
    required this.savePending,
    required this.saveFailed,
    required this.saved,
    required this.overallProgress,
  });

  factory DownloadSummary.fromTasks(
    List<DownloadTaskSnapshot> tasks, {
    int? resourceId,
  }) {
    var queued = 0;
    var running = 0;
    var downloaded = 0;
    var failed = 0;
    var cancelled = 0;
    var savePending = 0;
    var saveFailed = 0;
    var saved = 0;
    var progressTotal = 0.0;
    var progressCount = 0;
    var completedForProgress = 0;

    for (final task in tasks) {
      switch (task.status) {
        case DownloadStatus.queued:
          queued += 1;
          progressTotal += task.progress.clamp(0, 1);
          progressCount += 1;
          break;
        case DownloadStatus.running:
          running += 1;
          progressTotal += task.progress.clamp(0, 1);
          progressCount += 1;
          break;
        case DownloadStatus.paused:
          progressTotal += task.progress.clamp(0, 1);
          progressCount += 1;
          break;
        case DownloadStatus.downloaded:
          downloaded += 1;
          completedForProgress += 1;
          break;
        case DownloadStatus.failed:
          failed += 1;
          break;
        case DownloadStatus.cancelled:
          cancelled += 1;
          break;
      }

      switch (task.saveState) {
        case SaveState.pending:
        case SaveState.saving:
          savePending += 1;
          break;
        case SaveState.failed:
          saveFailed += 1;
          break;
        case SaveState.saved:
          saved += 1;
          break;
        case SaveState.none:
          break;
      }
    }

    return DownloadSummary(
      resourceId: resourceId,
      total: tasks.length,
      queued: queued,
      running: running,
      downloaded: downloaded,
      failed: failed,
      cancelled: cancelled,
      savePending: savePending,
      saveFailed: saveFailed,
      saved: saved,
      overallProgress: progressCount > 0
          ? progressTotal / progressCount
          : completedForProgress > 0
          ? 1
          : 0,
    );
  }

  final int? resourceId;
  final int total;
  final int queued;
  final int running;
  final int downloaded;
  final int failed;
  final int cancelled;
  final int savePending;
  final int saveFailed;
  final int saved;
  final double overallProgress;
}
