import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_artwork.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:path/path.dart' as p;

const _inspectorPreviewHeight = 220.0;
const _compactInspectorPreview = 72.0;

class DownloadTaskInspector extends ConsumerWidget {
  const DownloadTaskInspector({required this.task, super.key});
  final BooruDownloadItem task;

  Future<bool> _perform(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (error) {
      AppToast.errorWithCause(t.downloads.actionFailed, error);
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = task.snapshot;
    final compact =
        FrostInspector.presentationOf(context) ==
        FrostInspectorPresentation.sheet;
    final source = task.sourceId == null
        ? null
        : downloadSourceName(task, ref.watch(booruSourcesProvider));
    final creator = task.post == null ? null : postCreator(task.post!);
    final rate = ref.watch(
      downloadTransferRatesProvider.select((rates) => rates[snapshot.id]),
    );
    final remaining = downloadRemaining(snapshot, rate);
    final suffix =
        task.post?.originalMedia.extension_ ??
        p.extension(snapshot.filename).replaceFirst('.', '');
    final meta = <String>[
      ?source,
      if (creator != null && creator != '#${task.postId}') creator,
    ];
    Widget artwork() => DownloadArtwork(task: task);
    Widget heading() => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostText(
          downloadTaskTitle(task),
          role: FrostTextRole.title2,
          numeric: true,
        ),
        if (meta.isNotEmpty) FrostMetaLine(items: meta),
      ],
    );
    return SingleChildScrollView(
      primary: false,
      // The shared Sheet already provides its 20-point content inset.
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: FrostGap.rowInset),
      child: _content(
        compact,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Row(
                children: [
                  SizedBox.square(
                    dimension: _compactInspectorPreview,
                    child: FrostMediaFrame(child: artwork()),
                  ),
                  const SizedBox(width: FrostGap.group),
                  Expanded(child: heading()),
                ],
              )
            else ...[
              SizedBox(
                height: _inspectorPreviewHeight,
                child: FrostMediaFrame(child: artwork()),
              ),
              const SizedBox(height: FrostGap.group),
              heading(),
            ],
            const SizedBox(height: FrostGap.group),
            if (downloadActive(snapshot)) ...[
              Wrap(
                spacing: FrostGap.related,
                runSpacing: FrostGap.inline,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FrostText(
                    '${(snapshot.progress.clamp(0, 1) * 100).round()}%',
                    role: FrostTextRole.value,
                    numeric: true,
                  ),
                  if (rate != null || remaining != null)
                    FrostText(
                      [
                        if (rate != null) downloadRate(rate),
                        ?remaining,
                      ].join(' · '),
                      role: FrostTextRole.footnote,
                      tone: FrostTextTone.secondary,
                      numeric: true,
                    ),
                ],
              ),
              const SizedBox(height: FrostGap.related),
              FrostProgressBar(
                value: snapshot.progress,
                semanticLabel: downloadStatusLabel(snapshot),
              ),
            ] else
              FrostText(
                downloadStatusLabel(snapshot),
                tone: downloadFailed(snapshot)
                    ? FrostTextTone.negative
                    : FrostTextTone.secondary,
              ),
            const SizedBox(height: FrostGap.group),
            FrostKeyValueList(
              entries: [
                if (snapshot.totalBytes case final total? when total > 0)
                  FrostKeyValue(
                    label: t.postDetail.size,
                    value: downloadBytes(total),
                  )
                else if (snapshot.status == DownloadStatus.downloaded &&
                    snapshot.receivedBytes > 0)
                  FrostKeyValue(
                    label: t.postDetail.size,
                    value: downloadBytes(snapshot.receivedBytes),
                  ),
                if (suffix.isNotEmpty)
                  FrostKeyValue(
                    label: t.downloads.format,
                    value: suffix.toUpperCase(),
                  ),
                FrostKeyValue(
                  label: t.downloads.startedAt,
                  value: downloadTime(snapshot.createdAt, full: true),
                ),
                if (snapshot.localPath case final path?
                    when path.trim().isNotEmpty)
                  FrostKeyValue.path(label: t.downloads.path, value: path),
              ],
            ),
            const SizedBox(height: FrostGap.group),
            Wrap(
              spacing: FrostGap.related,
              runSpacing: FrostGap.related,
              children: [
                if (compact &&
                    (snapshot.status == DownloadStatus.running ||
                        snapshot.status == DownloadStatus.queued))
                  FrostButton(
                    label: t.downloads.pause,
                    icon: appIcons.pause,
                    onPressedAsync: () => _perform(
                      () =>
                          ref.read(downloadManagerProvider).pause(snapshot.id),
                    ),
                  ),
                if (compact && snapshot.status == DownloadStatus.paused)
                  FrostButton(
                    label: t.downloads.resume,
                    icon: appIcons.play,
                    onPressedAsync: () => _perform(
                      () =>
                          ref.read(downloadManagerProvider).resume(snapshot.id),
                    ),
                  ),
                if (task.canOpenPost)
                  FrostButton(
                    label: t.downloads.openPost,
                    size: compact
                        ? FrostControlSize.regular
                        : FrostControlSize.compact,
                    onPressed: () => unawaited(
                      closeFrostPanelThen(
                        context,
                        (origin) => openDownloadPost(origin, task),
                      ),
                    ),
                  ),
                if (ref.watch(downloadPlatformProvider).canRevealDirectory &&
                    snapshot.localPath != null &&
                    snapshot.localPath!.trim().isNotEmpty)
                  FrostButton(
                    label: t.frost.showInFolder,
                    icon: appIcons.folder,
                    size: FrostControlSize.compact,
                    onPressedAsync: () {
                      final manager = ref.read(downloadManagerProvider);
                      final revealer = ref.read(downloadPathRevealerProvider);
                      return _perform(
                        () => revealDownloadPath(
                          snapshot.localPath!,
                          revealer: revealer,
                          onRedownload: () => manager.retry(snapshot.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (snapshot.error case final error? when error.isNotEmpty) ...[
              const SizedBox(height: FrostGap.group),
              FrostErrorDetails(details: error),
            ],
            if (snapshot.log case final log? when log.isNotEmpty) ...[
              const SizedBox(height: FrostGap.group),
              FrostDisclosure(
                title: t.downloads.viewLog,
                child: FrostCodeBlock(text: log),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(bool compact, Widget child) =>
      compact ? child : FrostContentColumn(child: child);
}
