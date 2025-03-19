import 'dart:convert';
import 'dart:io';

class DnsService {
  DnsService._();

  static Future<Map<String, dynamic>> _fetchDnsByDoh(String domain) async {
    HttpClient client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final request = await client.getUrl(Uri.parse('https://doh.sb/dns-query?ct=application/dns-json&name=$domain&type=A&do=false&cd=false'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    }
    throw Exception('Failed to fetch latest release');
  }

  static Future<Map<String, dynamic>> _fetchDnsByGithub() async {
    HttpClient client = HttpClient();

    final request = await client.getUrl(Uri.parse('https://cdn.jsdelivr.net/gh/normalllll/yande_gui@main/DNS.json'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    }
    throw Exception('Failed to fetch latest release');
  }

  static Future<List<String>?> fetchDns() async {
    try {
      final dns0 = await _fetchDnsByDoh("yande.re");
      final dns1 = await _fetchDnsByDoh("files.yande.re");
      final dns2 = await _fetchDnsByDoh("assets.yande.re");
      // return dns['Answer'][0]['data'];

      return [dns0['Answer'][0]['data'], dns1['Answer'][0]['data'], dns2['Answer'][0]['data']];
    } catch (_) {
      // print(_);
    }

    try {
      final json = await _fetchDnsByGithub();
      return [json['yande.re'], json['files.yande.re'], json['assets.yande.re']];
    } catch (e) {
      print(e);
    }
    return null;
  }
}
