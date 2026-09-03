import 'package:yande_gui/src/rust/api/yande_client.dart';

abstract final class YandeClientRegistry {
  static YandeClient? _instance;

  static YandeClient get instance {
    final client = _instance;
    if (client == null) {
      throw StateError('YandeClientRegistry has not been initialized.');
    }
    return client;
  }

  static set instance(YandeClient client) {
    _instance = client;
  }
}
