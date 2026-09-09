import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

BooruError? challengeError(Object? error) {
  final value = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  return switch (value?.code) {
    BooruErrorCode.challengeRequired => value,
    _ => null,
  };
}

class WebChallengeButton extends ConsumerStatefulWidget {
  const WebChallengeButton({
    super.key,
    required this.sourceId,
    this.compact = false,
    this.controller,
    this.onResolved,
  });
  final String sourceId;
  final bool compact;
  final WebChallengeService? controller;
  final VoidCallback? onResolved;
  @override
  ConsumerState<WebChallengeButton> createState() => _WebChallengeButtonState();
}

class _WebChallengeButtonState extends ConsumerState<WebChallengeButton> {
  WebChallengeService get controller =>
      widget.controller ?? ref.read(webChallengeServiceProvider);
  Future<void> _open() async {
    try {
      final resolved = await ref
          .read(webChallengeSessionProvider(controller).notifier)
          .resolve(context, widget.sourceId);
      if (mounted && resolved) widget.onResolved?.call();
    } catch (error) {
      final cancelled =
          error is BooruError && error.code == BooruErrorCode.cancelled;
      if (mounted && !cancelled) {
        AppToast.errorWithCause(t.webChallenge.failed, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(webChallengeSessionProvider(controller));
    final active = session.activity;
    final busy = active != null || session.clearing;
    final mine = active?.sourceId == widget.sourceId;
    if (widget.compact) {
      return AppIconButton(
        tooltip: t.webChallenge.open,
        icon: mine
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.verified_user_outlined),
        onPressed: busy ? null : _open,
      );
    }
    return AppButton(
      label: switch ((mine, active?.phase)) {
        (true, WebChallengePhase.verifying) => t.webChallenge.saving,
        (true, _) => t.webChallenge.waiting,
        (false, _) => t.webChallenge.open,
      },
      icon: Icons.verified_user_outlined,
      loading: mine,
      onPressed: busy ? null : _open,
    );
  }
}
