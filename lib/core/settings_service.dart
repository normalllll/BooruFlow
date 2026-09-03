import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yande_gui/src/rust/api/booru_models.dart';

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
  // Keep the legacy key so existing installations retain this preference.
  static const _bypassSniKey = 'prefetchDns';
  static const _waterfallColumnsKey = 'waterfallColumns';
  static const _downloadPathKey = 'downloadPath';
  static const _maxConcurrentDownloadsKey = 'maxConcurrentDownloads';
  static const _maxSegmentsPerTaskKey = 'maxSegmentsPerTask';
  static const _sourceIdKey = 'booruSourceId';
  static const _networkFallbackModeKey = 'booruNetworkFallbackMode';
  static const _fallbackToSystemDnsKey = 'booruFallbackToSystemDns';
  static const _proxyUrlKey = 'booruProxyUrl';
  static const _contentPolicyKey = 'booruContentPolicy';
  static const _ratingsKey = 'booruRatings';

  static const _settingKeys = {
    _languageKey,
    _themeModeKey,
    _bypassSniKey,
    _waterfallColumnsKey,
    _downloadPathKey,
    _maxConcurrentDownloadsKey,
    _maxSegmentsPerTaskKey,
    _sourceIdKey,
    _networkFallbackModeKey,
    _fallbackToSystemDnsKey,
    _proxyUrlKey,
    _contentPolicyKey,
    _ratingsKey,
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

  static bool get bypassSni => _map[_bypassSniKey] as bool? ?? true;

  static set bypassSni(bool value) {
    _write(_bypassSniKey, value);
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

  static String get sourceId => _map[_sourceIdKey] as String? ?? 'yande';

  static set sourceId(String value) => _write(_sourceIdKey, value);

  static NetworkFallbackMode get networkFallbackMode {
    final index = _map[_networkFallbackModeKey] as int?;
    if (index == null && _map[_bypassSniKey] == false) {
      return NetworkFallbackMode.off;
    }
    return index != null &&
            index >= 0 &&
            index < NetworkFallbackMode.values.length
        ? NetworkFallbackMode.values[index]
        : NetworkFallbackMode.persistedIpOverride;
  }

  static set networkFallbackMode(NetworkFallbackMode value) {
    _write(_networkFallbackModeKey, value.index);
    _write(_bypassSniKey, value != NetworkFallbackMode.off);
  }

  static bool get fallbackToSystemDns =>
      _map[_fallbackToSystemDnsKey] as bool? ?? true;

  static set fallbackToSystemDns(bool value) =>
      _write(_fallbackToSystemDnsKey, value);

  static String? get proxyUrl {
    final value = (_map[_proxyUrlKey] as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static set proxyUrl(String? value) => _write(_proxyUrlKey, value?.trim());

  static ContentPolicy get contentPolicy {
    final index = _map[_contentPolicyKey] as int?;
    return index != null && index >= 0 && index < ContentPolicy.values.length
        ? ContentPolicy.values[index]
        : ContentPolicy.unfiltered;
  }

  static set contentPolicy(ContentPolicy value) =>
      _write(_contentPolicyKey, value.index);

  static List<ContentRating> get ratings {
    final values = _map[_ratingsKey];
    if (values is! List) return const [];
    return values
        .whereType<int>()
        .where((index) => index >= 0 && index < ContentRating.values.length)
        .map((index) => ContentRating.values[index])
        .toList(growable: false);
  }

  static set ratings(List<ContentRating> value) =>
      _write(_ratingsKey, value.map((rating) => rating.index).toList());

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
      _networkFallbackModeKey || _contentPolicyKey => value is int,
      _bypassSniKey || _fallbackToSystemDnsKey => value is bool,
      _downloadPathKey || _sourceIdKey || _proxyUrlKey => value is String,
      _ratingsKey => value is List && value.every((item) => item is int),
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
