import 'dart:async';
import 'dart:math' as math;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart' show SaveState;
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/download_actions.dart';
import 'package:booruflow/features/downloads/download_notifications.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_artwork.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The shell's downloads entry ([FrostShell.taskEntry]): the last row of the
/// sidebar, or the floating button of bottom-bar layouts. Either opens
/// [DownloadEntryPanel] through the entry's panel. The sidebar always has it;
/// the floating button comes with any download record, or with a flight on its
/// way to it.
FrostShellTaskEntry appDownloadTaskEntry({
  required FrostFloatingEntryPosition position,
  required ValueChanged<FrostFloatingEntryPosition> onPositionChanged,
}) => FrostShellTaskEntry(
  builder: (context, placement) => DownloadEntryButton(
    alwaysShown: placement == FrostShellTaskEntryPlacement.sidebar,
  ),
  panel: FrostShellTaskPanel(
    title: t.navigation.downloads,
    builder: (context) => const DownloadEntryPanel(),
  ),
  initialFloatingPosition: position,
  onFloatingPositionChanged: onPositionChanged,
);

/// The button the shell places. Hidden, it keeps its place, so a download
/// flight still finds where the button will appear.
class DownloadEntryButton extends ConsumerWidget {
  const DownloadEntryButton({required this.alwaysShown, super.key});

  /// Whether the button shows without any download record: the sidebar's does.
  final bool alwaysShown;

