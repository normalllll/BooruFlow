import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_logic.dart';
import 'package:booruflow/features/booru/widgets/web_challenge_button.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

class WebChallengeDataPanel extends ConsumerStatefulWidget {
  const WebChallengeDataPanel({
    super.key,
    required this.sources,
    this.controller,
    this.readState,
    this.compact = false,
    this.savedOnly = false,
  });
  final List<BooruSource> sources;
  final bool compact, savedOnly;
  final WebChallengeService? controller;
  final Future<WebChallengeState> Function(String)? readState;
  @override
  ConsumerState<WebChallengeDataPanel> createState() =>
      _WebChallengeDataPanelState();
}

class _WebChallengeDataPanelState extends ConsumerState<WebChallengeDataPanel> {
  WebChallengeService get controller =>
      widget.controller ?? ref.read(webChallengeServiceProvider);
  bool _confirming = false;

  Future<bool> _clear(List<String> sources) async {
    if (_confirming || controller.clearing) return false;
    setState(() => _confirming = true);
    try {
      if (!await showFrostConfirm(
            context: context,
            title: sources.length == 1
                ? t.webChallenge.clear
                : t.webChallenge.clearAll,
            message: t.webChallenge.clearDescription,
            confirmLabel: t.webChallenge.clear,
          ) ||
          !mounted) {
        return false;
      }
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
        return true;
      } catch (error) {
        if (mounted) AppToast.errorWithCause(t.webChallenge.failed, error);
        return false;
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(webChallengeSessionProvider(controller));
    final rows = <Widget>[];
    final failures = <String, Object>{};
    var awaitingSavedData = false;
    final busy = session.clearing || _confirming;
    for (final source in widget.sources) {
      final snapshot = ref.watch(
        webChallengeDataProvider((
          sourceId: source.sourceId,
          read: widget.readState,
        )),
      );
      if (widget.savedOnly) {
        // Unknown data must never appear as a saved source, even for one frame.
        // Riverpod retains previous values during refresh, keeping known rows.
        if (!snapshot.hasValue && !snapshot.hasError) awaitingSavedData = true;
        if (snapshot.hasError) failures[source.sourceId] = snapshot.error!;
        if (snapshot.value?.hasSavedData != true) continue;
      }
      final status = switch (snapshot) {
        AsyncValue(hasError: true, :final error) => describeBooruError(error),
        AsyncData(value: WebChallengeState(verified: true)) =>
          t.webChallenge.verified,
        AsyncData(value: WebChallengeState(hasSavedData: true)) =>
          t.webChallenge.saved,
        AsyncData() => t.webChallenge.empty,
        _ => t.generic.loading,
      };
      final action = widget.savedOnly
          ? FrostButton(
              key: ValueKey('clear-web-data-${source.sourceId}'),
              label: t.webChallenge.clear,
              variant: FrostButtonVariant.plain,
              size: FrostControlSize.compact,
              onPressedAsync: busy ? null : () => _clear([source.sourceId]),
            )
          : WebChallengeButton(
              sourceId: source.sourceId,
              controller: controller,
              asRow: true,
              onResolved: () => ref.invalidate(
                webChallengeDataProvider((
                  sourceId: source.sourceId,
                  read: widget.readState,
                )),
              ),
            );
      if (widget.savedOnly) {
        rows.add(
          FrostListRow(
            key: ValueKey('web-data-${source.sourceId}'),
            title: source.displayName,
            subtitle: status,
            subtitleStatus: snapshot.hasError
                ? FrostStatusTone.negative
                : snapshot.value?.verified == true
                ? FrostStatusTone.positive
                : FrostStatusTone.caution,
            trailing: action,
          ),
        );
      } else {
        rows.add(
          FrostListRow(
            key: ValueKey('web-data-${source.sourceId}'),
            title: t.settingsDetails.status,
            value: status,
          ),
        );
        rows.add(action);
      }
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.savedOnly && awaitingSavedData)
          AppLoadingContent.rows(
            labels: [for (final source in widget.sources) source.displayName],
          )
        else ...[
          if (failures.isNotEmpty) ...[
            FrostInlineBanner(
              tone: FrostBannerTone.negative,
              title: t.webChallenge.failed,
              message: describeBooruError(failures.values.first),
              actionLabel: t.generic.retry,
              onAction: () {
                for (final sourceId in failures.keys) {
                  ref.invalidate(
                    webChallengeDataProvider((
                      sourceId: sourceId,
                      read: widget.readState,
                    )),
                  );
                }
              },
            ),
            const SizedBox(height: FrostGap.related),
          ],
          if (rows.isNotEmpty)
            FrostGroupedSection(
              header: widget.savedOnly
                  ? t.settingsDetails.savedVerifications
                  : t.webChallenge.title,
              children: rows,
            )
          else if (failures.isEmpty)
            FrostEmptyState(
              icon: appIcons.success,
              title: t.webChallenge.empty,
            ),
        ],
        if (widget.savedOnly) ...[
          const SizedBox(height: FrostGap.section),
          FrostGroupedSection(
            footer: t.webChallenge.clearDescription,
            children: [
              FrostListRow(
                key: const ValueKey('clear-all-web-data'),
                title: t.webChallenge.clearAll,
                destructive: true,
                onPressed: busy || awaitingSavedData || rows.isEmpty
                    ? null
                    : () => _clear(
                        widget.sources.map((s) => s.sourceId).toList(),
                      ),
              ),
            ],
          ),
        ],
      ],
    );
    return widget.compact
        ? FrostDisclosure(title: t.webChallenge.title, child: content)
        : content;
  }
}
