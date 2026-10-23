import 'dart:async';

import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// The shell stays visible while the existing Rust/Wry verification window owns
/// the real browser. Test services can drive these states without opening it.
class NativeWebChallengePage extends StatefulWidget {
  const NativeWebChallengePage({
    required this.service,
    required this.sourceId,
    required this.sourceName,
    super.key,
  });
  final WebChallengeService service;
  final String sourceId, sourceName;
  @override
  State<NativeWebChallengePage> createState() => _NativeWebChallengePageState();
}

class _NativeWebChallengePageState extends State<NativeWebChallengePage> {
  bool _running = true,
      _closing = false,
      _canPop = false,
      _closed = false,
      _started = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_run());
    });
  }

  Future<void> _run() async {
    if (_closing) return;
    _started = true;
    setState(() {
      _running = true;
      _closed = false;
    });
    try {
      final result = await widget.service.resolve(context, widget.sourceId);
      if (!mounted || _closing) return;
      if (result) {
        _pop(true);
        return;
      }
      setState(() => _closed = true);
    } catch (error) {
      if (!mounted || _closing) return;
      setState(
        () => _closed =
            error is BooruError && error.code == BooruErrorCode.cancelled,
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _pop(bool result) {
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    try {
      await widget.service.cancelActive(widget.sourceId);
      if (mounted) _pop(false);
    } catch (error) {
      if (mounted) {
        _closing = false;
        AppToast.errorWithCause(t.webChallenge.failed, error);
      }
    }
  }

  @override
  void dispose() {
    // Switching shell destinations must release an active session as well.
    if (_started && _running && !_closing) {
      unawaited(
        widget.service.cancelActive(widget.sourceId).catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: _canPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_close());
    },
    child: WebChallengeLayout(
      sourceName: widget.sourceName,
      content: _running
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FrostActivityIndicator(semanticLabel: t.webChallenge.waiting),
                  const SizedBox(height: FrostGap.related),
                  FrostText(
                    t.webChallenge.waiting,
                    role: FrostTextRole.subheadline,
                    tone: FrostTextTone.secondary,
                  ),
                ],
              ),
            )
          : WebChallengeFailureContent(onRetry: _run, closed: _closed),
    ),
  );
}
