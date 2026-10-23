import 'dart:async';
import 'package:booruflow/core/file_paths.dart';
import 'package:booruflow/core/hive_storage.dart';
import 'package:booruflow/core/legacy_upgrade.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:frost_ui/frost_ui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'background.dart';

abstract interface class SettingsServiceStore {
  Map<String, dynamic> load();

  Future<void> write(String key, dynamic value);
}

final class HiveSettingsServiceStore implements SettingsServiceStore {
  HiveSettingsServiceStore(this._box);

  static Future<HiveSettingsServiceStore> open() async {
    await initializeHiveStorage();
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
  static final _changes = StreamController<void>.broadcast(sync: true);
  static Stream<void> get changes => _changes.stream;
  SettingsService._();

  static const _boxName = 'settings';

  static const _languageKey = 'language';
  static const _themeModeKey = 'themeMode';
  static const _appearanceKey = 'appearance';
  static const _backgroundKey = 'background';
  static const _sidebarExpandedKey = 'sidebarExpanded';
  static const _predictiveBackKey = 'predictiveBack';
  static const _waterfallColumnsKey = 'waterfallColumns';
  static const _ugoiraExportKey = 'ugoiraExport';
  static const _downloadPathKey = 'downloadPath';
  static const _maxConcurrentDownloadsKey = 'maxConcurrentDownloads';
  static const _maxSegmentsPerTaskKey = 'maxSegmentsPerTask';
  static const _defaultSourceIdKey = 'defaultSourceId';
  static const _networkFallbackModeKey = 'booruNetworkFallbackMode';
  static const _dnsProviderKey = 'booruDnsProvider';
  static const _proxyUrlKey = 'booruProxyUrl';
  static const _ratingsKey = 'booruRatings';
  static const _networkChecksKey = 'booruNetworkChecks';

  static const _settingKeys = {
    legacySettingsVersionKey,
    _appearanceKey,
    _backgroundKey,
    _sidebarExpandedKey,
    _predictiveBackKey,
    _languageKey,
    _themeModeKey,
    _waterfallColumnsKey,
    _downloadPathKey,
    _ugoiraExportKey,
    _maxConcurrentDownloadsKey,
    _maxSegmentsPerTaskKey,
    _defaultSourceIdKey,
    _networkFallbackModeKey,
    _dnsProviderKey,
    _proxyUrlKey,
    _ratingsKey,
    _networkChecksKey,
  };

  static final Map<String, dynamic> _map = {};
  static SettingsServiceStore? _store;

  static FrostAppearance get appearance => FrostAppearance.fromRecord(
    _map[_appearanceKey],
    FrostPalettes.pink,
    fallbackMode: switch (themeMode) {
      0 => ThemeMode.light,
      1 => ThemeMode.dark,
      _ => ThemeMode.system,
    },
  );
  static bool customAccentSelected(Brightness brightness) {
    final field = brightness == Brightness.light
        ? 'lightCustomSelected'
        : 'darkCustomSelected';
    final stored = _map[_appearanceKey];
    final value = appearance;
    if (stored is Map && stored[field] is bool) {
      return stored[field] == true &&
          value.customAccentFor(brightness) == value.accentFor(brightness);
    }
    return value.customAccentFor(brightness) == value.accentFor(brightness);
  }

  static Future<void> saveAppearance(
    FrostAppearance value, {
    Brightness? accentBrightness,
    bool? customSelected,
  }) async {
    final record = value.toRecord();
    final previous = _map[_appearanceKey];
    for (final field in ['lightCustomSelected', 'darkCustomSelected']) {
      if (previous is Map && previous[field] is bool) {
        record[field] = previous[field];
      }
    }
    if (accentBrightness != null && customSelected != null) {
      record[accentBrightness == Brightness.light
              ? 'lightCustomSelected'
              : 'darkCustomSelected'] =
          customSelected;
    }
    await _activeStore.write(_appearanceKey, record);
    _map[_appearanceKey] = record;
    _changes.add(null);
  }

  static bool get predictiveBack => _map[_predictiveBackKey] as bool? ?? true;
  static set predictiveBack(bool value) => _write(_predictiveBackKey, value);

  static bool get sidebarExpanded => _map[_sidebarExpandedKey] as bool? ?? true;
  static set sidebarExpanded(bool value) => _write(_sidebarExpandedKey, value);

  static BackgroundSettings get background =>
      BackgroundSettings.fromRecord(_map[_backgroundKey]);
  static Future<void> saveBackground(BackgroundSettings value) async {
    final record = value.toRecord();
    await _activeStore.write(_backgroundKey, record);
    _map[_backgroundKey] = record;
    _changes.add(null);
  }

  static int? get language => _map[_languageKey] as int?;

  static set language(int? value) {
    _write(_languageKey, value);
  }

  static int? get themeMode => _map[_themeModeKey] as int?;

  // B0 retains the original UI until B1 installs the v2 appearance scope.
  static set themeMode(int? value) => _write(_themeModeKey, value);

  static int? get waterfallColumns => _map[_waterfallColumnsKey] as int?;

  static set waterfallColumns(int? value) {
    _write(_waterfallColumnsKey, value);
  }

  static UgoiraExport get ugoiraExport =>
      UgoiraExport.values
          .where((v) => v.name == _map[_ugoiraExportKey])
          .firstOrNull ??
      UgoiraExport.losslessWebp;
  static set ugoiraExport(UgoiraExport value) =>
      _write(_ugoiraExportKey, value.name);

  static String? get downloadPath => switch (_map[_downloadPathKey]) {
    final String value => normalizeLocalPath(value),
    _ => null,
  };

  static set downloadPath(String? value) {
    _write(_downloadPathKey, value == null ? null : normalizeLocalPath(value));
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

  static NetworkFallbackMode get networkFallbackMode =>
      NetworkFallbackMode.values
          .where((mode) => mode.name == _map[_networkFallbackModeKey])
          .firstOrNull ??
      NetworkFallbackMode.off;
  static set networkFallbackMode(NetworkFallbackMode value) =>
      _write(_networkFallbackModeKey, value.name);
  static RouteProvider get dnsProvider =>
      RouteProvider.values
          .where((provider) => provider.name == _map[_dnsProviderKey])
          .firstOrNull ??
      RouteProvider.uncensoredDns;
  static set dnsProvider(RouteProvider value) =>
      _write(_dnsProviderKey, value.name);

  static String? get proxyUrl {
    final value = (_map[_proxyUrlKey] as String?)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static set proxyUrl(String? value) => _write(_proxyUrlKey, value?.trim());

  static String? get savedNetworkChecks => _map[_networkChecksKey] as String?;

  static Future<void> saveNetworkChecks(String value) async {
    await _activeStore.write(_networkChecksKey, value);
    _map[_networkChecksKey] = value;
  }

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
        .whereType<String>()
        .map(
          (name) => ContentRating.values
              .where((rating) => rating.name == name)
              .firstOrNull,
        )
        .whereType<ContentRating>()
        .toList(growable: false);
  }

  static set ratings(List<ContentRating> value) =>
      _write(_ratingsKey, value.map((rating) => rating.name).toList());

  static Future<void> initialize({SettingsServiceStore? store}) async {
    _store = store ?? await HiveSettingsServiceStore.open();
    final stored = await upgradeLegacySettings(
      _activeStore.load(),
      _activeStore.write,
    );
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
    _changes.add(null);
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
      _appearanceKey => value is Map,
      _backgroundKey => value is Map,
      _sidebarExpandedKey || _predictiveBackKey => value is bool,
      _languageKey ||
      _themeModeKey ||
      _waterfallColumnsKey ||
      _maxConcurrentDownloadsKey ||
      _maxSegmentsPerTaskKey ||
      legacySettingsVersionKey => value is int,
      _networkFallbackModeKey =>
        value is String &&
            NetworkFallbackMode.values.any((mode) => mode.name == value),
      _dnsProviderKey =>
        value is String &&
            RouteProvider.values.any((provider) => provider.name == value),
      _ugoiraExportKey ||
      _downloadPathKey ||
      _defaultSourceIdKey ||
      _networkChecksKey ||
      _proxyUrlKey => value is String,
      _ratingsKey =>
        value is List &&
            value.every(
              (item) =>
                  item is String &&
                  ContentRating.values.any((rating) => rating.name == item),
            ),
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
