import 'dart:async';
import 'dart:developer';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:meta/meta.dart';
import 'package:yande_gui/i18n.dart';
import 'download_task.dart';

abstract class DownloaderPlatform<T> {
  final _taskMap = <String, DownloadTask<T>>{};
  final _taskListController = StreamController<List<DownloadTask<T>>>.broadcast();

  Stream<List<DownloadTask<T>>> get taskListStream => _taskListController.stream;

  List<DownloadTask<T>> get taskList => _taskMap.values.toList();

  Future<void> init();

  Future<bool> checkPrerequisites(DownloadTask task);

  @mustCallSuper
  Future<void> addTask({required String taskId, required T inner, required String url, required String fileName}) async {
    if (_taskMap.values.any((task) => task.fileName == fileName)) {
      EasyLoading.showToast(i18n.downloads.messages.downloadTaskExists);
      return;
    }
    final task = DownloadTask(taskId: taskId, inner: inner, url: url, fileName: fileName);

    if (!await checkPrerequisites(task)) {
      return;
    }

    await handleTask(task);
    EasyLoading.showToast(i18n.downloads.messages.downloadStartWith(fileName));

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
          EasyLoading.showToast(i18n.downloads.messages.downloadRetryWith(task.fileName));
        } catch (e) {
          EasyLoading.showToast(i18n.downloads.messages.downloadFailedWith(task.fileName));
        }
      } else {
        log('retryAll skip:${task.fileName}, status:${task.state.status}');
      }
    }
  }

  @protected
  void removeTask(String taskId) {
    _taskMap.remove(taskId)?.dispose();
    _emitTaskList();
  }

  void cancelTask(String taskId);

  @protected
  void registerTaskState(DownloadTask<T> task) {
    _taskMap[task.taskId] = task;
    _emitTaskList();
  }

  void _emitTaskList() {
    _taskListController.add(_taskMap.values.toList(growable: false));
  }
}
