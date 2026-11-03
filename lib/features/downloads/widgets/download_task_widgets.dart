import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_artwork.dart';
import 'package:booruflow/features/downloads/widgets/download_task_details.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

FrostTaskStatus downloadTaskStatus(DownloadTaskSnapshot task) {
  if (downloadFailed(task)) {
    return FrostTaskStatus.failed;
  }
  if (task.saveState == SaveState.saving ||
      task.saveState == SaveState.pending) {
    return FrostTaskStatus.running;
  }
  return switch (task.status) {
    DownloadStatus.queued => FrostTaskStatus.queued,
    DownloadStatus.running => FrostTaskStatus.running,
    DownloadStatus.paused => FrostTaskStatus.paused,
    DownloadStatus.downloaded => FrostTaskStatus.completed,
    DownloadStatus.failed => FrostTaskStatus.failed,
    DownloadStatus.cancelled => FrostTaskStatus.cancelled,
  };
}

// All download rows use the shared small thumbnail, including saved records.
const downloadThumbnailExtent = 48.0;

/// Where the text of a row (and what expands below it) starts.
const downloadTextColumn = downloadThumbnailExtent + FrostGap.related;

class DownloadTaskTile extends ConsumerStatefulWidget {
  const DownloadTaskTile({
    required this.task,
    this.onTaskTap,
    this.expanded = false,
    super.key,
  });
  final BooruDownloadItem task;

  /// Whether the task's details show below the row.
  final bool expanded;
  final ValueChanged<BooruDownloadItem>? onTaskTap;
  @override
  ConsumerState<DownloadTaskTile> createState() => _DownloadTaskTileState();
}

