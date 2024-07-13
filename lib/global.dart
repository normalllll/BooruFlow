import 'dart:async';

import 'package:yande_gui/src/rust/api/yande_client.dart';

class Global {
  static String appVersion = '';
  static String buildNumber = '';
}

StreamController<void> rootUpdateController = StreamController();

YandeClient get yandeClient => _yandeClient!;

YandeClient? _yandeClient;

void setYandeClient(YandeClient client) {
  _yandeClient = client;
}
