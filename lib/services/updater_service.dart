import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdaterService {
  UpdaterService._();

  static Future<Map<String, dynamic>> _fetchLatestRelease() async {
    HttpClient client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://api.github.com/repos/normalllll/yande_gui/releases/latest'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    }
    throw Exception('Failed to fetch latest release');
  }

  static Future<(String, int, List<dynamic>)?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

    final latestRelease = await _fetchLatestRelease();

    final tagName = latestRelease['tag_name'] as String;

    if (tagName.contains('v') && tagName.contains('+')) {
      try {
        final version = tagName.split('v')[1].split('+');
        final latestVersion = version[0];
        final latestBuildNumber = version[1];
        if (latestVersion != appVersion || int.parse(latestBuildNumber) > int.parse(buildNumber)) {
          return (latestVersion, int.parse(latestBuildNumber), latestRelease['assets'] as List<dynamic>);
        }
      } catch (e) {
        throw Exception('Failed to parse latest release version');
      }
    }
    return null;
  }

  static Future<String?> selectDownloadUrl(List<dynamic> assets) async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final isArm64 = androidInfo.supportedAbis.contains('arm64-v8a');
      final isArm32 = androidInfo.supportedAbis.contains('armeabi-v7a');
      final isX86_64 = androidInfo.supportedAbis.contains('x86_64');

      if (isArm64) {
        for (final asset in assets) {
          if (asset['name'] as String == 'app-arm64-v8a-release.apk') {
            return asset['browser_download_url'] as String;
          }
        }
      } else if (isArm32) {
        for (final asset in assets) {
          if (asset['name'] as String == 'app-armeabi-v7a-release.apk') {
            return asset['browser_download_url'] as String;
          }
        }
      } else if (isX86_64) {
        for (final asset in assets) {
          if (asset['name'] as String == 'app-x86_64-release.apk') {
            return asset['browser_download_url'] as String;
          }
        }
      }
    } else if (Platform.isIOS) {
      return null;
    } else if (Platform.isMacOS) {
      for (final asset in assets) {
        if (asset['name'] as String == 'macos-arm64-nosigned.zip') {
          return asset['browser_download_url'] as String;
        }
      }
    } else if (Platform.isWindows) {
      for (final asset in assets) {
        if (asset['name'] as String == 'windows-x64.zip') {
          return asset['browser_download_url'] as String;
        }
      }
    } else if (Platform.isLinux) {
      for (final asset in assets) {
        if (asset['name'] as String == 'linux-x64.tar.gz') {
          return asset['browser_download_url'] as String;
        }
      }
    }

    return null;
  }
}
