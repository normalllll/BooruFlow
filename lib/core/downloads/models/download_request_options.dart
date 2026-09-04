import 'dart:io';

enum DownloadChecksumAlgorithm { md5, sha256 }

class DownloadChecksum {
  const DownloadChecksum({required this.algorithm, required this.value});

  factory DownloadChecksum.fromJson(Map<String, Object?> json) {
    return DownloadChecksum(
      algorithm: DownloadChecksumAlgorithm.values.byName(
        json['algorithm'] as String,
      ),
      value: json['value'] as String,
    );
  }

  final DownloadChecksumAlgorithm algorithm;
  final String value;

  Map<String, Object?> toJson() => {
    'algorithm': algorithm.name,
    'value': value,
  };
}

class DownloadValidationOptions {
  const DownloadValidationOptions({
    this.expectedBytes,
    this.allowedContentTypes = const <String>[],
    this.checksum,
  });

  factory DownloadValidationOptions.fromJson(Map<String, Object?> json) {
    final rawChecksum = json['checksum'];
    return DownloadValidationOptions(
      expectedBytes: json['expectedBytes'] as int?,
      allowedContentTypes: List<String>.from(
        (json['allowedContentTypes'] as List?) ?? const [],
      ),
      checksum: rawChecksum == null
          ? null
          : DownloadChecksum.fromJson(
              (rawChecksum as Map).cast<String, Object?>(),
            ),
    );
  }

  final int? expectedBytes;
  final List<String> allowedContentTypes;
  final DownloadChecksum? checksum;

  DownloadValidationOptions normalized() {
    final bytes = expectedBytes;
    if (bytes != null && bytes <= 0) {
      throw ArgumentError.value(
        bytes,
        'expectedBytes',
        'Expected byte count must be positive.',
      );
    }
    final normalizedChecksum = checksum;
    if (normalizedChecksum != null && normalizedChecksum.value.isEmpty) {
      throw ArgumentError.value(
        normalizedChecksum.value,
        'checksum',
        'Checksum must not be empty.',
      );
    }
    if (normalizedChecksum != null) {
      final expectedLength = switch (normalizedChecksum.algorithm) {
        DownloadChecksumAlgorithm.md5 => 32,
        DownloadChecksumAlgorithm.sha256 => 64,
      };
      final value = normalizedChecksum.value.trim();
      if (value.length != expectedLength ||
          !RegExp(r'^[0-9a-fA-F]+$').hasMatch(value)) {
        throw ArgumentError.value(
          value,
          'checksum',
          '${normalizedChecksum.algorithm.name} checksum must contain exactly $expectedLength hexadecimal characters.',
        );
      }
    }
    final normalizedContentTypes = allowedContentTypes
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    for (final contentType in normalizedContentTypes) {
      if (!RegExp(
        r'^[a-z0-9!#$&^_.+-]+/(?:[a-z0-9!#$&^_.+-]+|\*)$',
      ).hasMatch(contentType)) {
        throw ArgumentError.value(
          contentType,
          'allowedContentTypes',
          'Content type must be an exact MIME type or a subtype wildcard such as image/*.',
        );
      }
    }
    return DownloadValidationOptions(
      expectedBytes: bytes,
      allowedContentTypes: normalizedContentTypes,
      checksum: normalizedChecksum == null
          ? null
          : DownloadChecksum(
              algorithm: normalizedChecksum.algorithm,
              value: normalizedChecksum.value.trim().toLowerCase(),
            ),
    );
  }

  Map<String, Object?> toJson() => {
    // ignore: use_null_aware_elements
    if (expectedBytes case final value?) 'expectedBytes': value,
    if (allowedContentTypes.isNotEmpty)
      'allowedContentTypes': allowedContentTypes,
    if (checksum case final value?) 'checksum': value.toJson(),
  };
}

class DownloadNetworkOptions {
  const DownloadNetworkOptions({
    this.headers = const <String, String>{},
    this.proxyUrl,
    this.connectHost,
    this.hostHeader,
    this.disableTlsSni = false,
    this.allowInvalidCertificates = false,
    this.connectTimeoutSeconds = 30,
    this.receiveTimeoutSeconds = 120,
  });

  factory DownloadNetworkOptions.fromJson(Map<String, Object?> json) {
    return DownloadNetworkOptions(
      headers: Map<String, String>.from(json['headers'] as Map),
      proxyUrl: json['proxyUrl'] as String?,
      connectHost: json['connectHost'] as String?,
      hostHeader: json['hostHeader'] as String?,
      disableTlsSni: json['disableTlsSni'] as bool,
      allowInvalidCertificates: json['allowInvalidCertificates'] as bool,
      connectTimeoutSeconds: json['connectTimeoutSeconds'] as int,
      receiveTimeoutSeconds: json['receiveTimeoutSeconds'] as int,
    );
  }

