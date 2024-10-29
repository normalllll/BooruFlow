import 'dart:io';
import 'dart:isolate';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/image_saver.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';
import 'package:yande_gui/src/rust/frb_generated.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:path/path.dart' as path;

part 'logic.g.dart';

enum DownloadTaskStateType {
  idle,
  waiting,
  busying,
  completed,
  failed,
}

class DownloadTaskState {
  final Post post;
  final double progress;
  final DownloadTaskStateType type;

  DownloadTaskState({
    required this.post,
    required this.progress,
    required this.type,
  });

  DownloadTaskState copyWith({
    Post? post,
    double? progress,
    DownloadTaskStateType? type,
  }) {
    return DownloadTaskState(
      post: post ?? this.post,
      progress: progress ?? this.progress,
      type: type ?? this.type,
    );
  }
}

class DownloaderState {
  final List<DownloadTaskProvider> tasks;

  DownloaderState({
    required this.tasks,
  });

  DownloaderState copyWith({
    List<DownloadTaskProvider>? tasks,
  }) {
    return DownloaderState(
      tasks: tasks ?? this.tasks,
    );
  }
}

@Riverpod(keepAlive: true)
class Downloader extends _$Downloader {
  static SendPort? isolateSendPort;

  @override
  DownloaderState build() {
    return DownloaderState(
      tasks: [],
    );
  }

  static Future<void> initIsolate() async {
    if (isolateSendPort == null) {
      final receivePort = ReceivePort();
      await Isolate.spawn(
        _isolateDownloader,
        _DownloadIsolateConfig(
          ips: realIps,
          maxActiveDownloadTasks: SettingsService.maxConcurrentDownloads,
          mainSendPort: receivePort.sendPort,
        ),
      );

      isolateSendPort = await receivePort.first as SendPort;
    }
  }

  static void updateDownloadIsolateMaxActiveDownloadTasks(int value) {
    isolateSendPort?.send(_DownloadIsolateUpdate(maxConcurrentDownloads: value));
  }

  Future<DownloadTaskProvider?> addTask(Post post) async {
    await initIsolate();
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt < 29) {
          PermissionStatus status = await Permission.storage.status;

          if (status.isPermanentlyDenied) {
            EasyLoading.showError(i18n.downloads.messages.storagePermanentlyDenied);
            await Future.delayed(const Duration(seconds: 2));
            openAppSettings();
            return null;
          }
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) {
              EasyLoading.showError(i18n.downloads.messages.storageDenied);
              return null;
            }
          }
        }
      } catch (e) {
        EasyLoading.showError(i18n.downloads.messages.deviceInfoError);
        return null;
      }
    } else if (Platform.isIOS) {
      PermissionStatus status = await Permission.photos.status;

      if (status.isPermanentlyDenied) {
        EasyLoading.showError(i18n.downloads.messages.photosPermanentlyDenied);
        await Future.delayed(const Duration(seconds: 2));
        openAppSettings();
        return null;
      }
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          EasyLoading.showError(i18n.downloads.messages.photosDenied);
          return null;
        }
      }
    }

    if (state.tasks.any((provider) => provider.post.id == post.id)) {
      EasyLoading.showToast(i18n.downloads.messages.downloadTaskExists);
      return null;
    }
    if (await ImageSaver.existImage('${post.id}.${post.fileExt}', post.fileSize)) {
      EasyLoading.showToast(i18n.downloads.messages.imageFileExists);
      return null;
    }
    final provider = downloadTaskProvider(post: post);
    state = state.copyWith(tasks: [...state.tasks, provider]);
    return provider;
  }
}

@Riverpod(keepAlive: true)
class DownloadTask extends _$DownloadTask {
  @override
  DownloadTaskState build({required Post post}) {
    return DownloadTaskState(
      post: post,
      progress: 0,
      type: DownloadTaskStateType.waiting,
    );
  }

  void updateProgress(BigInt received, BigInt total) {
    state = state.copyWith(progress: received / total);
  }

