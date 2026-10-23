import 'dart:math' as math;
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/post_video.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Still images and videos occupy the same finite, opaque viewer stage.
class ViewerStage extends StatelessWidget {
  const ViewerStage({
    required this.post,
    required this.index,
    required this.presentation,
    required this.displayedFrame,
    required this.preview,
    required this.videoPosition,
    required this.videoMuted,
    required this.viewport,
    required this.scale,
    required this.maxScale,
    required this.onDismiss,
    required this.onScaleChanged,
    required this.onImageReady,
    this.overlay,
    super.key,
  });
  final Widget? overlay;
  final Post post;
  final int index;
  final StageImagePresentation presentation;
  final DisplayedMediaFrame displayedFrame;
  final ImageProvider? preview;
  final Duration? videoPosition;
  final bool videoMuted;
  final FrostMediaViewportController viewport;
  final double scale, maxScale;
  final VoidCallback onDismiss;
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<ImageProvider?> onImageReady;
  @override
  Widget build(BuildContext context) {
    Widget stage(BuildContext context, double ratio, Widget frame) =>
        FrostMediaStage(aspectRatio: ratio, child: frame);
    Widget video() => PostVideo(
      key: ValueKey(('viewer-video', index)),
      initialPosition: videoPosition,
      initialMuted: videoMuted,
      post: post,
      preview: preview,
      cover: (play) => PostMedia(
        displayedFrame: displayedFrame,
        post: post,
        purpose: PostMediaPurpose.stage,
        presentation: presentation,
        fit: BoxFit.contain,
        preview: preview,
        onPlay: play,
        stageBuilder: stage,
      ),
      stage: (ratio, player) => FrostMediaStage(
        aspectRatio: ratio,
        child: FrostMediaFrame(radius: 0, child: player),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        return FrostMediaViewport(
          key: ValueKey(('viewer-viewport', index)),
          controller: viewport,
          maxScale: postMediaFormat(post) == PostMediaFormat.video
              ? 1
              : maxScale,
          overlay: overlay,
          doubleTapScale: 2.5,
          onDismiss: onDismiss,
          onScaleChanged: (value) {
            onScaleChanged(value);
            if (value > 1) {
              final shownWidth =
                  math.min(
                    constraints.maxWidth,
                    constraints.maxHeight * post.aspectRatio,
                  ) *
                  dpr;
              presentation.requestPixels(post, shownWidth * value);
            }
          },
          background: ColoredBox(
            color: FrostThemeTokens.of(
              context,
            ).onMediaScrim.withValues(alpha: 1),
          ),
          child: postMediaFormat(post) == PostMediaFormat.video
              ? video()
              : PostMedia(
                  key: ValueKey(('viewer-media', index)),
                  stageBuilder: stage,
                  decodeWidth: math.max(
                    1,
                    (constraints.maxWidth * dpr * scale).ceil(),
                  ),
                  displayedFrame: displayedFrame,
                  post: post,
                  purpose: PostMediaPurpose.stage,
                  presentation: presentation,
                  fit: BoxFit.contain,
                  preview: preview,
                  onImageReady: onImageReady,
                  frameBuilder: (image) => Semantics(
                    container: true,
                    image: true,
                    label: '${post.sourceId} · #${post.id}',
                    child: image,
                  ),
                ),
        );
      },
    );
  }
}
