import 'dart:io';

/// Reachability and an optional measurement from the connection operation.
/// Adapters without a measured duration leave latency null.
class ProxyConnectivityResult {
  const ProxyConnectivityResult({required this.reachable, this.latency});
  final bool reachable;
  final Duration? latency;

  /// Round a positive sub-millisecond measurement up; never claim zero latency.
  int? get latencyMs {
    final micros = latency?.inMicroseconds ?? 0;
    return reachable && micros > 0 ? (micros + 999) ~/ 1000 : null;
  }
}

Future<ProxyConnectivityResult> probeProxyConnectivity(String endpoint) async {
  final uri = Uri.parse(endpoint);
  Socket? socket;
  final elapsed = Stopwatch()..start();
  try {
    socket = await Socket.connect(
      uri.host.replaceAll('[', '').replaceAll(']', ''),
      uri.port,
      timeout: const Duration(seconds: 5),
    );
    elapsed.stop();
    return ProxyConnectivityResult(reachable: true, latency: elapsed.elapsed);
  } catch (_) {
    return const ProxyConnectivityResult(reachable: false);
  } finally {
    socket?.destroy();
  }
}

String? proxyEndpoint(String protocol, String host, String port) {
  final number = int.tryParse(port.trim());
  final address = host.trim();
  if (number == null ||
      number < 1 ||
      number > 65535 ||
      address.isEmpty ||
      RegExp(r'[\s/@?#]').hasMatch(address) ||
      address.contains('://')) {
    return null;
  }
  try {
    final uri = Uri(scheme: protocol, host: address, port: number);
    return uri.host.isEmpty ? null : uri.toString();
  } on FormatException {
    return null;
  }
}
