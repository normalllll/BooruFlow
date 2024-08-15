import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsService {
  SettingsService._();

  static late final File _file;

  static const _fileName = 'settings.json';

  static final Map<String, dynamic> _map = {};

  static int get language => _map['language'] as int? ?? 0;

  static set language(int value) {
    _map['language'] = value;
    _save();
  }

  static int get themeMode => _map['themeMode'] as int? ?? 0;

  static set themeMode(int value) {
    _map['themeMode'] = value;
    _save();
  }

  static String? get downloadPath => _map['downloadPath'] as String?;

  static set downloadPath(String? value) {
    _map['downloadPath'] = value;
    _save();
  }

  static void _save() {
    _file.writeAsStringSync(json.encode(_map));
  }

  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      _file = File(path.join(Directory.current.path, _fileName));
    } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      _file = File(path.join(directory.path, _fileName));
    } else {
      throw UnsupportedError('Unsupported platform');
    }
    if (await _file.exists()) {
      try {
        _map.addAll(json.decode(_file.readAsStringSync()));
      } catch (_) {}
    }
  }
}
