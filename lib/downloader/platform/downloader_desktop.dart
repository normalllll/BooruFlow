import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:path/path.dart' as path;

import '../download_task.dart';
import '../downloader_platform.dart';
import 'download_queue_manger.dart';

class DownloaderDesktop<T> extends DownloaderPlatform<T> {
  final _downloadQueueManager = DownloadQueueManager(getMaxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads);

  Future<void> _moveFile(String sourcePath, String targetPath) async {
    final sourceFile = File(sourcePath);
    final targetFile = File(targetPath);

    final targetDir = targetFile.parent;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    try {
      await sourceFile.rename(targetPath);
    } catch (e) {
      try {
        await sourceFile.copy(targetPath);
        await sourceFile.delete();
      } catch (e) {
        rethrow;
      }
    }
  }

  @override
  Future<void> init() async {
    // no init
  }

  @override
  Future<bool> checkPrerequisites(DownloadTask task) async {
    final downloadDir = await getDownloadsDirectory();
    final File file;
    if (SettingsService.downloadPath case String downloadPath) {
      file = File(path.join(downloadPath, task.fileName));
    } else {
      file = File(path.join(downloadDir!.path, 'YandeGUI', task.fileName));
    }
    if (await file.exists()) {
      EasyLoading.showError(i18n.downloads.messages.imageFileExists);
      return false;
    }
    return true;
  }

  @override
  Future<void> handleTask(DownloadTask task) async {
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
            task.emit(task.state.copyWith(status: DownloadStatus.busying));
            break;
          case DownloadEventProgress(:final value):
            task.emit(task.state.copyWith(status: DownloadStatus.busying, progress: value));
            break;
          case DownloadEventSuccess():
            final downloadDir = await getDownloadsDirectory();
            final String targetPath;
            if (SettingsService.downloadPath case String downloadPath) {
              targetPath = path.join(downloadPath, task.fileName);
            } else {
              targetPath = path.join(downloadDir!.path, 'YandeGUI', task.fileName);
            }
            await _moveFile(filePath, targetPath);

            EasyLoading.showSuccess(i18n.downloads.messages.downloadCompletedWith(task.fileName));
            task.emit(task.state.copyWith(status: DownloadStatus.completed));
            break;
          case DownloadEventError(:final error):
            print('download error:$error');
            EasyLoading.showError(i18n.downloads.messages.downloadFailedWith(task.fileName));
            task.emit(task.state.copyWith(status: DownloadStatus.failed, error: error));
            break;
        }
      },
    );
  }

  @override
  void cancelTask(String taskId) {}
}
