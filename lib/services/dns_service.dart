import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract final class DnsService {
  static const hosts = <String>[
    'yande.re',
    'files.yande.re',
    'assets.yande.re',
  ];

  static Map<String, String> _addresses = const {};
  static Future<Map<String, String>?>? _refreshing;

  static Map<String, String> get cachedAddresses =>
      Map.unmodifiable(_addresses);

  static String? cachedAddressFor(String host) =>
      _addresses[host.toLowerCase()];

  static Future<Map<String, String>?> fetchAddresses({bool force = false}) {
    if (!force && _addresses.length == hosts.length) {
      return Future.value(cachedAddresses);
    }
    return _refreshing ??= _fetchAddresses().whenComplete(() {
      _refreshing = null;
    });
  }

  static Future<List<String>?> fetchDns({bool force = false}) async {
    final addresses = await fetchAddresses(force: force);
    if (addresses == null) return null;
    return [for (final host in hosts) addresses[host]!];
  }

  static Future<Map<String, String>?> _fetchAddresses() async {
    try {
      final values = await Future.wait([
        for (final host in hosts) _fetchAddressByDoh(host),
      ]);
      _addresses = Map.unmodifiable({
        for (var index = 0; index < hosts.length; index++)
          hosts[index]: values[index],
      });
      return cachedAddresses;
    } catch (_) {}

    try {
      final fallback = await _fetchDnsByGithub();
      final validated = <String, String>{};
      for (final host in hosts) {
        final address = _validIp(fallback[host]);
        if (address == null) return null;
        validated[host] = address;
      }
      _addresses = Map.unmodifiable(validated);
      return cachedAddresses;
    } catch (_) {
      return _addresses.isEmpty ? null : cachedAddresses;
    }
  }

  static Future<String> _fetchAddressByDoh(String host) async {
    final json = await _getJson(
      Uri.https('doh.sb', '/dns-query', {
        'ct': 'application/dns-json',
        'name': host,
        'type': 'A',
        'do': 'false',
        'cd': 'false',
      }),
      headers: {HttpHeaders.acceptHeader: 'application/dns-json'},
    );
    final answers = json['Answer'];
    if (answers is List) {
      for (final answer in answers.reversed) {
        if (answer is Map && (answer['type'] == 1 || answer['type'] == '1')) {
          final address = _validIp(answer['data']);
          if (address != null) return address;
        }
      }
    }
    throw const FormatException('DNS response contains no IPv4 address.');
  }

  static Future<Map<String, dynamic>> _fetchDnsByGithub() {
    return _getJson(
      Uri.parse(
        'https://cdn.jsdelivr.net/gh/normalllll/yande_gui@main/DNS.json',
      ),
    );
  }

  static Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 8));
      final decoded = jsonDecode(body);
      if (decoded is! Map) throw const FormatException('Expected JSON object.');
      return decoded.cast<String, dynamic>();
    } finally {
      client.close(force: true);
    }
  }

  static String? _validIp(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    final address = InternetAddress.tryParse(text);
    return address?.type == InternetAddressType.IPv4 ? address!.address : null;
  }
}
