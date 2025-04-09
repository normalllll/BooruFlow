import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yande_gui/i18n.dart';
import 'package:path/path.dart' as path;
import 'package:yande_gui/services/settings_service.dart';

import '../download_task.dart';
import '../downloader_platform.dart';
import 'download_queue_manger.dart';

class DownloaderIOS<T> extends DownloaderPlatform<T> {
  final _downloadQueueManager = DownloadQueueManager(getMaxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads);

  final MethodChannel _channel = MethodChannel('io.github.normalllll.yandegui/image_saver');

  Future<bool> saveImage(String filePath, String fileName) async {
    final bool result = await _channel.invokeMethod('saveImage', {'filePath': filePath, 'fileName': fileName});
    return result;
  }

  Future<bool> existImage(String fileName, int fileSize) async {
    final bool result = await _channel.invokeMethod('existImage', {'fileName': fileName});
    return result;
  }

  @override
  Future<void> init() async {
    SettingsService.maxConcurrentDownloadsStream.listen((_) {
      _downloadQueueManager.schedule();
    });
  }

  @override
  Future<bool> checkPrerequisites(DownloadTask task) async {
    PermissionStatus status = await Permission.photos.status;

    if (status.isPermanentlyDenied) {
      EasyLoading.showError(i18n.downloads.messages.photosPermanentlyDenied);
      await Future.delayed(const Duration(seconds: 2));
      openAppSettings();
      return false;
    }
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        EasyLoading.showError(i18n.downloads.messages.photosDenied);
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> handleTask(DownloadTask task) async {
    //TODO Standalone Swift native downloader
    final cacheDirectory = await getApplicationCacheDirectory();

    final downloadsCachePath = path.join(cacheDirectory.path, 'yande_gui');

    final filePath = path.join(downloadsCachePath, task.fileName);
    _downloadQueueManager.startTask(
      taskId: task.taskId,
      url: task.url,
      filePath: filePath,
      maxSegmentsPerTask: SettingsService.maxSegmentsPerTask,
      onEvent: (event) async {
        switch (event) {
          case DownloadEventStart():
            task.emit(DownloadTaskState(status: DownloadStatus.busying, progress: 0, error: null));
            break;
          case DownloadEventProgress(:final value):
            task.emit(task.state.copyWith(status: DownloadStatus.busying, progress: value));
            break;
          case DownloadEventSuccess():
            await saveImage(filePath, task.fileName);
            EasyLoading.showSuccess(i18n.downloads.messages.downloadCompletedWith(task.fileName));
            task.emit(task.state.copyWith(status: DownloadStatus.completed));
            break;
          case DownloadEventError(:final error):
            EasyLoading.showError(i18n.downloads.messages.downloadFailedWith(task.fileName));
            task.emit(task.state.copyWith(status: DownloadStatus.failed, error: error));
            break;
        }
      },
    );
  }

  @override
  void cancelTask(String taskId) {
    // TODO: implement cancelTask
  }
}
