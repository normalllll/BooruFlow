import 'dart:io';

import 'package:booruflow/core/downloads/models/download_job.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_platform.g.dart';

/// Storage capabilities follow the real OS, independently of window width.
enum DownloadPlatform {
  desktop,
  android,
  ios;

  static DownloadPlatform get current => Platform.isAndroid
      ? android
      : Platform.isIOS
      ? ios
      : desktop;
  static DownloadPlatform fromTargetPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android => android,
        TargetPlatform.iOS => ios,
        _ => desktop,
      };
  bool get canChooseDirectory => this == desktop;
  bool get canRevealDirectory => this == desktop;

  /// Preserve original bytes for formats Photos cannot reliably retain.
  /// Animated WebP is kept in Files rather than risking animation loss.
  bool usesFiles(DownloadJob job) =>
      this == ios &&
      (job.ugoiraExport != null ||
          !const {
            '.jpg',
            '.jpeg',
            '.png',
            '.gif',
            '.heic',
            '.heif',
            '.tif',
            '.tiff',
            '.mp4',
            '.mov',
            '.m4v',
          }.contains(p.extension(job.filename).toLowerCase()));
  static const androidDirectories =
      'Pictures/BooruFlow · Movies/BooruFlow · Download/BooruFlow';
}

@riverpod
DownloadPlatform downloadPlatform(Ref ref) => DownloadPlatform.current;

/// Existing read access is observed, never requested for a single photo save.
enum IosPhotosReadAccess {
  notDetermined,
  denied,
  restricted,
  authorized,
  limited;

  // PhotoKit limited access cannot create or fetch user albums.
  bool get mayUseDefaultAlbum => this == authorized;
  static IosPhotosReadAccess parse(String? value) =>
      values.where((item) => item.name == value).firstOrNull ?? notDetermined;
}
