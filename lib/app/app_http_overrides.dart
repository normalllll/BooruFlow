import 'dart:io';

import 'package:yande_gui/features/posts/network/yande_network_policy.dart';

final class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = YandeNetworkPolicy.userAgent
      ..badCertificateCallback = (certificate, host, port) =>
          YandeNetworkPolicy.shouldAllowInvalidCertificate(host);
  }
}
