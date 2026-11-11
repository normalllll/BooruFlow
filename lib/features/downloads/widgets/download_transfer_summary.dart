import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The total progress of the tasks in flight. It watches the transfer rates
/// itself so the lazy task lists below do not rebuild with them.
///
/// Tasks start and stop all the time, so the strip keeps one height whatever
/// it shows and the list below never moves.
class DownloadTransferSummary extends ConsumerStatefulWidget {
  const DownloadTransferSummary({required this.items, super.key});
  final List<BooruDownloadItem> items;
  @override
  ConsumerState<DownloadTransferSummary> createState() =>
      _DownloadTransferSummaryState();
}

class _DownloadTransferSummaryState
    extends ConsumerState<DownloadTransferSummary> {
  // Every task of the current run, so that finishing one does not take its
  // bytes out of the total and move the bar backwards.
  final _run = <String>{};
  double _bar = 0;

  void _track() {
    final active = [
      for (final item in widget.items)
        if (downloadActive(item.snapshot)) item.snapshot.id,
    ];
    if (active.isEmpty) {
      _run.clear();
    } else {
      _run.addAll(active);
    }
  }

  @override
  void initState() {
    super.initState();
    _track();
  }

  @override
  void didUpdateWidget(DownloadTransferSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    _track();
  }

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(downloadTransferRatesProvider);
    final summary = downloadTransferSummary(
      widget.items,
      rates,
      finished: [
        for (final item in widget.items)
          if (_run.contains(item.snapshot.id) &&
              downloadCompleted(item.snapshot))
            item,
      ],
    );
    final idle = summary.count == 0;
    final line = idle
        ? t.downloads.noActive
        : [
            t.downloads.activeTasks(
              n: summary.count,
              count: formatCount(summary.count),
            ),
            if (summary.rate case final rate?) downloadRate(rate),
            ?summary.remaining,
          ].join(' · ');
    if (!idle) _bar = summary.progress ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostGap.group),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FrostText(
                  line,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                  numeric: true,
                  maxLines: 1,
                ),
              ),
              if (summary.transferring && summary.progress == null)
                FrostActivityIndicator(
                  size: FrostControlSize.compact,
                  semanticLabel: t.frost.loading,
                ),
            ],
          ),
          const SizedBox(height: FrostGap.inline),
          ExcludeSemantics(
            excluding: idle,
            child: AnimatedOpacity(
              opacity: idle ? 0 : 1,
              duration: FrostMotion.duration(context, FrostMotion.hover),
              curve: FrostMotion.hoverCurve,
              child: FrostProgressBar(
                value: _bar,
                semanticLabel: t.downloads.active,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
