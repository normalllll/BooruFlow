import 'dart:async';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/models/web_challenge_failure.dart';
import 'package:booruflow/features/booru/web_challenge_browser.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_action_group.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

export 'web_challenge_browser.dart'
    show clearEmbeddedWebData, challengeNavigationAllowed, rootSnapshotHeader;

class WebChallengePage extends StatefulWidget {
  const WebChallengePage({
    super.key,
    required this.operation,
    required this.cancellation,
    this.browser,
  });
  final WebChallengeOperation operation;
  final ValueListenable<int> cancellation;

  /// An application-owned content/load-state boundary, not a plugin fake.
  /// Injected instances belong to the caller; the default browser to this page.
  final WebChallengeBrowser? browser;
  @override
  State<WebChallengePage> createState() => _WebChallengePageState();
}

class _WebChallengePageState extends State<WebChallengePage> {
  late final _browser = widget.browser ?? EmbeddedWebChallengeBrowser();
  Timer? _timer;
  bool _finishing = false, _canPop = false, _initializationFailed = false;
  bool get _failed => _initializationFailed || _browser.failed;
  @override
  void initState() {
    super.initState();
    widget.cancellation.addListener(_cancelled);
    _browser.addListener(_changed);
    _timer = Timer(
      Duration(seconds: widget.operation.spec.timeoutSeconds),
      () => _finish(cancel: true),
    );
    unawaited(_initialize());
  }

  void _changed() {
    if (mounted && !_finishing) setState(() {});
  }

  Future<void> _initialize() async {
    try {
      await _browser.open(widget.operation.spec);
    } catch (_) {
      if (mounted && !_finishing) setState(() => _initializationFailed = true);
    }
  }

  Future<void> _reload() async {
    setState(() => _initializationFailed = false);
    try {
      if (_browser.available) {
        await _browser.reload();
      } else {
        await _initialize();
      }
    } catch (_) {
      if (mounted && !_finishing) setState(() => _initializationFailed = true);
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
      if (!cancel && _browser.available && !_failed) {
        candidate = await _browser.capture(widget.operation.spec);
      }
    } catch (_) {
      failure = const WebChallengeFailure('captureFailed');
    }
    try {
      await _browser.clear();
    } catch (_) {
      failure = const WebChallengeFailure('cleanupFailed');
    }
    if (!mounted) return;
    setState(() => _canPop = true);
    // PopScope observes canPop before the route closes; cancellation never saves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop<Object?>(failure ?? candidate);
    });
  }

  @override
  void dispose() {
    widget.cancellation.removeListener(_cancelled);
    _browser.removeListener(_changed);
    _timer?.cancel();
    if (widget.browser == null) _browser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_finish());
    },
    child: WebChallengeLayout(
      sourceName: widget.operation.spec.displayName,
      actions: [
        FrostToolbarItem.custom(
          minWidth: _finishWidth(context),
          priority: FrostToolbarPriority.high,
          overflowEntry: FrostMenuAction(
            t.webChallenge.finish,
            onSelected: _finishing || _failed || !_browser.available
                ? null
                : _finish,
          ),
          builder: (_) => FrostButton(
            label: t.webChallenge.finish,
            size: FrostControlSize.compact,
            variant: FrostButtonVariant.prominent,
            loading: _finishing,
            onPressed: _finishing || _failed || !_browser.available
                ? null
                : _finish,
          ),
        ),
      ],
      content: _failed
          ? WebChallengeFailureContent(onRetry: _reload)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostInlineBanner(
                  tone: FrostBannerTone.info,
                  message: t.verificationPage.instructions,
                ),
                const SizedBox(height: FrostGap.group),
                Expanded(
                  child: FrostSurface(
                    role: FrostSurfaceRole.module,
                    elevated: false,
                    borderRadius: FrostRadius.borderRadius(FrostRadius.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            FrostButton.icon(
                              label: t.settingsDetails.refresh,
                              icon: appIcons.refresh,
                              size: FrostControlSize.compact,
                              onPressed: _finishing ? null : _reload,
                            ),
                            Expanded(
                              child: FrostText(
                                (_browser.url ??
                                            Uri.tryParse(
                                              widget.operation.spec.entryUrl,
                                            ))
                                        ?.host ??
                                    '',
                                role: FrostTextRole.footnote,
                                tone: FrostTextTone.secondary,
                              ),
                            ),
                            const SizedBox(width: FrostGap.related),
                          ],
                        ),
                        const FrostDivider(),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_browser.available) _browser.content(context),
                              if (_browser.loading || !_browser.available)
                                ColoredBox(
                                  color: FrostThemeTokens.of(
                                    context,
                                  ).surfaceRaised,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FrostActivityIndicator(
                                          semanticLabel:
                                              t.verificationPage.opening,
                                        ),
                                        const SizedBox(
                                          height: FrostGap.related,
                                        ),
                                        FrostText(
                                          t.verificationPage.opening,
                                          role: FrostTextRole.subheadline,
                                          tone: FrostTextTone.secondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
  double _finishWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: t.webChallenge.finish,
        style: FrostTypography.of(context).style(FrostTextRole.callout),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + FrostGap.group * 2;
    painter.dispose();
    return width;
  }
}

/// One pinned header shared by embedded verification and the native-window shell
/// status. The normal shell remains mounted, including mobile bottom navigation.
class WebChallengeLayout extends StatelessWidget {
  const WebChallengeLayout({
    required this.sourceName,
    required this.content,
    this.actions = const [],
    super.key,
  });
  final String sourceName;
  final Widget content;
  final List<FrostToolbarItem> actions;
  @override
  Widget build(BuildContext context) => FrostPinnedChrome(
    chrome: FrostPageHeader(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostText(t.webChallenge.title, role: FrostTextRole.headline),
          FrostText(
            sourceName,
            role: FrostTextRole.footnote,
            tone: FrostTextTone.tertiary,
          ),
        ],
      ),
      actions: actions,
    ),
    body: Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: FrostContentColumn(
          maxWidth: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(bottom: FrostGap.rowInset),
            child: content,
          ),
        ),
      ),
    ),
  );
}

class WebChallengeFailureContent extends StatelessWidget {
  const WebChallengeFailureContent({
    required this.onRetry,
    this.closed = false,
    super.key,
  });
  final VoidCallback onRetry;
  final bool closed;
  @override
  Widget build(BuildContext context) => FrostEmptyState(
    icon: appIcons.error,
    title: closed ? t.verificationPage.closed : t.verificationPage.failed,
    message: t.verificationPage.failureHelp,
    details: AppActionGroup(
      alignment: WrapAlignment.center,
      children: [
        FrostButton(
          label: t.verificationPage.reopen,
          icon: appIcons.refresh,
          onPressed: onRetry,
        ),
        FrostButton(
          label: t.verificationPage.networkSettings,
          variant: FrostButtonVariant.plain,
          onPressed: () => AppRouter.router.go('/settings/network'),
        ),
      ],
    ),
  );
}
