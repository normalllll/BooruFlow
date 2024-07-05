

class SettingsService {
  SettingsService._();

  static final _map = <String, dynamic>{};

  static int get themeMode => _map['themeMode'] as int? ?? 0;

  static set themeMode(int value) => _map['themeMode'] = value;

  static String? get downloadPath => _map['downloadPath'] as String?;

  static set downloadPath(String? value) => _map['downloadPath'] = value;
}
