import 'dart:io';


abstract final class AppInfo {
  static String version = '';
  static String buildNumber = '';
}
abstract final class AppPlatform {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
}
