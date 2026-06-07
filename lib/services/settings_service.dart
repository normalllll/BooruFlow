import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract interface class SettingsServiceStore {
  Map<String, dynamic> load();

  bool containsKey(String key);

  Future<void> write(String key, dynamic value);

  Future<void> writeAll(Map<String, dynamic> values);
}

final class HiveSettingsServiceStore implements SettingsServiceStore {
  HiveSettingsServiceStore(this._box);

  static Future<HiveSettingsServiceStore> open() async {
    await Hive.initFlutter();
    return HiveSettingsServiceStore(
      await Hive.openBox<dynamic>(SettingsService._boxName),
    );
  }

  final Box<dynamic> _box;

  @override
  Map<String, dynamic> load() {
    final values = <String, dynamic>{};
    for (final key in _box.keys) {
      if (key is String) {
        values[key] = _box.get(key);
      }
    }
    return values;
  }

  @override
  bool containsKey(String key) => _box.containsKey(key);

  @override
  Future<void> write(String key, dynamic value) {
    if (value == null) {
      return _box.delete(key);
    }
    return _box.put(key, value);
  }

  @override
  Future<void> writeAll(Map<String, dynamic> values) async {
    final valuesToPut = <String, dynamic>{};
    final keysToDelete = <String>[];

    for (final entry in values.entries) {
      if (entry.value == null) {
        keysToDelete.add(entry.key);
      } else {
        valuesToPut[entry.key] = entry.value;
      }
    }

    if (valuesToPut.isNotEmpty) {
      await _box.putAll(valuesToPut);
    }
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }
}

abstract interface class SettingsServiceMigrationSource {
  Future<Map<String, dynamic>> load();
}

final class JsonSettingsServiceMigrationSource
    implements SettingsServiceMigrationSource {
  JsonSettingsServiceMigrationSource(this._file);

  final File _file;

  @override
  Future<Map<String, dynamic>> load() async {
    if (!await _file.exists()) {
      return {};
    }

    try {
      final decoded = json.decode(await _file.readAsString());
      if (decoded is! Map) {
        return {};
      }

      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return {};
    }
  }
}

class SettingsService {
  SettingsService._();

  static const _boxName = 'settings';
  static const _legacyFileName = 'settings.json';
  static const _legacyMigrationCompletedKey = '_legacySettingsJsonMigrated';

  static const _languageKey = 'language';
  static const _themeModeKey = 'themeMode';
  static const _prefetchDnsKey = 'prefetchDns';
  static const _waterfallColumnsKey = 'waterfallColumns';
  static const _downloadPathKey = 'downloadPath';
  static const _maxConcurrentDownloadsKey = 'maxConcurrentDownloads';
  static const _maxSegmentsPerTaskKey = 'maxSegmentsPerTask';

  static const _settingKeys = {
    _languageKey,
    _themeModeKey,
    _prefetchDnsKey,
    _waterfallColumnsKey,
    _downloadPathKey,
    _maxConcurrentDownloadsKey,
    _maxSegmentsPerTaskKey,
  };

  static final Map<String, dynamic> _map = {};
  static SettingsServiceStore? _store;

  static int? get language => _map[_languageKey] as int?;

  static set language(int? value) {
    _write(_languageKey, value);
  }

  static int? get themeMode => _map[_themeModeKey] as int?;

  static set themeMode(int? value) {
    _write(_themeModeKey, value);
  }

  static bool get prefetchDns => _map[_prefetchDnsKey] as bool? ?? true;

  static set prefetchDns(bool value) {
    _write(_prefetchDnsKey, value);
  }

  static int? get waterfallColumns => _map[_waterfallColumnsKey] as int?;

  static set waterfallColumns(int? value) {
    _write(_waterfallColumnsKey, value);
  }

  static String? get downloadPath => _map[_downloadPathKey] as String?;

  static set downloadPath(String? value) {
    _write(_downloadPathKey, value);
  }

  static int get maxConcurrentDownloads =>
      _map[_maxConcurrentDownloadsKey] as int? ?? 2;

  static set maxConcurrentDownloads(int value) {
    _write(_maxConcurrentDownloadsKey, value);
    _maxConcurrentDownloadsStreamController.add(null);
  }

  static final _maxConcurrentDownloadsStreamController =
      StreamController<void>.broadcast();

  static final maxConcurrentDownloadsStream =
      _maxConcurrentDownloadsStreamController.stream;

  static int get maxSegmentsPerTask =>
      _map[_maxSegmentsPerTaskKey] as int? ?? 3;

  static set maxSegmentsPerTask(int value) {
    _write(_maxSegmentsPerTaskKey, value);
  }

  static Future<void> initialize({
    SettingsServiceStore? store,
    SettingsServiceMigrationSource? migrationSource,
  }) async {
    _store = store ?? await HiveSettingsServiceStore.open();

    final resolvedMigrationSource =
        migrationSource ??
        JsonSettingsServiceMigrationSource(await _legacySettingsFile());
    await _migrateLegacySettings(resolvedMigrationSource);

    _map
      ..clear()
      ..addAll(_filterSettings(_activeStore.load()));
  }

  static void _write(String key, dynamic value) {
    final store = _activeStore;
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
    unawaited(store.write(key, value));
  }

  static Future<void> _migrateLegacySettings(
    SettingsServiceMigrationSource source,
  ) async {
    final store = _activeStore;
    if (store.containsKey(_legacyMigrationCompletedKey)) {
      return;
    }

    final legacySettings = _filterSettings(await source.load());
    if (legacySettings.isEmpty) {
      return;
    }

    final settingsToMigrate = <String, dynamic>{};
    for (final entry in legacySettings.entries) {
      if (!store.containsKey(entry.key)) {
        settingsToMigrate[entry.key] = entry.value;
      }
    }

    if (settingsToMigrate.isNotEmpty) {
      await store.writeAll(settingsToMigrate);
    }
    await store.write(_legacyMigrationCompletedKey, true);
  }

  static Map<String, dynamic> _filterSettings(Map<String, dynamic> values) {
    final settings = <String, dynamic>{};
    for (final entry in values.entries) {
      if (_settingKeys.contains(entry.key) &&
          _isValidSettingValue(entry.key, entry.value)) {
        settings[entry.key] = entry.value;
      }
    }
    return settings;
  }

  static bool _isValidSettingValue(String key, dynamic value) {
    if (value == null) {
      return true;
    }

    return switch (key) {
      _languageKey ||
      _themeModeKey ||
      _waterfallColumnsKey ||
      _maxConcurrentDownloadsKey ||
      _maxSegmentsPerTaskKey => value is int,
      _prefetchDnsKey => value is bool,
      _downloadPathKey => value is String,
      _ => false,
    };
  }

  static SettingsServiceStore get _activeStore {
    final store = _store;
    if (store == null) {
      throw StateError(
        'SettingsService.initialize() must be called before writing settings.',
      );
    }
    return store;
  }

  static Future<File> _legacySettingsFile() async {
    if (Platform.isWindows || Platform.isLinux) {
      return File(path.join(Directory.current.path, _legacyFileName));
    }
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      final directory = await getApplicationDocumentsDirectory();
      return File(path.join(directory.path, _legacyFileName));
    }
    throw UnsupportedError('Unsupported platform');
  }
}
