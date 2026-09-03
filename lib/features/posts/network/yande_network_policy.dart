import 'dart:io';

import 'package:yande_gui/core/downloads/download_models.dart';
import 'package:yande_gui/core/settings_service.dart';
import 'package:yande_gui/features/posts/network/client.dart';
import 'package:yande_gui/features/posts/network/dns_service.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';

class YandeNetworkRoute {
  const YandeNetworkRoute({
    required this.originalUri,
    required this.requestUri,
    required this.connectHost,
    required this.headers,
    required this.bypassed,
  });

  final Uri originalUri;
  final Uri requestUri;
  final String? connectHost;
  final Map<String, String> headers;
  final bool bypassed;
}

abstract final class YandeNetworkPolicy {
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko)';

  static const imageHeaders = <String, String>{
    HttpHeaders.userAgentHeader: userAgent,
    HttpHeaders.refererHeader: 'https://yande.re/',
  };

  static Future<void> initialize({bool force = false}) async {
    if (SettingsService.bypassSni) {
      await DnsService.fetchAddresses(force: force);
    }
  }

  static List<String>? get rustAddresses {
    if (!SettingsService.bypassSni) return null;
    final values = [
      for (final host in DnsService.hosts) DnsService.cachedAddressFor(host),
    ];
    if (values.any((value) => value == null)) return null;
    return values.cast<String>();
  }

  static YandeNetworkRoute route(
    Uri uri, {
    bool permitBypass = true,
    Map<String, String> headers = const {},
  }) {
    final normalizedHeaders = <String, String>{...headers};
    final address = permitBypass && SettingsService.bypassSni
        ? DnsService.cachedAddressFor(uri.host)
        : null;
    if (address == null) {
      return YandeNetworkRoute(
        originalUri: uri,
        requestUri: uri,
        connectHost: null,
        headers: Map.unmodifiable(normalizedHeaders),
        bypassed: false,
      );
    }
    normalizedHeaders[HttpHeaders.hostHeader] = _authority(uri);
    return YandeNetworkRoute(
      originalUri: uri,
      requestUri: uri,
      connectHost: address,
      headers: Map.unmodifiable(normalizedHeaders),
      bypassed: true,
    );
  }

  static DownloadNetworkOptions resolveDownloadOptions(
    Uri uri,
    DownloadNetworkOptions requested,
  ) {
    final route = YandeNetworkPolicy.route(uri);
    if (!route.bypassed) return requested.normalizedFor(uri);
    return requested
        .copyWith(
          connectHost: route.connectHost,
          hostHeader: _authority(uri),
          // The CDN currently rejects a TLS handshake without SNI. Keep the
          // original URL/SNI/Host and override only the connection address.
          disableTlsSni: false,
          allowInvalidCertificates: true,
        )
        .normalizedFor(uri);
  }

  static bool shouldAllowInvalidCertificate(String host) {
    final normalized = host.toLowerCase();
    if (DnsService.hosts.contains(normalized)) return true;
    return SettingsService.bypassSni &&
        DnsService.cachedAddresses.values.contains(normalized);
  }

  static String _authority(Uri uri) {
    final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
    final defaultPort = uri.scheme == 'https'
        ? 443
        : uri.scheme == 'http'
        ? 80
        : null;
    return uri.hasPort && uri.port != defaultPort ? '$host:${uri.port}' : host;
  }
}

Future<void> applyYandeNetworkSettings({bool force = false}) async {
  await YandeNetworkPolicy.initialize(force: force);
  final addresses = YandeNetworkPolicy.rustAddresses;
  YandeClientRegistry.instance = YandeClient(
    ips: addresses == null ? null : StringArray3(addresses),
  );
}