class _DownloadTaskTileState extends ConsumerState<DownloadTaskTile> {
  final _artwork = GlobalKey();
  bool _busy = false, _hovered = false, _focused = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.downloads.actionFailed, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openPost() => unawaited(openDownloadPost(context, widget.task));
  void _menu(List<FrostMenuEntry> entries) {
    final box = context.findRenderObject()! as RenderBox;
    final end = Directionality.of(context) == TextDirection.ltr
        ? box.size.width
        : 0.0;
    showFrostContextMenu(
      context: context,
      globalPosition: box.localToGlobal(Offset(end, box.size.height)),
      entries: entries,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.task, task = item.snapshot;
    final manager = ref.read(downloadManagerProvider);
    final source = item.sourceId == null
        ? null
        : downloadSourceName(item, ref.watch(booruSourcesProvider));
    final rate = ref.watch(
      downloadTransferRatesProvider.select((rates) => rates[task.id]),
    );
    final primary = switch ((task.status, task.saveState)) {
      (DownloadStatus.failed || DownloadStatus.cancelled, _) => (
        t.generic.retry,
        appIcons.refresh,
        () => manager.retry(task.id),
      ),
      (_, SaveState.failed) => (
        t.downloads.retrySave,
        appIcons.refresh,
        () => manager.retrySave(task.id),
      ),
      (DownloadStatus.queued || DownloadStatus.running, _) => (
        t.downloads.pause,
        appIcons.pause,
        () => manager.pause(task.id),
      ),
      (DownloadStatus.paused, _) => (
        t.downloads.resume,
        appIcons.play,
        () => manager.resume(task.id),
      ),
      _ => null,
    };
    final completed = downloadCompleted(task);
    final openPath = completed && (task.localPath?.trim().isNotEmpty ?? false)
        ? task.localPath
        : null;
    void openFile(String path) => unawaited(
      _run(
        () => openDownloadFile(
          path,
          revealer: ref.read(downloadPathRevealerProvider),
          onRedownload: () => manager.retry(task.id),
        ),
      ),
    );
    final entries = <FrostMenuEntry>[
      if (openPath != null)
        FrostMenuAction(
          t.downloads.open,
          leading: FrostGlyph.icon(appIcons.externalLink),
          onSelected: () => openFile(openPath),
        ),
      if (primary != null)
        FrostMenuAction(
          primary.$1,
          leading: FrostGlyph.icon(primary.$2),
          onSelected: _busy ? null : () => unawaited(_run(primary.$3)),
        ),
      if (item.canOpenPost)
        FrostMenuAction(
          t.downloads.openPost,
          leading: FrostGlyph.icon(appIcons.image),
          onSelected: _openPost,
        ),
      if (task.localPath case final path?
          when ref.watch(downloadPlatformProvider).canRevealDirectory &&
              path.trim().isNotEmpty)
        FrostMenuAction(
          t.frost.showInFolder,
          leading: FrostGlyph.icon(appIcons.folder),
          onSelected: () => unawaited(
            _run(
              () => revealDownloadPath(
                path,
                revealer: ref.read(downloadPathRevealerProvider),
                onRedownload: () => manager.retry(task.id),
              ),
            ),
          ),
        ),
      // The manager cannot stop a file that is already being saved.
      if (switch (task.status) {
        DownloadStatus.queued ||
        DownloadStatus.running ||
        DownloadStatus.paused => true,
        _ => false,
      })
        FrostMenuAction(
          t.downloads.cancel,
          leading: FrostGlyph.icon(appIcons.close),
          onSelected: _busy
              ? null
              : () => unawaited(_run(() => manager.cancel(task.id))),
        ),
      FrostMenuAction(
        t.downloads.deleteTask,
        leading: FrostGlyph.icon(appIcons.delete),
        destructive: true,
        onSelected: _busy
            ? null
            : () => unawaited(_run(() => manager.deleteTask(task.id))),
      ),
    ];
    final failure = downloadFailed(task);
    final detail = downloadTaskDetail(task, source: source, rate: rate);
    final title = downloadTaskTitle(item);
    final artwork = DownloadArtwork(
      key: _artwork,
      task: item,
      decodeWidth:
          (downloadThumbnailExtent * MediaQuery.devicePixelRatioOf(context))
              .ceil(),
    );
    Widget more() => FrostButton.icon(
      label: t.frost.more,
      icon: appIcons.more,
      size: FrostControlSize.compact,
      onPressed: () => _menu(entries),
    );
    final showActions = _hovered || _focused;
    // Without hover these never show; swipe, long press and the details hold
    // the same actions, so a touch row gives their room back to its text.
    final hover = FrostInputCapability.of(context).hoverAvailable;
    // Each press is guarded in _run; a control that dims for the moment an
    // instant action takes would only flicker.
    void pressPrimary() => unawaited(_run(primary!.$3));
    Widget primaryButton({required bool iconOnly}) => iconOnly
        ? FrostButton.icon(
            label: primary!.$1,
            icon: primary.$2,
            size: FrostControlSize.compact,
            onPressed: pressPrimary,
          )
        : FrostButton(
            label: primary!.$1,
            icon: primary.$2,
            size: FrostControlSize.compact,
            onPressed: pressPrimary,
          );
    Widget openButton({required bool iconOnly}) => iconOnly
        ? FrostButton.icon(
            label: t.downloads.open,
            icon: appIcons.externalLink,
            size: FrostControlSize.compact,
            onPressed: () => openFile(openPath!),
          )
        : FrostButton(
            label: t.downloads.open,
            icon: appIcons.externalLink,
            size: FrostControlSize.compact,
            onPressed: () => openFile(openPath!),
          );
    Widget moreSlot() => SizedBox(
      width: FrostDensity.of(context).targetHeight,
      child: FrostPresence(visible: showActions, child: more()),
    );
    // A failed row keeps its retry, a completed one its open, always visible.
    Widget trailingActions({required bool iconOnly}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hover) moreSlot(),
        if (failure && primary != null) primaryButton(iconOnly: iconOnly),
        if (openPath != null) openButton(iconOnly: iconOnly),
      ],
    );
    final Widget? controls = failure || openPath != null
        ? FrostFit(
            candidates: [
              (_) => trailingActions(iconOnly: false),
              (_) => trailingActions(iconOnly: true),
            ],
          )
        : !hover
        ? null
        : SizedBox(
            width:
                FrostDensity.of(context).targetHeight *
                (primary == null ? 1 : 2),
            child: FrostPresence(
              visible: showActions,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primary != null) primaryButton(iconOnly: true),
                  more(),
                ],
              ),
            ),
          );
    final thumbnail = FrostThumbnail(
      size: FrostThumbnailSize.small,
      image: artwork,
      semanticLabel: title,
    );
    final mainRow = completed
        ? FrostListRow(
            title: title,
            subtitle: FrostRowSubtitle(
              [
                if (task.ugoiraExport case final format?)
                  format == UgoiraExport.losslessWebp
                      ? t.ugoira.webpRecord
                      : t.ugoira.zipRecord,
                if (detail.isNotEmpty) detail,
              ].join(' · '),
            ),
            selected: widget.expanded,
            trailing: controls,
            leading: FrostLeading.custom(thumbnail),
            onPressed: widget.onTaskTap == null
                ? null
                : () => widget.onTaskTap!(item),
            contextMenu: entries,
          )
        : FrostTaskRow(
            title: title,
            detail: detail.isEmpty ? null : detail,
            selected: widget.expanded,
            trailing: controls,
            status: downloadTaskStatus(task),
            showsStatusDot: false,
            progressPlacement: FrostTaskProgressPlacement.belowDetail,
            thumbnail: thumbnail,
            progress: downloadActive(task) && !failure ? task.progress : null,
            contextMenu: entries,
            onPressed: widget.onTaskTap == null
                ? null
                : () => widget.onTaskTap!(item),
          );
    final row = Focus(
      canRequestFocus: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FrostSwipeActions(
          showsPointerActions: false,
          trailing: [
            if (primary != null)
              FrostSwipeAction(
                label: primary.$1,
                icon: primary.$2,
                onPressed: () => unawaited(_run(primary.$3)),
              ),
            FrostSwipeAction(
              label: t.downloads.remove,
              icon: appIcons.delete,
              tone: FrostSwipeTone.destructive,
              onPressed: () =>
                  unawaited(_run(() => manager.deleteTask(task.id))),
            ),
          ],
          child: mainRow,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        FrostPresence(
          visible: widget.expanded,
          effect: FrostPresenceEffect.expand,
          alignment: AlignmentDirectional.topStart,
          child: DownloadTaskDetails(task: item),
        ),
      ],
    );
  }
}

/// Opens both live tasks and restored historical records through real routes.
Future<void> openDownloadPost(
  BuildContext context,
  BooruDownloadItem item,
) async {
  if (item.post case final post?) {
    await context.pushPost(post);
  } else if (item.canOpenPost) {
    await context.pushNamed<void>(
      AppRoute.postDetail.name,
      pathParameters: {'id': item.postId!},
      queryParameters: {'source': item.sourceId!},
    );
  }
}
