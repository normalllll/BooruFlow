import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yande_gui/services/settings_service.dart';

class ImageSaver {
  static const MethodChannel _channel = MethodChannel('io.github.normalllll.yandegui/image_saver');

  static Future<bool> saveImage(Uint8List imageBytes, String filename) async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final bool result = await _channel.invokeMethod('saveImage', {
          'imageBytes': imageBytes,
          'filename': filename,
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
          file = File(path.join(downloadDir!.path, 'yande', filename));
        }
        await file.create(recursive: true);
        await file.writeAsBytes(imageBytes);
        return true;
      } catch (e) {
        EasyLoading.showError(e.toString());
        print(e);
        return false;
      }
    }
  }

  static Future<bool> existImage(String filename, int fileSize) async {
    if (Platform.isAndroid) {
      try {
        final bool result = await _channel.invokeMethod('existImage', {
          'filename': filename,
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
          file = File(path.join(downloadDir!.path, 'yande', filename));
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
