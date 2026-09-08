import 'dart:io';

import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:flutter/services.dart';

abstract interface class DownloadPermissionGuard {
  Future<void> ensureReadyForDownload();
}

final class NativeDownloadPermissionGuard implements DownloadPermissionGuard {
  const NativeDownloadPermissionGuard();

  static const _methodChannel = MethodChannel('booruflow/download_engine');

  @override
  Future<void> ensureReadyForDownload() async {
    try {
      await _methodChannel.invokeMethod<void>('prepareForDownload');
    } on PlatformException catch (error) {
      throw DownloadException(_nativePermissionMessage(error), error);
    }
  }

  String _nativePermissionMessage(PlatformException error) {
    return switch (error.code) {
      'permission_denied_permanent' =>
        'Download permission was denied. App settings were opened; grant permission there and try again.',
      'permission_denied' => 'Download permission was denied.',
      'permission_unavailable' =>
        'Download permission cannot be requested right now.',
      _ => error.message ?? 'Download permission check failed.',
    };
  }
}

final class DesktopDownloadPermissionGuard implements DownloadPermissionGuard {
  const DesktopDownloadPermissionGuard();

  @override
  Future<void> ensureReadyForDownload() async {
    final directory = Directory(await resolveDesktopDownloadDirectory());
    await ensureWritableDirectory(directory);
  }
}

final class UnsupportedDownloadPermissionGuard
    implements DownloadPermissionGuard {
  const UnsupportedDownloadPermissionGuard();

  @override
  Future<void> ensureReadyForDownload() {
    throw UnsupportedError('Downloads are not supported on this platform.');
  }
}
