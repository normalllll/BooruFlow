import 'package:flutter/material.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'booru_error_presentation.dart';
import 'web_challenge_controller.dart';

BooruError? challengeError(Object? error) {
  final value = switch (error) {
    BooruReadableException(:final cause) => cause,
    BooruError value => value,
    _ => null,
  };
  return value?.code == BooruErrorCode.challengeRequired ? value : null;
}

class WebChallengeButton extends StatefulWidget {
  const WebChallengeButton({
    super.key,
    required this.sourceId,
    this.compact = false,
    this.controller,
    this.onResolved,
  });
  final String sourceId;
  final bool compact;
  final WebChallengeController? controller;
  final VoidCallback? onResolved;
  @override
  State<WebChallengeButton> createState() => _WebChallengeButtonState();
}

class _WebChallengeButtonState extends State<WebChallengeButton> {
  WebChallengeController get controller =>
      widget.controller ?? WebChallengeController.instance;
  Future<void> _open() async {
    try {
      final resolved = await controller.resolve(context, widget.sourceId);
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller.activity, controller.clearing]),
    builder: (context, _) {
      final active = controller.activity.value;
      final busy = active != null || controller.clearing.value;
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
        label: mine
            ? active?.phase == WebChallengePhase.verifying
                  ? t.webChallenge.saving
                  : t.webChallenge.waiting
            : t.webChallenge.open,
        icon: Icons.verified_user_outlined,
        loading: mine,
        onPressed: busy ? null : _open,
      );
    },
  );
}
