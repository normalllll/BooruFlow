import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// Aggregate presentation watches transfer rates without rebuilding lazy task groups.
class DownloadTransferSummary extends ConsumerWidget {
  const DownloadTransferSummary({
    required this.items,
    required this.filter,
    required this.busy,
    required this.onRetryFailed,
    required this.onPauseAll,
    super.key,
  });
  final List<BooruDownloadItem> items;
  final DownloadFilter filter;
  final bool busy;
  final VoidCallback onRetryFailed, onPauseAll;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(downloadTransferRatesProvider);
    final summary = downloadTransferSummary(items, rates);
    if (filter == DownloadFilter.failed) {
      final count = items.where((item) => downloadFailed(item.snapshot)).length;
      return Padding(
        padding: const EdgeInsets.only(bottom: FrostGap.group),
        child: Row(
          children: [
            Expanded(
              child: FrostText(
                t.downloads.failedTasks(count: formatCount(count)),
                role: FrostTextRole.headline,
              ),
            ),
            FrostButton(
              label: t.downloads.retryAll,
              icon: appIcons.refresh,
              size: FrostControlSize.compact,
              onPressed: busy || count == 0 ? null : onRetryFailed,
            ),
          ],
        ),
      );
    }
    if (summary.count == 0 || filter == DownloadFilter.saved) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: FrostGap.related,
                runSpacing: FrostGap.inline,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FrostText(
                    t.downloads.activeTasks(count: formatCount(summary.count)),
                    role: FrostTextRole.headline,
                  ),
                  if (summary.rate != null || summary.remaining != null)
                    FrostText(
                      [
                        if (summary.rate case final rate?) downloadRate(rate),
                        ?summary.remaining,
                      ].join(' · '),
                      role: FrostTextRole.subheadline,
                      tone: FrostTextTone.secondary,
                      numeric: true,
                    ),
                ],
              ),
            ),
            FrostButton(
              label: t.downloads.pauseAll,
              icon: appIcons.pause,
              variant: FrostButtonVariant.plain,
              size: FrostControlSize.compact,
              onPressed: busy ? null : onPauseAll,
            ),
          ],
        ),
        const SizedBox(height: FrostGap.related),
        if (summary.progress case final progress?)
          FrostProgressBar(value: progress, semanticLabel: t.downloads.active)
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostActivityIndicator(
              size: FrostControlSize.compact,
              semanticLabel: t.frost.loading,
            ),
          ),
      ],
    );
  }
}
