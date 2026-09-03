import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AppInfo {
  static String version = '';
  static String buildNumber = '';
}

abstract final class AppPlatform {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
}

final ValueNotifier<int> appSettingsRevision = ValueNotifier<int>(0);

void notifyAppSettingsChanged() {
  appSettingsRevision.value += 1;
}
