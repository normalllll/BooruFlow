import 'download_models.dart';

typedef MaxConcurrentDownloadsProvider = int Function();
typedef DownloadNetworkOptionsResolver =
    DownloadNetworkOptions Function(Uri url, DownloadNetworkOptions requested);

class DownloadManagerConfiguration {
  const DownloadManagerConfiguration({
    required this.maxConcurrentDownloads,
    this.resolveNetworkOptions = _identityNetworkOptions,
  });

  final MaxConcurrentDownloadsProvider maxConcurrentDownloads;
  final DownloadNetworkOptionsResolver resolveNetworkOptions;
}

DownloadNetworkOptions _identityNetworkOptions(
  Uri url,
  DownloadNetworkOptions requested,
) {
  return requested.normalizedFor(url);
}
