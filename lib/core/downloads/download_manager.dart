import 'package:booruflow/core/downloads/default_download_manager.dart';
import 'package:booruflow/core/downloads/download_manager_configuration.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';

export 'download_manager_contract.dart';

DownloadManager? _downloadManager;
DownloadManagerConfiguration? _configuration;

void configureDownloadManager(DownloadManagerConfiguration configuration) {
  if (_downloadManager != null) {
    throw StateError('Download manager has already been created.');
  }
  _configuration = configuration;
}

DownloadManager get downloadManager {
  final configuration = _configuration;
  if (configuration == null) {
    throw StateError(
      'configureDownloadManager must be called before using downloadManager.',
    );
  }
  return _downloadManager ??= DefaultDownloadManager(
    configuration: configuration,
  );
}

Future<void> initializeDownloadManager() {
  return downloadManager.initialize();
}
