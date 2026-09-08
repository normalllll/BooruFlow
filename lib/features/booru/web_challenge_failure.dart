import 'package:booruflow/intl/translations.g.dart';

final class WebChallengeFailure implements Exception {
  const WebChallengeFailure(this.key);
  final String key;

  @override
  String toString() => webChallengeMessage(key);
}

String webChallengeMessage(String key) => switch (key) {
  'webViewUnavailable' => t.webChallenge.webViewUnavailable,
  'proxyUnsupported' => t.webChallenge.proxyUnsupported,
  'busy' => t.webChallenge.busy,
  'cancelled' => t.webChallenge.cancelled,
  'timedOut' => t.webChallenge.timedOut,
  'storageFailed' => t.webChallenge.storageFailed,
  'cleanupFailed' => t.webChallenge.cleanupFailed,
  'operationSuperseded' => t.webChallenge.operationSuperseded,
  'noCookies' => t.webChallenge.noCookies,
  'captureFailed' => t.webChallenge.captureFailed,
  _ => t.webChallenge.failed,
};
