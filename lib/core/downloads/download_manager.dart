import 'package:yande_gui/core/downloads/default_download_manager.dart';
import 'package:yande_gui/core/downloads/download_manager_configuration.dart';
import 'package:yande_gui/core/downloads/download_manager_contract.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/services/yande_network_policy.dart';

export 'download_manager_contract.dart';

DownloadManager? _downloadManager;

DownloadManager get downloadManager {
  return _downloadManager ??= DefaultDownloadManager(
    configuration: DownloadManagerConfiguration(
      maxConcurrentDownloads: () => SettingsService.maxConcurrentDownloads,
      resolveNetworkOptions: YandeNetworkPolicy.resolveDownloadOptions,
    ),
  );
}

Future<void> initializeDownloadManager() {
  return downloadManager.initialize();
}