  static final _noFlight = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(downloadActivityProvider);
    final hasRecords = ref.watch(
      downloadItemsProvider.select((items) => items.isNotEmpty),
    );
    final flying = DownloadFlightHost.maybeOf(context)?.flying ?? _noFlight;
    return ValueListenableBuilder<bool>(
      valueListenable: flying,
      builder: (context, flightOnItsWay, _) => DownloadFlightTarget(
        child: alwaysShown || hasRecords || flightOnItsWay
            ? FrostShellTaskButton(
                icon: appIcons.download,
                label: t.navigation.downloads,
                badge: activity.count,
                progress: activity.progress,
                // No action of its own: the shell opens the entry's panel.
                onPressed: null,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Active and failed items first, then the rest, newest first.
List<BooruDownloadItem> orderedDownloadItems(List<BooruDownloadItem> items) {
  int rank(BooruDownloadItem item) {
    final task = item.snapshot;
    if (downloadFailed(task)) return 1;
    return downloadActive(task) ? 0 : 2;
  }

  return [...items]..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0
        ? byRank
        : b.snapshot.createdAt.compareTo(a.snapshot.createdAt);
  });
}

/// The entry's panel: the overall progress and counts, bulk actions, every
/// item with those needing attention first, and the way to the downloads page.
/// It keeps one size whatever it holds. Closing it never cancels anything.
class DownloadEntryPanel extends ConsumerStatefulWidget {
  const DownloadEntryPanel({super.key});

  static const width = 400.0;

  /// At the normal text size; larger text makes the panel taller.
  static const height = 400.0;

  /// The most of the window's height the panel takes at large text.
  static const maxWindowShare = .7;

  @override
  ConsumerState<DownloadEntryPanel> createState() => _DownloadEntryPanelState();
}

class _DownloadEntryPanelState extends ConsumerState<DownloadEntryPanel> {
  /// Actions still running; each runs once at a time.
  final _busy = <Object>{};

  /// Runs [action] unless it is already running; a failure says so.
  Future<void> _run(
    Object key,
    Future<void> Function(DownloadManager manager) action,
  ) async {
    if (!_busy.add(key)) return;
    setState(() {});
    try {
      await action(ref.read(downloadManagerProvider));
    } catch (error) {
      AppToast.errorWithCause(t.downloads.actionFailed, error);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  FrostActionState _state(Object key) => _busy.contains(key)
      ? const FrostActionState.running()
      : FrostActionState.idle;

  /// Closes the panel, in whichever form it takes, then opens the downloads
  /// page (on [taskId] when given) above the page the user is on.
  void _open({String? taskId}) => unawaited(
    closeFrostPanelThen(
      context,
      (origin) => openDownloads(taskId: taskId, router: GoRouter.of(origin)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final labels = t.downloads;
    final all = ref.watch(downloadItemsProvider);
    final items = orderedDownloadItems(all);
    final progress = ref.watch(downloadActivityProvider).progress;
    final media = MediaQuery.of(context);
    final active = all.where((item) => downloadActive(item.snapshot)).length;
    final saved = all.where((item) => downloadCompleted(item.snapshot)).length;
    final failed = all.where((item) => downloadFailed(item.snapshot)).length;

    final summary = Wrap(
      children: [
        FrostText(
          [
            '${labels.total} ${formatCount(all.length)}',
            '${labels.active} ${formatCount(active)}',
            '${labels.saved} ${formatCount(saved)}',
          ].join(' · '),
          role: FrostTextRole.footnote,
          tone: FrostTextTone.secondary,
          numeric: true,
        ),
        if (failed > 0)
          FrostText(
            ' · ${labels.failed} ${formatCount(failed)}',
            role: FrostTextRole.footnote,
            tone: FrostTextTone.negative,
            numeric: true,
          ),
      ],
    );
    final bulk = [
      if (failed > 0)
        FrostButton.quiet(
          label: labels.retryFailed,
          state: _state(#retryFailed),
          onPressed: _busy.contains(#retryFailed)
              ? null
              : () => unawaited(
                  _run(
                    #retryFailed,
                    (manager) => retryFailedDownloads(manager, all),
                  ),
                ),
        ),
      if (saved > 0)
        FrostButton.quiet(
          label: labels.clearCompleted,
          state: _state(#clearCompleted),
          onPressed: _busy.contains(#clearCompleted)
              ? null
              : () => unawaited(
                  _run(
                    #clearCompleted,
                    (manager) => clearCompletedDownloads(manager, all),
                  ),
                ),
        ),
    ];

    return SizedBox(
      width: DownloadEntryPanel.width,
      height: math.min(
        media.textScaler.scale(DownloadEntryPanel.height),
        media.size.height * DownloadEntryPanel.maxWindowShare,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.related,
        children: [
          if (progress != null)
            Row(
              spacing: FrostGap.related,
              children: [
                Expanded(
                  child: FrostProgressBar(
                    value: progress,
                    semanticLabel: labels.downloading,
                  ),
                ),
                FrostText(
                  '${(progress * 100).round()}%',
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                  numeric: true,
                ),
              ],
            ),
          // On one line when the panel has room; the floating panel is
          // narrower, so there the bulk actions go under the counts.
          FrostFit(
            candidates: [
              (context) => Row(
                mainAxisSize: MainAxisSize.min,
                spacing: FrostGap.related,
                children: [summary, ...bulk],
              ),
              (context) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summary,
                  if (bulk.isNotEmpty)
                    Wrap(spacing: FrostGap.related, children: bulk),
                ],
              ),
            ],
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: FrostEmptyState(
                      icon: appIcons.download,
                      title: labels.noTasks,
                      message: labels.noTasksMessage,
                    ),
                  )
                : FrostLoadingScrollView(
                    primary: false,
                    slivers: [
                      SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) => _DownloadPanelRow(
                          key: ValueKey(items[index].snapshot.id),
                          item: items[index],
                          busy: _busy.contains(items[index].snapshot.id),
                          onRetry: (item) => unawaited(
                            _run(
                              item.snapshot.id,
                              (manager) =>
                                  retryDownload(manager, item.snapshot),
                            ),
                          ),
                          onOpen: (item) => _open(taskId: item.snapshot.id),
                        ),
                      ),
                    ],
                  ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FrostButton.quiet(label: labels.viewAll, onPressed: _open),
          ),
        ],
      ),
    );
  }
}

class _DownloadPanelRow extends ConsumerWidget {
  const _DownloadPanelRow({
    required this.item,
    required this.busy,
    required this.onRetry,
    required this.onOpen,
    super.key,
  });
  final BooruDownloadItem item;
  final bool busy;
  final ValueChanged<BooruDownloadItem> onRetry, onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = item.snapshot;
    final failure = downloadFailed(task);
    final source = item.sourceId == null
        ? null
        : downloadSourceName(item, ref.watch(booruSourcesProvider));
    final rate = ref.watch(
      downloadTransferRatesProvider.select((rates) => rates[task.id]),
    );
    final detail = downloadTaskDetail(task, source: source, rate: rate);
    final title = downloadTaskTitle(item);
    return FrostTaskRow(
      title: title,
      detail: detail.isEmpty ? null : detail,
      status: downloadTaskStatus(task),
      showsStatusDot: false,
      progress: downloadActive(task) && !failure ? task.progress : null,
      thumbnail: FrostThumbnail(
        size: FrostThumbnailSize.small,
        image: DownloadArtwork(
          task: item,
          decodeWidth:
              (downloadThumbnailExtent * MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
        ),
        semanticLabel: title,
      ),
      actions: [
        if (failure)
          FrostTaskAction(
            label: task.saveState == SaveState.failed
                ? t.downloads.retrySave
                : t.generic.retry,
            icon: appIcons.refresh,
            onPressed: busy ? () {} : () => onRetry(item),
          ),
      ],
      onPressed: () => onOpen(item),
    );
  }
}
