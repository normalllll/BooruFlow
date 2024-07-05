import 'dart:async';

class Global {
  static String appVersion = '';
  static String buildNumber = '';
}

StreamController<void> rootUpdateController = StreamController();
