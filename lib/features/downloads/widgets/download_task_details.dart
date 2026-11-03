import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:path/path.dart' as p;

/// The facts and actions of one download task, shown in place below its row.
/// [start] is where the row's text column begins, so the details line up with
/// the title above them.
class DownloadTaskDetails extends ConsumerWidget {
  const DownloadTaskDetails({
    required this.task,
    this.start = downloadTextColumn,
    super.key,
  });
  final BooruDownloadItem task;
  final double start;

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      AppToast.errorWithCause(t.downloads.actionFailed, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = task.snapshot;
    final source = task.sourceId == null
        ? null
        : downloadSourceName(task, ref.watch(booruSourcesProvider));
    final suffix =
        task.post?.originalMedia.extension_ ??
        p.extension(snapshot.filename).replaceFirst('.', '');
    final stored = snapshot.localPath?.trim() ?? '';
    // A MediaStore item has a handle rather than a path a person can use.
    final path = Uri.tryParse(stored)?.scheme == 'content' ? '' : stored;
    final from = [?source, if (task.postId != null) '#${task.postId}'];
    final creator = task.post == null ? null : postCreator(task.post!);
    final rate = ref.watch(
      downloadTransferRatesProvider.select((rates) => rates[snapshot.id]),
    );
    final running = snapshot.status == DownloadStatus.running;
    final remaining = running ? downloadRemaining(snapshot, rate) : null;
    final percent = downloadActive(snapshot) && (snapshot.totalBytes ?? 0) > 0
        ? '${(snapshot.progress.clamp(0, 1) * 100).round()}%'
        : null;
    final speed = [if (running && rate != null) downloadRate(rate), ?remaining];
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: start,
        end: FrostGap.rowInset,
        top: FrostGap.inline,
        bottom: FrostGap.group,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (creator != null && creator != '#${task.postId}') ...[
            FrostText(creator, role: FrostTextRole.footnote),
            const SizedBox(height: FrostGap.inline),
          ],
          Wrap(
            spacing: FrostGap.related,
            runSpacing: FrostGap.inline,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FrostText(
                downloadStatusLabel(snapshot),
                tone: downloadFailed(snapshot)
                    ? FrostTextTone.negative
                    : FrostTextTone.secondary,
              ),
              if (percent != null)
                FrostText(percent, role: FrostTextRole.value, numeric: true),
              if (speed.isNotEmpty)
                FrostText(
                  speed.join(' · '),
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                  numeric: true,
                ),
            ],
          ),
          const SizedBox(height: FrostGap.related),
          FrostKeyValueList(
            entries: [
              if (path.isNotEmpty)
                FrostKeyValue.path(label: t.downloads.path, value: path),
              if (from.isNotEmpty)
                FrostKeyValue(
                  label: t.postDetail.source,
                  value: from.join(' · '),
                ),
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
            ],
          ),
          const SizedBox(height: FrostGap.related),
          Wrap(
            spacing: FrostGap.related,
            runSpacing: FrostGap.inline,
            children: [
              if (snapshot.status == DownloadStatus.queued || running)
                FrostButton(
                  label: t.downloads.pause,
                  icon: appIcons.pause,
                  size: FrostControlSize.small,
                  onPressed: () {
                    final manager = ref.read(downloadManagerProvider);
                    unawaited(_perform(() => manager.pause(snapshot.id)));
                  },
                ),
              if (snapshot.status == DownloadStatus.paused)
                FrostButton(
                  label: t.downloads.resume,
                  icon: appIcons.play,
                  size: FrostControlSize.small,
                  onPressed: () {
                    final manager = ref.read(downloadManagerProvider);
                    unawaited(_perform(() => manager.resume(snapshot.id)));
                  },
                ),
              if (task.canOpenPost)
                FrostButton(
                  label: t.downloads.openPost,
                  size: FrostControlSize.small,
                  onPressed: () => unawaited(openDownloadPost(context, task)),
                ),
              if (ref.watch(downloadPlatformProvider).canRevealDirectory &&
                  path.isNotEmpty)
                FrostButton(
                  label: t.frost.showInFolder,
                  size: FrostControlSize.small,
                  onPressed: () {
                    final manager = ref.read(downloadManagerProvider);
                    unawaited(
                      revealDownloadPath(
                        path,
                        revealer: ref.read(downloadPathRevealerProvider),
                        onRedownload: () => manager.retry(snapshot.id),
                      ),
                    );
                  },
                ),
              if (path.isNotEmpty)
                FrostButton(
                  label: t.downloads.copyPath,
                  size: FrostControlSize.small,
                  onPressed: () => unawaited(
                    performPostAction(
                      context,
                      () => copyPostValue(context, path),
                    ),
                  ),
                ),
            ],
          ),
          if (snapshot.error case final error? when error.isNotEmpty) ...[
            const SizedBox(height: FrostGap.related),
            FrostErrorDetails.quiet(details: error),
          ],
          if (snapshot.log case final log? when log.isNotEmpty) ...[
            const SizedBox(height: FrostGap.related),
            FrostDisclosure(
              title: t.downloads.viewLog,
              child: FrostCodeBlock(text: log),
            ),
          ],
        ],
      ),
    );
  }
}
