import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'web_challenge_failure.dart';

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

class WebChallengePage extends StatefulWidget {
  const WebChallengePage({
    super.key,
    required this.operation,
    required this.cancellation,
  });
  final WebChallengeOperation operation;
  final ValueListenable<int> cancellation;

  @override
  State<WebChallengePage> createState() => _WebChallengePageState();
}

class _WebChallengePageState extends State<WebChallengePage> {
  late final WebViewController _controller;
  Timer? _timer;
  bool _ready = false;
  bool _finishing = false;
  bool _canPop = false;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.cancellation.addListener(_cancelled);
    _controller = WebViewController();
    _timer = Timer(
      Duration(seconds: widget.operation.spec.timeoutSeconds),
      () => _finish(cancel: true),
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await clearEmbeddedWebData(controller: _controller);
      if (!mounted || _finishing) return;
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: (request) =>
              !request.isMainFrame ||
                  challengeNavigationAllowed(widget.operation.spec, request.url)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _error = t.webChallenge.pageLoadFailed);
            }
          },
        ),
      );
      if (!mounted || _finishing) return;
      await _controller.loadRequest(Uri.parse(widget.operation.spec.entryUrl));
      if (mounted && !_finishing) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = t.webChallenge.webViewUnavailable);
    }
  }

  void _cancelled() => unawaited(_finish(cancel: true));

  Future<void> _finish({bool cancel = false}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    WebChallengeCandidate? candidate;
    Object? failure;
    try {
      if (!cancel && _ready) {
        String? userAgent = await _controller.getUserAgent();
        if (userAgent == null || userAgent.isEmpty) {
          final raw = await _controller.runJavaScriptReturningResult(
            'navigator.userAgent',
          );
          userAgent = switch (raw) {
            String() => raw,
            _ => '',
          };
          if (userAgent.startsWith('"')) {
            userAgent = jsonDecode(userAgent) as String;
          }
        }
        final snapshots = <WebChallengeSnapshot>[];
        for (final target in widget.operation.spec.captureTargets) {
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
        candidate = WebChallengeCandidate(
          cookies: const [],
          snapshots: snapshots,
          userAgent: userAgent,
        );
      }
    } catch (_) {
      failure = const WebChallengeFailure('captureFailed');
    }
    try {
      await clearEmbeddedWebData(controller: _controller);
    } catch (_) {
      failure = const WebChallengeFailure('cleanupFailed');
    }
    if (!mounted) return;
    setState(() => _canPop = true);
    // PopScope must observe canPop before the programmatic close.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop<Object?>(failure ?? candidate);
    });
  }

  @override
  void dispose() {
    widget.cancellation.removeListener(_cancelled);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_finish());
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.operation.spec.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _finishing ? null : _finish,
        ),
        actions: [
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: Text(
              _finishing ? t.webChallenge.saving : t.webChallenge.finish,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          if (_progress < 100 || _finishing)
            LinearProgressIndicator(value: _finishing ? null : _progress / 100),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    ),
  );
}
