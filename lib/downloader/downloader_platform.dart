import 'dart:async';
import 'dart:developer';
import 'package:meta/meta.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/services/app_toast.dart';
import 'download_task.dart';

abstract class DownloaderPlatform<T> {
  final _taskMap = <String, DownloadTask<T>>{};
  final _taskSubscriptions = <String, StreamSubscription<DownloadTaskState>>{};
  final _taskListController =
      StreamController<List<DownloadTask<T>>>.broadcast();

  Stream<List<DownloadTask<T>>> get taskListStream =>
      _taskListController.stream;

  List<DownloadTask<T>> get taskList => _taskMap.values.toList();

  Future<void> init();

  Future<bool> checkPrerequisites(DownloadTask task);

  @mustCallSuper
  Future<void> addTask({
    required String taskId,
    required T inner,
    required String url,
    required String fileName,
  }) async {
    if (_taskMap.values.any((task) => task.fileName == fileName)) {
      AppToast.show(i18n.downloads.messages.downloadTaskExists);
      return;
    }
    final task = DownloadTask(
      taskId: taskId,
      inner: inner,
      url: url,
      fileName: fileName,
    );

    if (!await checkPrerequisites(task)) {
      return;
    }

    await handleTask(task);
    AppToast.show(i18n.downloads.messages.downloadStartWith(name: fileName));

    registerTaskState(task);
  }

  Future<void> handleTask(DownloadTask<T> task);

  Future<void> startTask(String taskId) async {
    final task = _taskMap[taskId];
    if (task != null) {
      if (!await checkPrerequisites(task)) {
        return;
      }
      await handleTask(task);
    }
  }

  Future<void> retryAll() async {
    for (final task in _taskMap.values) {
      if (task.state.status == DownloadStatus.failed) {
        try {
          await handleTask(task);
          AppToast.show(
            i18n.downloads.messages.downloadRetryWith(name: task.fileName),
          );
        } catch (e) {
          AppToast.error(
            i18n.downloads.messages.downloadFailedWith(name: task.fileName),
          );
        }
      } else {
        log('retryAll skip:${task.fileName}, status:${task.state.status}');
      }
    }
  }

  @protected
  void removeTask(String taskId) {
    _taskSubscriptions.remove(taskId)?.cancel();
    _taskMap.remove(taskId)?.dispose();
    _emitTaskList();
  }

  void cancelTask(String taskId);

  @protected
  void registerTaskState(DownloadTask<T> task) {
    _taskMap[task.taskId] = task;
    _taskSubscriptions.remove(task.taskId)?.cancel();
    _taskSubscriptions[task.taskId] = task.stream.listen((_) {
      _emitTaskList();
    });
    _emitTaskList();
  }

  void _emitTaskList() {
    _taskListController.add(_taskMap.values.toList(growable: false));
  }
}