  Future<void> doDownload({bool retry = false}) async {
    if (retry) {
      if (state.type != DownloadTaskStateType.failed) {
        return;
      }
      state = state.copyWith(type: DownloadTaskStateType.waiting);

      EasyLoading.showToast(i18n.downloads.messages.downloadRetryWithId(state.post.id));
    } else {
      EasyLoading.showToast(i18n.downloads.messages.downloadStartWithId(state.post.id));
    }

    final ReceivePort receivePort = ReceivePort('DownloadTask:${post.id}');

    final cacheDirectory = await getApplicationCacheDirectory();

    final downloadsCachePath = path.join(cacheDirectory.path, 'downloads');

    final filePath = path.join(downloadsCachePath, 'file-${post.id}.${state.post.fileExt}');

    Downloader.isolateSendPort?.send(
      _DownloadTaskArgs(
        url: state.post.fileUrl ?? state.post.jpegUrl,
        filePath: filePath,
        maxSegmentsPerTask: SettingsService.maxSegmentsPerTask,
        taskSendPort: receivePort.sendPort,
      ),
    );

    await for (final message in receivePort) {
      if (message is _DownloadProgress) {
        state = state.copyWith(progress: message.value, type: state.type != DownloadTaskStateType.busying ? DownloadTaskStateType.busying : null);
      } else if (message is _DownloadSuccess) {
        try {
          ImageSaver.saveImage(filePath, '${state.post.id}.${state.post.fileExt}');
          EasyLoading.showSuccess(i18n.downloads.messages.downloadCompletedWithId(state.post.id));
          state = state.copyWith(type: DownloadTaskStateType.completed);
        } catch (e) {
          EasyLoading.showError(i18n.downloads.messages.saveFailedWith(state.post.id));
          if (kDebugMode) {
            print(e);
          }
          state = state.copyWith(type: DownloadTaskStateType.failed);
        }
      } else if (message is _DownloadError) {
        EasyLoading.showError(i18n.downloads.messages.downloadFailedWithId(state.post.id));
        if (kDebugMode) {
          print(message.error);
        }
        state = state.copyWith(type: DownloadTaskStateType.failed);
      }
    }
  }
}

void _isolateDownloader(_DownloadIsolateConfig args) async {
  final receivePort = ReceivePort();

  // Send the receive port to the main thread
  args.mainSendPort.send(receivePort.sendPort);

  await RustLib.init();
  final downloadClient = YandeClient(
      ips: switch (args.ips) {
        final ips? => StringArray3(ips),
        _ => null,
      },
      forLargeFile: true);

  int maxConcurrentDownloads = args.maxActiveDownloadTasks;

  int activeDownloadTasks = 0;

  final taskQueue = <_DownloadTaskArgs>[];

  Future<void> processDownloadTask(_DownloadTaskArgs task) async {
    final String url = task.url;
    final String savePath = task.filePath;
    final SendPort taskSendPort = task.taskSendPort;

    try {
      taskSendPort.send(_DownloadProgress(0));
      // Execute the download task
      await downloadClient.downloadToFile(
        url: url,
        filePath: savePath,
        maxTaskCount: task.maxSegmentsPerTask,
        progressCallback: (received, total) {
          taskSendPort.send(_DownloadProgress(total == BigInt.zero ? 0 : received / total));
        },
      );
      // Notify task success
      taskSendPort.send(_DownloadSuccess());
    } catch (e) {
      // Send error message
      taskSendPort.send(_DownloadError(e.toString()));
    }
  }

  // Function to schedule tasks, ensuring the maximum download task limit is respected
  Future<void> scheduleTasks() async {
    // If the maximum limit is reached or no tasks are left, return
    if (activeDownloadTasks >= maxConcurrentDownloads || taskQueue.isEmpty) {
      return;
    }
    // Dequeue a task and increment the number of active tasks
    final task = taskQueue.removeAt(0);
    activeDownloadTasks++;
    // Start processing the download task
    await processDownloadTask(task);

    // Once the task is complete, decrement the number of active tasks and continue checking
    activeDownloadTasks--;

    // After the task is completed, call scheduleTasks to continue scheduling new tasks
    scheduleTasks();
  }

  // Receive and handle messages from the main thread
  await for (final message in receivePort) {
    if (message is _DownloadTaskArgs) {
      // Add the task to the queue
      taskQueue.add(message);

      // Check if new tasks can be executed
      scheduleTasks();
    } else if (message is _DownloadIsolateUpdate) {
      maxConcurrentDownloads = message.maxConcurrentDownloads;
      scheduleTasks();
    }
  }
}

class _DownloadIsolateConfig {
  final List<String>? ips;
  final int maxActiveDownloadTasks;
  final SendPort mainSendPort;

  _DownloadIsolateConfig({required this.ips, required this.maxActiveDownloadTasks, required this.mainSendPort});
}

class _DownloadIsolateUpdate {
  final int maxConcurrentDownloads;

  _DownloadIsolateUpdate({required this.maxConcurrentDownloads});
}

class _DownloadTaskArgs {
  final String url;
  final String filePath;
  final int maxSegmentsPerTask;
  final SendPort taskSendPort;

  _DownloadTaskArgs({
    required this.url,
    required this.filePath,
    required this.maxSegmentsPerTask,
    required this.taskSendPort,
  });
}

class _DownloadProgress {
  double value;

  _DownloadProgress(this.value);
}

class _DownloadSuccess {}

class _DownloadError {
  String error;

  _DownloadError(this.error);
}
