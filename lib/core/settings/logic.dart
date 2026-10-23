import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:frost_ui/frost_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'background.dart';

part 'logic.g.dart';

/// Persistence boundary; widgets only observe [settingsProvider].
class SettingsRepository {
  const SettingsRepository();
  Stream<void> get changes => SettingsService.changes;
  AppSettings read() => AppSettings(
    language: SettingsService.language,
    themeMode: SettingsService.themeMode,
    appearance: SettingsService.appearance,
    lightCustomSelected: SettingsService.customAccentSelected(Brightness.light),
    darkCustomSelected: SettingsService.customAccentSelected(Brightness.dark),
    background: SettingsService.background,
    sidebarExpanded: SettingsService.sidebarExpanded,
    predictiveBack: SettingsService.predictiveBack,
    waterfallColumns: SettingsService.waterfallColumns,
    downloadPath: SettingsService.downloadPath,
    ugoiraExport: SettingsService.ugoiraExport,
    maxConcurrentDownloads: SettingsService.maxConcurrentDownloads,
    maxSegmentsPerTask: SettingsService.maxSegmentsPerTask,
    defaultSourceId: SettingsService.defaultSourceId,
    ratings: SettingsService.ratings,
  );
  void setPredictiveBack(bool value) => SettingsService.predictiveBack = value;
  void setSidebarExpanded(bool value) =>
      SettingsService.sidebarExpanded = value;
  void setLanguage(int? value) => SettingsService.language = value;
  void setThemeMode(int? value) => SettingsService.themeMode = value;
  Future<void> setAppearance(
    FrostAppearance value, {
    Brightness? accentBrightness,
    bool? customSelected,
  }) => SettingsService.saveAppearance(
    value,
    accentBrightness: accentBrightness,
    customSelected: customSelected,
  );
  Future<void> setBackground(BackgroundSettings value) =>
      SettingsService.saveBackground(value);
  void setColumns(int? value) => SettingsService.waterfallColumns = value;
  void setDownloadPath(String? value) => SettingsService.downloadPath = value;
  void setConcurrency(int value) =>
      SettingsService.maxConcurrentDownloads = value;
  void setUgoiraExport(UgoiraExport value) =>
      SettingsService.ugoiraExport = value;
  void setSegments(int value) => SettingsService.maxSegmentsPerTask = value;
  void setDefaultSource(String value) =>
      SettingsService.defaultSourceId = value;
  void setRatings(List<ContentRating> value) => SettingsService.ratings = value;
}

class AppSettings {
  AppSettings({
    required this.language,
    required this.themeMode,
    required this.appearance,
    required this.lightCustomSelected,
    required this.darkCustomSelected,
    required this.background,
    required this.sidebarExpanded,
    this.predictiveBack = true,
    required this.waterfallColumns,
    required this.downloadPath,
    this.ugoiraExport = UgoiraExport.losslessWebp,
    required this.maxConcurrentDownloads,
    required this.maxSegmentsPerTask,
    required this.defaultSourceId,
    required List<ContentRating> ratings,
  }) : ratings = List.unmodifiable(ratings);
  final FrostAppearance appearance;
  final bool lightCustomSelected, darkCustomSelected;
  final BackgroundSettings background;
  final bool sidebarExpanded, predictiveBack;
  final int? language, themeMode, waterfallColumns;
  final UgoiraExport ugoiraExport;
  final String? downloadPath;
  final int maxConcurrentDownloads, maxSegmentsPerTask;
  final String defaultSourceId;
  final List<ContentRating> ratings;
  AppSettings withBackground(BackgroundSettings value) => AppSettings(
    language: language,
    themeMode: themeMode,
    appearance: appearance,
    lightCustomSelected: lightCustomSelected,
    darkCustomSelected: darkCustomSelected,
    background: value,
    sidebarExpanded: sidebarExpanded,
    predictiveBack: predictiveBack,
    waterfallColumns: waterfallColumns,
    downloadPath: downloadPath,
    ugoiraExport: ugoiraExport,
    maxConcurrentDownloads: maxConcurrentDownloads,
    maxSegmentsPerTask: maxSegmentsPerTask,
    defaultSourceId: defaultSourceId,
    ratings: ratings,
  );
}

/// Android exposes gesture progress through OnBackAnimationCallback from API 34.
/// Read the real OS version, independently of theme platform or window size.
/// Other OSes do not expose that Android system capability.
@Riverpod(keepAlive: true)
Future<bool> predictiveBackAvailable(Ref ref) async {
  final info = await DeviceInfoPlugin().deviceInfo;
  return info is AndroidDeviceInfo && info.version.sdkInt >= 34;
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => const SettingsRepository();

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  int? _previewIntensity;
  Future<void> _backgroundWrite = Future<void>.value();
  int _backgroundRevision = 0;
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);
  @override
  AppSettings build() {
    final repository = ref.watch(settingsRepositoryProvider);
    final subscription = repository.changes.listen((_) {
      final saved = repository.read();
      state = _previewIntensity == null
          ? saved
          : saved.withBackground(
              saved.background.copyWith(intensity: _previewIntensity),
            );
    });
    ref.onDispose(subscription.cancel);
    return repository.read();
  }

  void setPredictiveBack(bool value) => _repository.setPredictiveBack(value);
  void setSidebarExpanded(bool value) => _repository.setSidebarExpanded(value);
  void setLanguage(int? value) => _repository.setLanguage(value);
  void setThemeMode(int? value) => _repository.setThemeMode(value);
  Future<void> setAppearance(
    FrostAppearance value, {
    Brightness? accentBrightness,
    bool? customSelected,
  }) => _repository.setAppearance(
    value,
    accentBrightness: accentBrightness,
    customSelected: customSelected,
  );
  Future<void> setBackgroundMaterial(BackgroundMaterial material) =>
      _saveBackgroundValue(state.background.copyWith(material: material));
  void previewBackgroundIntensity(double value) {
    _previewIntensity = BackgroundSettings.normalizeIntensity(value);
    state = state.withBackground(
      state.background.copyWith(intensity: _previewIntensity),
    );
  }

  Future<void> saveBackgroundIntensity(double value) => _saveBackgroundValue(
    state.background.copyWith(
      intensity: BackgroundSettings.normalizeIntensity(value),
    ),
  );

  Future<void> _saveBackgroundValue(BackgroundSettings value) {
    final revision = ++_backgroundRevision, repository = _repository;
    // Keep the control focused while disk writes run. Serialize all material
    // and intensity requests so earlier completion cannot replace newer intent.
    final operation = _backgroundWrite.then((_) async {
      if (ref.mounted) await repository.setBackground(value);
    });
    // A failed write remains visible to its caller without blocking later ones.
    _backgroundWrite = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation.whenComplete(() {
      if (ref.mounted && revision == _backgroundRevision) {
        _previewIntensity = null;
        state = repository.read();
      }
    });
  }

  void setColumns(int? value) => _repository.setColumns(value);
  void setDownloadPath(String? value) => _repository.setDownloadPath(value);
  void setConcurrency(int value) => _repository.setConcurrency(value);
  void setUgoiraExport(UgoiraExport value) =>
      _repository.setUgoiraExport(value);
  void setSegments(int value) => _repository.setSegments(value);
  void setDefaultSource(String value) => _repository.setDefaultSource(value);
  void setRatings(List<ContentRating> value) => _repository.setRatings(value);
}
