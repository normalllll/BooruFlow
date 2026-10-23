import 'dart:async';
import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/native_web_challenge_page.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

class WebChallengeButton extends ConsumerStatefulWidget {
  const WebChallengeButton({
    super.key,
    required this.sourceId,
    this.compact = false,
    this.asRow = false,
    this.controller,
    this.onResolved,
  });
  final String sourceId;
  final bool compact, asRow;
  final WebChallengeService? controller;
  final VoidCallback? onResolved;
  @override
  ConsumerState<WebChallengeButton> createState() => _WebChallengeButtonState();
}

class _WebChallengeButtonState extends ConsumerState<WebChallengeButton> {
  WebChallengeService get controller =>
      widget.controller ?? ref.read(webChallengeServiceProvider);
  Future<bool> _open() async {
    try {
      final resolved = controller.usesNativeWindow
          ? await AppRouter.pushContent<bool>(
                  context,
                  NativeWebChallengePage(
                    service: controller,
                    sourceId: widget.sourceId,
                    sourceName:
                        ref
                            .read(booruSourcesProvider)
                            .where((s) => s.sourceId == widget.sourceId)
                            .firstOrNull
                            ?.displayName ??
                        widget.sourceId,
                  ),
                ) ??
                false
          : await ref
                .read(webChallengeSessionProvider(controller).notifier)
                .resolve(context, widget.sourceId);
      if (mounted && resolved) widget.onResolved?.call();
      return resolved;
    } catch (error) {
      final cancelled =
          error is BooruError && error.code == BooruErrorCode.cancelled;
      if (mounted && !cancelled) {
        AppToast.errorWithCause(t.webChallenge.failed, error);
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(webChallengeSessionProvider(controller));
    final active = session.activity;
    final mine = active?.sourceId == widget.sourceId;
    final label = switch ((mine, active?.phase)) {
      (true, WebChallengePhase.verifying) => t.webChallenge.saving,
      (true, _) => t.webChallenge.waiting,
      (false, _) => t.webChallenge.open,
    };
    final action = active != null && !mine || session.clearing ? null : _open;
    if (widget.asRow) {
      return FrostListRow(
        title: label,
        accessory: FrostRowAccessory.external,
        enabled: action != null,
        onPressed: action == null ? null : () => unawaited(action()),
      );
    }
    return widget.compact
        ? FrostButton.icon(
            label: label,
            icon: appIcons.check,
            onPressedAsync: action,
          )
        : FrostButton(label: label, onPressedAsync: action);
  }
}
