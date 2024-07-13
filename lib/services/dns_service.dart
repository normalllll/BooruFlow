import 'dart:convert';
import 'dart:io';

class DnsService {
  DnsService._();

  static Future<Map<String, dynamic>> _fetchDnsByDoh() async {
    HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    final request = await client.getUrl(Uri.parse('https://doh.sb/dns-query?ct=application/dns-json&name=yande.re&type=A&do=false&cd=false'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    }
    throw Exception('Failed to fetch latest release');
  }

  static Future<String> _fetchDnsByGithub() async {
    HttpClient client = HttpClient();

    final request = await client.getUrl(Uri.parse('https://cdn.jsdelivr.net/gh/normalllll/yande_gui@main/DNS'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    }
    throw Exception('Failed to fetch latest release');
  }

  static Future<String?> fetchDns() async {
    try {
      final dns = await _fetchDnsByDoh();
      return dns['Answer'][0]['data'];
    } catch (_) {}

    try {
      final dns = await _fetchDnsByGithub();
      return dns;
    } catch (_) {}
    return null;
  }
}
