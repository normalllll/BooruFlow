import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

abstract interface class SettingsServiceStore {
  Map<String, dynamic> load();

  Future<void> write(String key, dynamic value);
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
  Future<void> write(String key, dynamic value) {
    if (value == null) {
      return _box.delete(key);
    }
    return _box.put(key, value);
  }
}

class SettingsService {
  static final changes = ValueNotifier<int>(0);
  SettingsService._();

  static const _boxName = 'settings';

  static const _languageKey = 'language';
  static const _themeModeKey = 'themeMode';
  static const _waterfallColumnsKey = 'waterfallColumns';
  static const _downloadPathKey = 'downloadPath';
  static const _maxConcurrentDownloadsKey = 'maxConcurrentDownloads';
  static const _maxSegmentsPerTaskKey = 'maxSegmentsPerTask';
  static const _defaultSourceIdKey = 'defaultSourceId';
  static const _networkFallbackModeKey = 'booruNetworkFallbackMode';
  static const _fallbackToSystemDnsKey = 'booruFallbackToSystemDns';
  static const _proxyUrlKey = 'booruProxyUrl';
  static const _ratingsKey = 'booruRatings';

  static const _settingKeys = {
    _languageKey,
    _themeModeKey,
    _waterfallColumnsKey,
    _downloadPathKey,
    _maxConcurrentDownloadsKey,
    _maxSegmentsPerTaskKey,
    _defaultSourceIdKey,
    _networkFallbackModeKey,
    _fallbackToSystemDnsKey,
    _proxyUrlKey,
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

  static String get defaultSourceId =>
      _map[_defaultSourceIdKey] as String? ?? 'yande';

  static set defaultSourceId(String value) =>
      _write(_defaultSourceIdKey, value);

  static NetworkFallbackMode get networkFallbackMode {
    final index = _map[_networkFallbackModeKey] as int?;
    return index != null &&
            index >= 0 &&
            index < NetworkFallbackMode.values.length
        ? NetworkFallbackMode.values[index]
        : NetworkFallbackMode.persistedIpOverride;
  }

  static set networkFallbackMode(NetworkFallbackMode value) {
    _write(_networkFallbackModeKey, value.index);
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

  /// Empty means no additional rating restriction.
  static const configurableRatings = [
    ContentRating.general,
    ContentRating.sensitive,
    ContentRating.questionable,
    ContentRating.explicit,
  ];

  /// Empty means no additional rating restriction.
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

  static Future<void> initialize({SettingsServiceStore? store}) async {
    _store = store ?? await HiveSettingsServiceStore.open();
    final stored = _activeStore.load();
    final current = _filterSettings(stored);
    for (final key in stored.keys.where((key) => !current.containsKey(key))) {
      await _activeStore.write(key, null);
    }
    _map
      ..clear()
      ..addAll(current);
  }

  static void _write(String key, dynamic value) {
    final store = _activeStore;
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
    unawaited(store.write(key, value));
    changes.value++;
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
      _networkFallbackModeKey => value is int,
      _fallbackToSystemDnsKey => value is bool,
      _downloadPathKey ||
      _defaultSourceIdKey ||
      _proxyUrlKey => value is String,
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
}
