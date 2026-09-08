import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'web_challenge_data_state.dart';
import 'package:flutter/material.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/booru/web_challenge_button.dart';
import 'package:booruflow/features/booru/web_challenge_controller.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';

class WebChallengeDataPanel extends ConsumerStatefulWidget {
  const WebChallengeDataPanel({
    super.key,
    required this.sources,
    this.controller,
    this.readState,
    this.compact = false,
  });
  final List<BooruSource> sources;
  final bool compact;
  final WebChallengeController? controller;
  final Future<WebChallengeState> Function(String)? readState;
  @override
  ConsumerState<WebChallengeDataPanel> createState() =>
      _WebChallengeDataPanelState();
}

class _WebChallengeDataPanelState extends ConsumerState<WebChallengeDataPanel> {
  bool _expanded = false;
  WebChallengeController get controller =>
      widget.controller ?? WebChallengeController.instance;
  Future<void> _clear(List<String> sources) async {
    try {
      await controller.clearSources(sources);
      if (mounted) {
        for (final source in sources) {
          ref.invalidate(
            webChallengeDataProvider((
              sourceId: source,
              read: widget.readState,
            )),
          );
        }
        AppToast.success(t.webChallenge.cleared);
      }
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.webChallenge.failed, error);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      BooruService.instance.revision,
      controller.clearing,
    ]),
    builder: (context, _) => ExpansionTile(
      leading: const Icon(Icons.verified_user_outlined),
      title: Text(t.webChallenge.title),
      subtitle: widget.compact ? null : Text(t.webChallenge.clearDescription),
      onExpansionChanged: (value) => setState(() => _expanded = value),
      children: _expanded
          ? [
              ListTile(
                dense: true,
                minTileHeight: 48,
                minVerticalPadding: 4,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(t.webChallenge.clearAll),
                enabled: !controller.clearing.value,
                onTap: controller.clearing.value
                    ? null
                    : () => _clear(
                        widget.sources.map((s) => s.sourceId).toList(),
                      ),
              ),
              for (final (index, source) in widget.sources.indexed)
                ColoredBox(
                  color: index.isOdd
                      ? Theme.of(context).colorScheme.surfaceContainerLow
                      : Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    key: ValueKey('web-data-${source.sourceId}'),
                    dense: true,
                    minTileHeight: 56,
                    minVerticalPadding: 4,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      source.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Consumer(
                      builder: (context, ref, _) {
                        final snapshot = ref.watch(
                          webChallengeDataProvider((
                            sourceId: source.sourceId,
                            read: widget.readState,
                          )),
                        );
                        final data = snapshot.asData?.value;
                        final status = snapshot.hasError
                            ? describeBooruError(snapshot.error)
                            : data == null
                            ? t.generic.loading
                            : data.verified
                            ? t.webChallenge.verified
                            : data.hasSavedData
                            ? t.webChallenge.saved
                            : t.webChallenge.empty;
                        return Tooltip(
                          message: status,
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WebChallengeButton(
                          sourceId: source.sourceId,
                          controller: controller,
                          compact: true,
                          onResolved: () => ref.invalidate(
                            webChallengeDataProvider((
                              sourceId: source.sourceId,
                              read: widget.readState,
                            )),
                          ),
                        ),
                        AppIconButton(
                          key: ValueKey('clear-web-data-${source.sourceId}'),
                          tooltip: t.webChallenge.clear,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: controller.clearing.value
                              ? null
                              : () => _clear([source.sourceId]),
                        ),
                      ],
                    ),
                  ),
                ),
            ]
          : const [],
    ),
  );
}
