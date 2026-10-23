import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/features/posts/widgets/post_detail_controls.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The viewer's commands share one header and overflow menu.
class ViewerControls extends ConsumerWidget {
  const ViewerControls({
    required this.post,
    required this.presentation,
    required this.displayedFrame,
    required this.index,
    required this.itemCount,
    required this.scale,
    required this.maxScale,
    required this.onClose,
    required this.onSelect,
    required this.onZoom,
    super.key,
  });
  final Post post;
  final StageImagePresentation presentation;
  final DisplayedMediaFrame displayedFrame;
  final int index, itemCount;
  final double scale, maxScale;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;
  final ValueChanged<bool> onZoom;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = <FrostMenuEntry>[
      FrostMenuAction(
        t.frost.openInBrowser,
        icon: appIcons.externalLink,
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
          icon: appIcons.copy,
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
        icon: appIcons.link,
        enabled: post.webUrl != null,
        onSelected: post.webUrl == null
            ? null
            : () => performPostAction(
                context,
                () => copyPostValue(context, post.webUrl!),
              ),
      ),
      FrostMenuAction(
        t.frost.previous,
        icon: appIcons.chevronLeft,
        enabled: index > 0,
        onSelected: index > 0 ? () => onSelect(index - 1) : null,
      ),
      FrostMenuAction(
        t.frost.next,
        icon: appIcons.chevronRight,
        enabled: index + 1 < itemCount,
        onSelected: index + 1 < itemCount ? () => onSelect(index + 1) : null,
      ),
    ];
    return PostMediaHeader(
      title: const SizedBox.shrink(),
      leading: FrostButton.icon(
        label: t.frost.close,
        icon: appIcons.close,
        size: FrostControlSize.compact,
        onPressed: onClose,
      ),
      windowButtons: false,
      actions: [
        if (postMediaFormat(post) != PostMediaFormat.video) ...[
          postIconAction(
            context,
            label: t.postDetail.zoomOut,
            icon: appIcons.zoomOut,
            onPressed: scale > 1 ? () => onZoom(false) : null,
          ),
          postIconAction(
            context,
            label: t.postDetail.zoomIn,
            icon: appIcons.zoomIn,
            onPressed: scale < maxScale ? () => onZoom(true) : null,
          ),
        ],
        if (presentation.canUpgrade(post))
          FrostToolbarItem.custom(
            minWidth: FrostDensity.of(context).targetHeight,
            overflowEntry: FrostMenuAction(
              t.postDetail.viewOriginal,
              icon: appIcons.fullscreen,
              enabled: !presentation.loadingOriginal(post),
              onSelected: () => presentation.requestOriginal(post),
            ),
            builder: (_) => FrostButton.icon(
              label: t.postDetail.viewOriginal,
              icon: appIcons.fullscreen,
              size: FrostControlSize.compact,
              loading: presentation.loadingOriginal(post),
              onPressed: () => presentation.requestOriginal(post),
            ),
          ),
        postIconAction(
          context,
          label: t.postDetail.download,
          icon: appIcons.download,
          onPressedAsync: () => ref.read(booruDownloadsProvider).add(post),
        ),
        postMoreAction(context, entries),
      ],
    );
  }
}
