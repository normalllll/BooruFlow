import 'dart:io';

Future<bool> probeProxyConnectivity(String endpoint) async {
  final uri = Uri.parse(endpoint);
  Socket? socket;
  try {
    socket = await Socket.connect(
      uri.host.replaceAll('[', '').replaceAll(']', ''),
      uri.port,
      timeout: const Duration(seconds: 5),
    );
    return true;
  } catch (_) {
    return false;
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
