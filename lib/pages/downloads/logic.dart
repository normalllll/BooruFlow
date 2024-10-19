import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/image_saver.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

part 'logic.g.dart';

enum DownloadTaskStateType {
  idle,
  busy,
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
  @override
  DownloaderState build() {
    return DownloaderState(
      tasks: [],
    );
  }

  Future<DownloadTaskProvider?> addTask(Post post) async {
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
      type: DownloadTaskStateType.busy,
    );
  }

  void updateProgress(BigInt received, BigInt total) {
    state = state.copyWith(progress: received / total);
  }

  Future<void> doDownload({bool retry = false}) async {
    state = state.copyWith(type: DownloadTaskStateType.busy, progress: 0);
    if (retry) {
      EasyLoading.showToast(i18n.downloads.messages.downloadRetryWithId(state.post.id));
    } else {
      EasyLoading.showToast(i18n.downloads.messages.downloadStartWithId(state.post.id));
    }
    yandeClient.downloadToMemory(url: state.post.fileUrl ?? state.post.jpegUrl, progressCallback: (received, total) => updateProgress(received, total)).then((bytes) {
      try {
        ImageSaver.saveImage(bytes, '${state.post.id}.${state.post.fileExt}');
        EasyLoading.showSuccess(i18n.downloads.messages.downloadCompletedWithId(state.post.id));
        state = state.copyWith(type: DownloadTaskStateType.completed);
      } catch (e) {
        EasyLoading.showError(i18n.downloads.messages.saveFailedWith(state.post.id));
        if (kDebugMode) {
          print(e);
        }
        state = state.copyWith(type: DownloadTaskStateType.failed);
      }
    }).catchError((e) {
      EasyLoading.showError(i18n.downloads.messages.downloadFailedWithId(state.post.id));
      state = state.copyWith(type: DownloadTaskStateType.failed);
    });
  }
}
