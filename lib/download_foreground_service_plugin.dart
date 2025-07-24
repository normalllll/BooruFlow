import 'dart:io';
import 'package:flutter/services.dart';

class DownloadForegroundServicePlugin {
  static const MethodChannel _channel = MethodChannel('foreground_service_plugin');

  static Future<void> startService({required String title, required String text}) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('startService', {'title': title, 'text': text});
    }
  }

  static Future<void> updateProgress({required String title, required String text, int? progress}) async {
    if (Platform.isAndroid) {
      final args = {'title': title, 'text': text, 'progress': progress};

      await _channel.invokeMethod('updateProgress', args);
    }
  }

  static Future<void> stopService() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('stopService');
    }
  }
}
