import 'dart:async';
import 'dart:io';

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


YandeClient get yandeClientForLargeFile => _yandeClientForLargeFile!;

YandeClient? _yandeClientForLargeFile;

void setYandeClientForLargeFile(YandeClient client) {
  _yandeClientForLargeFile = client;
}


bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool get isMobile => Platform.isAndroid || Platform.isIOS;
