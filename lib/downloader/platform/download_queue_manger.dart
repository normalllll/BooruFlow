import 'dart:async';

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
  final FutureOr<void> Function()? onFirstTaskStarted;
  final FutureOr<void> Function()? onAllTasksCompleted;
  final FutureOr<void> Function(int total, int completed, int failed, int canceled, double overallProgress)? onProgressChanged;

  final _queue = <_DownloadTaskEntry>[];
  final _activeJobs = <String, _DownloadTaskEntry>{};
  final Map<String, double> _taskProgress = {};
  Timer? _throttleTimer;

  int _totalTaskCount = 0;
  int _completedTaskCount = 0;
  int _failedTaskCount = 0;
  int _canceledTaskCount = 0;
  bool _isIdle = true;
  bool _foregroundServiceStarted = false;

  DownloadQueueManager({
    required int Function() getMaxConcurrentDownloads,
    this.onFirstTaskStarted,
    this.onAllTasksCompleted,
    this.onProgressChanged,
  }) : _getMaxConcurrentDownloads = getMaxConcurrentDownloads;

  int get _maxConcurrentDownloads => _getMaxConcurrentDownloads();

  void startTask({
    required String taskId,
    required String url,
    required String filePath,
    required int maxSegmentsPerTask,
    required void Function(DownloadEventBase event) onEvent,
  }) async {
    final isNewSession = _isIdle;
    if (!_queue.any((e) => e.taskId == taskId) && !_activeJobs.containsKey(taskId)) {
      _queue.add(
        _DownloadTaskEntry(
          taskId: taskId,
          args: _DownloadTaskArgs(
            url: url,
            filePath: filePath,
            maxSegmentsPerTask: maxSegmentsPerTask,
          ),
          callback: onEvent,
        ),
      );
      _totalTaskCount++;
      _updateProgressThrottled();
    }
    if (isNewSession && !_foregroundServiceStarted) {
      _isIdle = false;
      await onFirstTaskStarted?.call();
      _foregroundServiceStarted = true;
    }
    schedule();
  }

  void cancelTask(String taskId) {
    final beforeQueueLength = _queue.length;
    _queue.removeWhere((t) => t.taskId == taskId);
    final removedFromQueue = _queue.length < beforeQueueLength;

    final removedFromActive = _activeJobs.remove(taskId) != null;

    if (removedFromQueue || removedFromActive) {
      _taskProgress[taskId] = 1.0;
      _canceledTaskCount++;
      _updateProgressThrottled();
      schedule();
    }
  }

  Future<void> schedule() async {
    final shouldTriggerStart = _isIdle && (_queue.isNotEmpty || _activeJobs.isNotEmpty);

    while (_activeJobs.length < _maxConcurrentDownloads && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _activeJobs[task.taskId] = task;
      _doDownload(task);
    }

    if (shouldTriggerStart && _activeJobs.isNotEmpty && !_foregroundServiceStarted) {
      _isIdle = false;
      await onFirstTaskStarted?.call();
      _foregroundServiceStarted = true;
      _updateProgressThrottled();
    }
  }

  Future<void> _doDownload(_DownloadTaskEntry task) async {
    final args = task.args;
    final eventCallback = task.callback;
    final taskId = task.taskId;

    eventCallback(DownloadEventStart());
    _updateProgressThrottled();

    try {
      await yandeClient.downloadToFile(
        url: args.url,
        filePath: args.filePath,
        maxTaskCount: args.maxSegmentsPerTask,
        progressCallback: (received, total) {
          final progress = total == BigInt.zero ? 0.0 : received / total;
          _taskProgress[taskId] = progress.toDouble();
          eventCallback(DownloadEventProgress(progress.toDouble()));
          _updateProgressThrottled();
        },
      );
      _taskProgress[taskId] = 1.0;
      _completedTaskCount++;
      eventCallback(DownloadEventSuccess());
    } catch (e) {
      _taskProgress[taskId] = 1.0;
      _failedTaskCount++;
      eventCallback(DownloadEventError(e.toString()));
    }

    _activeJobs.remove(taskId);
    _updateProgressThrottled();

    schedule();

    if (_activeJobs.isEmpty && _queue.isEmpty) {
      _isIdle = true;
      await onAllTasksCompleted?.call();
      resetStats();
    }
  }

  void _updateProgressThrottled() {
    if (_throttleTimer?.isActive ?? false) return;

    _throttleTimer = Timer(const Duration(milliseconds: 200), () {
      _updateProgress();
    });
  }

  void _updateProgress() {
    if (!_foregroundServiceStarted) return;

    final finishedCount = _completedTaskCount + _failedTaskCount + _canceledTaskCount;
    final activeProgress = _taskProgress.values.fold(0.0, (a, b) => a + b);

    double overallProgress = 0.0;
    if (_totalTaskCount > 0) {
      overallProgress = (finishedCount + activeProgress) / _totalTaskCount;
      if (overallProgress > 1.0) overallProgress = 1.0;
    }

    onProgressChanged?.call(
      _totalTaskCount,
      _completedTaskCount,
      _failedTaskCount,
      _canceledTaskCount,
      overallProgress,
    );
  }

  void resetStats() {
    _totalTaskCount = 0;
    _completedTaskCount = 0;
    _failedTaskCount = 0;
    _canceledTaskCount = 0;
    _taskProgress.clear();
    _foregroundServiceStarted = false;
  }
}


class _DownloadTaskEntry {
  final String taskId;
  final _DownloadTaskArgs args;
  final void Function(DownloadEventBase) callback;

  _DownloadTaskEntry({required this.taskId, required this.args, required this.callback});
}
