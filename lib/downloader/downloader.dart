import 'package:yande_gui/src/rust/yande/model/post.dart';

import 'download_task.dart';
import 'downloader_platform.dart';
import 'platform/downloader_desktop.dart' as desktop;
import 'platform/downloader_android.dart' as android;
import 'platform/downloader_ios.dart' as ios;
import 'dart:io';

class Downloader {
  static final Downloader instance = Downloader._internal();

  Downloader._internal();

  static bool _initialized = false;

  late final DownloaderPlatform<Post> _platform = _selectPlatformDownloader();

  DownloaderPlatform<Post> _selectPlatformDownloader() {
    if (Platform.isAndroid) {
      return android.DownloaderAndroid();
    } else if (Platform.isIOS) {
      return ios.DownloaderIOS();
    } else {
      return desktop.DownloaderDesktop();
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _platform.init();
  }

  int count = 0;

  Future<void> addTask({required String taskId, required Post inner, required String url, required String fileName}) {
    return _platform.addTask(taskId: taskId, inner: inner, url: url, fileName: fileName);
  }

  Future<void> startTask(String taskId) {
    return _platform.startTask(taskId);
  }

  Future<void> retryAll() {
    return _platform.retryAll();
  }

  Future<void> add(Post post) async {
    return _platform.addTask(
      taskId: (count++).toString(),
      inner: post,
      url: post.fileUrl ?? post.jpegUrl ?? post.previewUrl,
      fileName: '${post.id}.${post.fileExt}',
    );
  }

  Stream<List<DownloadTask<Post>>> get taskListStream {
    return _platform.taskListStream;
  }

  List<DownloadTask<Post>> get taskList => _platform.taskList;

  void cancelTask(String taskId) {
    _platform.cancelTask(taskId);
  }
}
