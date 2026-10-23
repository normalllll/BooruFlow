import 'dart:convert';
import 'dart:io';

import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _nativeCookies = MethodChannel('booruflow/web_challenge');

Future<void> clearEmbeddedWebData({WebViewController? controller}) async {
  if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;
  final view = controller ?? WebViewController();
  await WebViewCookieManager().clearCookies();
  await view.clearCache();
  await view.clearLocalStorage();
  if (Platform.isAndroid) {
    await _nativeCookies.invokeMethod<void>('clearBrowsingData');
  }
}

bool challengeNavigationAllowed(WebChallengeSpec spec, String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      spec.navigationHosts.contains(uri.host);
}

/// A root snapshot only contains cookies native metadata permits at this root.
/// Android uses CookieManager.getCookie(url) directly instead (no guessed fields).
String rootSnapshotHeader(Uri target, List<WebViewCookie> cookies) => cookies
    .where((cookie) {
      final domain = cookie.domain.toLowerCase();
      final host = domain.startsWith('.') ? domain.substring(1) : domain;
      return cookie.path == '/' &&
          (target.host == host ||
              domain.startsWith('.') && target.host.endsWith('.$host'));
    })
    .map((cookie) => '${cookie.name}=${cookie.value}')
    .join('; ');

/// Application-owned browser boundary. Injected browsers belong to the caller;
/// the page owns and disposes its default embedded browser. Tests can provide
/// content and load state without implementing a plugin platform interface.
abstract class WebChallengeBrowser extends ChangeNotifier {
  Uri? get url;
  bool get loading;
  bool get available;
  bool get failed;
  Future<void> open(WebChallengeSpec spec);
  Future<void> reload();
  Future<WebChallengeCandidate> capture(WebChallengeSpec spec);
  Future<void> clear();
  Widget content(BuildContext context);
}

class EmbeddedWebChallengeBrowser extends WebChallengeBrowser {
  WebViewController? _controller;
  bool _disposed = false;
  bool _loading = true, _available = false, _failed = false;
  Uri? _url;
  @override
  Uri? get url => _url;
  @override
  bool get loading => _loading;
  @override
  bool get available => _available;
  @override
  bool get failed => _failed;
  void _changed(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  Future<void> open(WebChallengeSpec spec) async {
    _changed(() {
      _loading = true;
      _failed = false;
    });
    final controller = _controller ??= WebViewController();
    await clearEmbeddedWebData(controller: controller);
    if (_disposed) return;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onUrlChange: (change) =>
            _changed(() => _url = Uri.tryParse(change.url ?? '')),
        onPageStarted: (_) => _changed(() {
          _loading = true;
          _failed = false;
        }),
        onPageFinished: (_) => _changed(() => _loading = false),
        onNavigationRequest: (request) =>
            !request.isMainFrame ||
                challengeNavigationAllowed(spec, request.url)
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) {
            _changed(() {
              _failed = true;
              _loading = false;
            });
          }
        },
      ),
    );
    if (_disposed) return;
    await controller.loadRequest(Uri.parse(spec.entryUrl));
    _changed(() => _available = true);
  }

  @override
  Future<void> reload() async {
    _changed(() {
      _loading = true;
      _failed = false;
    });
    await _controller?.reload();
  }

  @override
  Future<WebChallengeCandidate> capture(WebChallengeSpec spec) async {
    final controller = _controller!;
    String? userAgent = await controller.getUserAgent();
    if (userAgent == null || userAgent.isEmpty) {
      final raw = await controller.runJavaScriptReturningResult(
        'navigator.userAgent',
      );
      userAgent = raw is String ? raw : '';
      if (userAgent.startsWith('"')) {
        userAgent = jsonDecode(userAgent) as String;
      }
    }
    final snapshots = <WebChallengeSnapshot>[];
    for (final target in spec.captureTargets) {
      final uri = Uri.parse(target.url);
      final header = Platform.isAndroid
          ? await _nativeCookies.invokeMethod<String>(
                  'cookiesForUrl',
                  target.url,
                ) ??
                ''
          : rootSnapshotHeader(
              uri,
              await WebViewCookieManager().getCookies(domain: uri),
            );
      if (header.isNotEmpty) {
        snapshots.add(
          WebChallengeSnapshot(targetId: target.id, cookieHeader: header),
        );
      }
    }
    return WebChallengeCandidate(
      cookies: const [],
      snapshots: snapshots,
      userAgent: userAgent,
    );
  }

  @override
  Future<void> clear() => clearEmbeddedWebData(controller: _controller);
  @override
  Widget content(BuildContext context) =>
      WebViewWidget(controller: _controller!);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