  final Map<String, String> headers;
  final String? proxyUrl;
  final String? connectHost;
  final String? hostHeader;
  final bool disableTlsSni;
  final bool allowInvalidCertificates;
  final int connectTimeoutSeconds;
  final int receiveTimeoutSeconds;

  DownloadNetworkOptions copyWith({
    Map<String, String>? headers,
    String? proxyUrl,
    bool clearProxyUrl = false,
    String? connectHost,
    bool clearConnectHost = false,
    String? hostHeader,
    bool clearHostHeader = false,
    bool? disableTlsSni,
    bool? allowInvalidCertificates,
    int? connectTimeoutSeconds,
    int? receiveTimeoutSeconds,
  }) {
    return DownloadNetworkOptions(
      headers: headers ?? this.headers,
      proxyUrl: clearProxyUrl ? null : proxyUrl ?? this.proxyUrl,
      connectHost: clearConnectHost ? null : connectHost ?? this.connectHost,
      hostHeader: clearHostHeader ? null : hostHeader ?? this.hostHeader,
      disableTlsSni: disableTlsSni ?? this.disableTlsSni,
      allowInvalidCertificates:
          allowInvalidCertificates ?? this.allowInvalidCertificates,
      connectTimeoutSeconds:
          connectTimeoutSeconds ?? this.connectTimeoutSeconds,
      receiveTimeoutSeconds:
          receiveTimeoutSeconds ?? this.receiveTimeoutSeconds,
    );
  }

  DownloadNetworkOptions normalizedFor(Uri uri) {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError.value(
        uri,
        'uri',
        'Only HTTP and HTTPS downloads are supported.',
      );
    }
    final normalizedConnectHost = _nonEmptyString(connectHost);
    final normalizedHostHeader =
        _nonEmptyString(hostHeader) ??
        (normalizedConnectHost == null ? null : _originalAuthority(uri));
    if (disableTlsSni && normalizedConnectHost == null) {
      throw ArgumentError(
        'disableTlsSni requires connectHost so the connection target is explicit.',
      );
    }
    if (disableTlsSni &&
        InternetAddress.tryParse(normalizedConnectHost!) == null) {
      throw ArgumentError.value(
        connectHost,
        'connectHost',
        'SNI bypass requires connectHost to be an IP address on every supported platform.',
      );
    }
    final normalizedHeaders = <String, String>{};
    for (final entry in headers.entries) {
      final key = entry.key.trim().toLowerCase();
      if (key.isNotEmpty) {
        normalizedHeaders[key] = entry.value.trim();
      }
    }
    return DownloadNetworkOptions(
      headers: Map.unmodifiable(normalizedHeaders),
      proxyUrl: _normalizeProxyUrl(proxyUrl),
      connectHost: normalizedConnectHost,
      hostHeader: normalizedHostHeader,
      disableTlsSni: disableTlsSni,
      allowInvalidCertificates: allowInvalidCertificates,
      connectTimeoutSeconds: _positiveInt(connectTimeoutSeconds) ?? 30,
      receiveTimeoutSeconds: _positiveInt(receiveTimeoutSeconds) ?? 120,
    );
  }

  Map<String, Object?> toJson() => {
    'headers': headers,
    // ignore: use_null_aware_elements
    if (proxyUrl case final value?) 'proxyUrl': value,
    // ignore: use_null_aware_elements
    if (connectHost case final value?) 'connectHost': value,
    // ignore: use_null_aware_elements
    if (hostHeader case final value?) 'hostHeader': value,
    'disableTlsSni': disableTlsSni,
    'allowInvalidCertificates': allowInvalidCertificates,
    'connectTimeoutSeconds': connectTimeoutSeconds,
    'receiveTimeoutSeconds': receiveTimeoutSeconds,
  };
}

String? _normalizeProxyUrl(String? value) {
  final text = _nonEmptyString(value);
  if (text == null) {
    return null;
  }
  final uri = Uri.tryParse(text);
  const supportedSchemes = {'http', 'socks', 'socks5'};
  if (uri == null ||
      uri.host.isEmpty ||
      !supportedSchemes.contains(uri.scheme.toLowerCase())) {
    throw ArgumentError.value(
      value,
      'proxyUrl',
      'Proxy URL must use http, socks, or socks5 and include a host.',
    );
  }
  if (uri.userInfo.isNotEmpty) {
    throw ArgumentError.value(
      value,
      'proxyUrl',
      'Authenticated proxies are not supported consistently on every platform.',
    );
  }
  return uri.toString();
}

String _originalAuthority(Uri uri) {
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  final defaultPort = switch (uri.scheme) {
    'http' => 80,
    'https' => 443,
    _ => null,
  };
  return uri.hasPort && uri.port != defaultPort ? '$host:${uri.port}' : host;
}

String? _nonEmptyString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _positiveInt(Object? value) {
  final parsed = switch (value) {
    int value => value,
    num value => value.toInt(),
    String value => int.tryParse(value),
    _ => null,
  };
  return parsed != null && parsed > 0 ? parsed : null;
}
