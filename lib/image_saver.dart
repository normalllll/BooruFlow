import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yande_gui/services/settings_service.dart';

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

class ImageSaver {
  static const MethodChannel _channel = MethodChannel('io.github.normalllll.yandegui/image_saver');

  static Future<bool> saveImage(String filePath, String fileName) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final bool result = await _channel.invokeMethod('saveImage', {
          'filePath': filePath,
          'fileName': fileName,
        });
        return result;
      } else {
        final downloadDir = await getDownloadsDirectory();
        final String targetPath;
        if (SettingsService.downloadPath case String downloadPath) {
          targetPath = path.join(downloadPath, fileName);
        } else {
          targetPath = path.join(downloadDir!.path, 'YandeGUI', fileName);
        }
        await _moveFile(filePath, targetPath);
        return true;
      }
    } catch (e) {
      EasyLoading.showError(e.toString());
      print(e);
      return false;
    } finally {
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await File(filePath).delete();
        } catch (_) {}
      }
    }
  }

  static Future<bool> existImage(String filename, int fileSize) async {
    if (Platform.isAndroid) {
      try {
        final bool result = await _channel.invokeMethod('existImage', {
          'fileName': filename,
          'fileSize': fileSize,
        });
        return result;
      } catch (e) {
        print(e);
        return false;
      }
    } else {
      try {
        final downloadDir = await getDownloadsDirectory();
        final File file;
        if (SettingsService.downloadPath case String downloadPath) {
          file = File(path.join(downloadPath, filename));
        } else {
          file = File(path.join(downloadDir!.path, 'YandeGUI', filename));
        }
        return await file.exists() && await file.length() == fileSize;
      } catch (e) {
        EasyLoading.showError(e.toString());
        print(e);
        return false;
      }
    }
  }
}
