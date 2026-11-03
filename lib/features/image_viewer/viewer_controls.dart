import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/action_runner_builder.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The top row over the media: close at the start, the position in the
/// collection in the middle, the less common commands at the end.
class ViewerTopBar extends ConsumerWidget {
  const ViewerTopBar({
    required this.post,
    required this.displayedFrame,
    required this.index,
    required this.itemCount,
    required this.onClose,
    super.key,
  });
  final Post post;
  final DisplayedMediaFrame displayedFrame;
  final int index, itemCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = <FrostMenuEntry>[
      FrostMenuAction(
        t.frost.openInBrowser,
        leading: FrostGlyph.icon(appIcons.externalLink),
        onSelected: () => performPostAction(context, () async {
          if (!await launchUrl(
            Uri.parse(post.originalMedia.url),
            mode: LaunchMode.externalApplication,
          )) {
            throw StateError(t.generic.loadFailed);
          }
        }),
      ),
      if (ref.watch(imageClipboardProvider).supportsImages)
        FrostMenuAction(
          t.discovery.copyImage,
          tooltip: displayedFrame.readyFor(post.postKey)
              ? null
              : t.generic.loading,
          leading: FrostGlyph.icon(appIcons.copy),
          enabled:
              displayedFrame.readyFor(post.postKey) && !displayedFrame.copying,
          onSelected: () => performPostAction(context, () async {
            await copyDisplayedPostImage(
              context,
              displayedFrame,
              post.postKey,
              clipboard: ref.read(imageClipboardProvider),
            );
          }),
        ),
      FrostMenuAction(
        t.discovery.copyLink,
        leading: FrostGlyph.icon(appIcons.link),
        enabled: post.webUrl != null,
        onSelected: post.webUrl == null
            ? null
            : () => performPostAction(
                context,
                () => copyPostValue(context, post.webUrl!),
              ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(FrostGap.related),
      child: Row(
        children: [
          FrostButton.iconOnMedia(
            label: t.frost.close,
            icon: appIcons.close,
            onPressed: onClose,
          ),
          Expanded(
            child: Center(
              heightFactor: 1,
              child: FrostBadge(
                label: '${index + 1} / $itemCount',
                tone: FrostBadgeTone.onMedia,
              ),
            ),
          ),
          FrostMenuAnchor(
            entries: entries,
            builder: (context, focus, toggle) => Focus(
              focusNode: focus,
              canRequestFocus: false,
              child: FrostButton.iconOnMedia(
                label: t.frost.more,
                icon: appIcons.more,
                onPressed: toggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom row over the media: zoom, the original, download.
class ViewerBottomBar extends ConsumerWidget {
  const ViewerBottomBar({
    required this.post,
    required this.presentation,
    required this.scale,
    required this.maxScale,
    required this.onZoom,
    super.key,
  });
  final Post post;
  final StageImagePresentation presentation;
  final double scale, maxScale;
  final ValueChanged<bool> onZoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(FrostGap.related),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (postMediaFormat(post) != PostMediaFormat.video) ...[
          FrostButton.iconOnMedia(
            label: t.postDetail.zoomOut,
            icon: appIcons.zoomOut,
            onPressed: scale > 1 ? () => onZoom(false) : null,
          ),
          const SizedBox(width: FrostGap.related),
          FrostButton.iconOnMedia(
            label: t.postDetail.zoomIn,
            icon: appIcons.zoomIn,
            onPressed: scale < maxScale ? () => onZoom(true) : null,
          ),
        ],
        if (presentation.canUpgrade(post)) ...[
          const SizedBox(width: FrostGap.group),
          FrostButton.iconOnMedia(
            label: t.postDetail.viewOriginal,
            icon: appIcons.fullscreen,
            state: presentation.loadingOriginal(post)
                ? const FrostActionState.running()
                : FrostActionState.idle,
            onPressed: () => presentation.requestOriginal(post),
          ),
        ],
        const SizedBox(width: FrostGap.group),
        ActionRunnerBuilder(
          builder: (context, runner) => FrostButton.iconOnMedia(
            label: t.postDetail.download,
            icon: appIcons.download,
            state: runner.state,
            onPressed: () => unawaited(
              runner.run(() => ref.read(booruDownloadsProvider).add(post)),
            ),
          ),
        ),
      ],
    ),
  );
}
