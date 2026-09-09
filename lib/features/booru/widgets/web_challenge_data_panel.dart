import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/features/booru/widgets/web_challenge_button.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final WebChallengeService? controller;
  final Future<WebChallengeState> Function(String)? readState;
  @override
  ConsumerState<WebChallengeDataPanel> createState() =>
      _WebChallengeDataPanelState();
}

class _WebChallengeDataPanelState extends ConsumerState<WebChallengeDataPanel> {
  bool _expanded = false;
  WebChallengeService get controller =>
      widget.controller ?? ref.read(webChallengeServiceProvider);
  Future<void> _clear(List<String> sources) async {
    try {
      await ref
          .read(webChallengeSessionProvider(controller).notifier)
          .clearSources(sources);
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
  Widget build(BuildContext context) {
    final session = ref.watch(webChallengeSessionProvider(controller));
    return ExpansionTile(
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
                enabled: !session.clearing,
                onTap: session.clearing
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
                        final status = switch (snapshot) {
                          AsyncValue(hasError: true, :final error) =>
                            describeBooruError(error),
                          AsyncData(value: WebChallengeState(verified: true)) =>
                            t.webChallenge.verified,
                          AsyncData(
                            value: WebChallengeState(hasSavedData: true),
                          ) =>
                            t.webChallenge.saved,
                          AsyncData() => t.webChallenge.empty,
                          _ => t.generic.loading,
                        };
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
                          onPressed: session.clearing
                              ? null
                              : () => _clear([source.sourceId]),
                        ),
                      ],
                    ),
                  ),
                ),
            ]
          : const [],
    );
  }
}
