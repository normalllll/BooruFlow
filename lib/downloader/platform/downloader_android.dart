import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:path/path.dart' as path;

import '../download_task.dart';
import '../downloader_platform.dart';
import 'download_queue_manger.dart';

class DownloaderAndroid<T> extends DownloaderPlatform<T> {
  final _downloadQueueManager = DownloadQueueManager(getMaxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads);

  final MethodChannel _channel = MethodChannel('io.github.normalllll.yandegui/image_saver');

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

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
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  Future<bool> checkPrerequisites(DownloadTask task) async {
    try {
      await _requestPermissions();
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt < 29) {
        PermissionStatus status = await Permission.storage.status;

        if (status.isPermanentlyDenied) {
          EasyLoading.showError(i18n.downloads.messages.storagePermanentlyDenied);
          await Future.delayed(const Duration(seconds: 2));
          openAppSettings();
          return false;
        }
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            EasyLoading.showError(i18n.downloads.messages.storageDenied);
            return false;
          }
        }
      }
    } catch (e) {
      EasyLoading.showError(i18n.downloads.messages.deviceInfoError);
      return false;
    }

    if (await existImage(task.fileName, 0)) {
      EasyLoading.showError(i18n.downloads.messages.imageFileExists);
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
            FlutterForegroundTask.startService(notificationTitle: 'Yande GUI Downloader', notificationText: 'Downloading...');
            task.emit(task.state.copyWith(status: DownloadStatus.busying));
            break;
          case DownloadEventProgress(:final value):
            FlutterForegroundTask.updateService(
              notificationTitle: 'Yande GUI Downloader',
              notificationText: '${task.fileName} ${(value * 100).toStringAsFixed(2)}%',
            );
            task.emit(task.state.copyWith(status: DownloadStatus.busying, progress: value));
            break;
          case DownloadEventSuccess():
            await saveImage(filePath, task.fileName);
            FlutterForegroundTask.stopService();
            EasyLoading.showSuccess(i18n.downloads.messages.downloadCompletedWith(task.fileName));
            task.emit(task.state.copyWith(status: DownloadStatus.completed));
            break;
          case DownloadEventError(:final error):
            FlutterForegroundTask.stopService();
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
