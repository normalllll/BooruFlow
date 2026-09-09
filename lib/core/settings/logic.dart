import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

/// Persistence boundary; widgets only observe [settingsProvider].
class SettingsRepository {
  const SettingsRepository();
  Stream<void> get changes => SettingsService.changes;
  AppSettings read() => AppSettings(
    language: SettingsService.language,
    themeMode: SettingsService.themeMode,
    waterfallColumns: SettingsService.waterfallColumns,
    downloadPath: SettingsService.downloadPath,
    maxConcurrentDownloads: SettingsService.maxConcurrentDownloads,
    maxSegmentsPerTask: SettingsService.maxSegmentsPerTask,
    defaultSourceId: SettingsService.defaultSourceId,
    ratings: SettingsService.ratings,
  );
  void setLanguage(int? value) => SettingsService.language = value;
  void setThemeMode(int? value) => SettingsService.themeMode = value;
  void setColumns(int? value) => SettingsService.waterfallColumns = value;
  void setDownloadPath(String? value) => SettingsService.downloadPath = value;
  void setConcurrency(int value) =>
      SettingsService.maxConcurrentDownloads = value;
  void setSegments(int value) => SettingsService.maxSegmentsPerTask = value;
  void setDefaultSource(String value) =>
      SettingsService.defaultSourceId = value;
  void setRatings(List<ContentRating> value) => SettingsService.ratings = value;
}

class AppSettings {
  AppSettings({
    required this.language,
    required this.themeMode,
    required this.waterfallColumns,
    required this.downloadPath,
    required this.maxConcurrentDownloads,
    required this.maxSegmentsPerTask,
    required this.defaultSourceId,
    required List<ContentRating> ratings,
  }) : ratings = List.unmodifiable(ratings);
  final int? language, themeMode, waterfallColumns;
  final String? downloadPath;
  final int maxConcurrentDownloads, maxSegmentsPerTask;
  final String defaultSourceId;
  final List<ContentRating> ratings;
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => const SettingsRepository();

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);
  @override
  AppSettings build() {
    final repository = ref.watch(settingsRepositoryProvider);
    final subscription = repository.changes.listen(
      (_) => state = repository.read(),
    );
    ref.onDispose(subscription.cancel);
    return repository.read();
  }

  void setLanguage(int? value) => _repository.setLanguage(value);
  void setThemeMode(int? value) => _repository.setThemeMode(value);
  void setColumns(int? value) => _repository.setColumns(value);
  void setDownloadPath(String? value) => _repository.setDownloadPath(value);
  void setConcurrency(int value) => _repository.setConcurrency(value);
  void setSegments(int value) => _repository.setSegments(value);
  void setDefaultSource(String value) => _repository.setDefaultSource(value);
  void setRatings(List<ContentRating> value) => _repository.setRatings(value);
}
