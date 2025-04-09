import 'package:yande_gui/global.dart';

abstract class DownloadEventBase {}

class DownloadEventStart extends DownloadEventBase {
  DownloadEventStart();
}

class DownloadEventProgress extends DownloadEventBase {
  final double value;

  DownloadEventProgress(this.value);
}

class DownloadEventSuccess extends DownloadEventBase {}

class DownloadEventError extends DownloadEventBase {
  final String error;

  DownloadEventError(this.error);
}

class _DownloadTaskArgs {
  final String url;
  final String filePath;
  final int maxSegmentsPerTask;

  _DownloadTaskArgs({required this.url, required this.filePath, required this.maxSegmentsPerTask});
}

class DownloadQueueManager {
  final int Function() _getMaxConcurrentDownloads;
  final _queue = <_DownloadTaskEntry>[];
  final _activeJobs = <String, _DownloadTaskEntry>{};

  DownloadQueueManager({required int Function() getMaxConcurrentDownloads}) : _getMaxConcurrentDownloads = getMaxConcurrentDownloads;

  int get _maxConcurrentDownloads => _getMaxConcurrentDownloads();

  void startTask({
    required String taskId,
    required String url,
    required String filePath,
    required int maxSegmentsPerTask,
    required void Function(DownloadEventBase event) onEvent,
  }) {
    if (!_queue.any((e) => e.taskId == taskId)) {
      _queue.add(
        _DownloadTaskEntry(
          taskId: taskId,
          args: _DownloadTaskArgs(url: url, filePath: filePath, maxSegmentsPerTask: maxSegmentsPerTask),
          callback: onEvent,
        ),
      );
    }
    schedule();
  }

  void cancelTask(String taskId) {
    _queue.removeWhere((t) => t.taskId == taskId);
    final removed = _activeJobs.remove(taskId);
    if (removed != null) {
      schedule();
    }
  }

  void schedule() {
    while (_activeJobs.length < _maxConcurrentDownloads && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _activeJobs[task.taskId] = task;
      _doDownload(task);
    }
  }

  void _doDownload(_DownloadTaskEntry task) async {
    final args = task.args;
    final eventCallback = task.callback;

    eventCallback(DownloadEventStart());

    try {
      await yandeClient.downloadToFile(
        url: args.url,
        filePath: args.filePath,
        maxTaskCount: args.maxSegmentsPerTask,
        progressCallback: (received, total) {
          final progress = total == BigInt.zero ? 0.0 : received / total;
          eventCallback(DownloadEventProgress(progress.toDouble()));
        },
      );
      eventCallback(DownloadEventSuccess());
    } catch (e) {
      eventCallback(DownloadEventError(e.toString()));
    }

    _activeJobs.remove(task.taskId);
    schedule();
  }
}

class _DownloadTaskEntry {
  final String taskId;
  final _DownloadTaskArgs args;
  final void Function(DownloadEventBase) callback;

  _DownloadTaskEntry({required this.taskId, required this.args, required this.callback});
}
