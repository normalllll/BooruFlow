import 'dart:math' as math;

import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/booru_image.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart'
    show PostRatingBadge;
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';

class PostImageViewer extends StatelessWidget {
  const PostImageViewer({
    super.key,
    required this.posts,
    required this.pageController,
    required this.pageIndex,
    required this.loadingRelated,
    required this.relatedError,
    required this.onRetryRelated,
    required this.showPageControls,
    required this.onPageChanged,
    required this.onOpen,
    required this.onDownload,
  });

  final List<Post> posts;
  final PageController pageController;
  final int pageIndex;
  final bool loadingRelated;
  final Object? relatedError;
  final VoidCallback? onRetryRelated;
  final bool showPageControls;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Post> onOpen;
  final ValueChanged<Post> onDownload;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPost = posts[pageIndex];

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: posts.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final pagePost = posts[index];
              return _PostImagePage(
                post: pagePost,
                onOpen: () => onOpen(pagePost),
                onDownload: () => onDownload(pagePost),
              );
            },
          ),
          if (selectedPost.rating != ContentRating.general)
            PositionedDirectional(
              top: 16,
              end: 16,
              child: PostRatingBadge(rating: selectedPost.rating),
            ),
          if (loadingRelated)
            const PositionedDirectional(
              top: 18,
              start: 18,
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (relatedError != null && onRetryRelated != null)
            PositionedDirectional(
              top: switch (selectedPost.rating) {
                ContentRating.general => 12,
                _ => 58,
              },
              start: 12,
              child: _RelatedLoadError(
                error: relatedError!,
                onRetry: onRetryRelated!,
              ),
            ),
          if (posts.length > 1) ...[
            PositionedDirectional(
              bottom: 18,
              start: 0,
              end: 0,
              child: Center(
                child: _PageIndicator(
                  pageIndex: pageIndex,
                  pageCount: posts.length,
                ),
              ),
            ),
            if (showPageControls) ...[
              PositionedDirectional(
                start: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AppIconButton(
                    kind: AppIconButtonKind.surface,
                    icon: Icon(Icons.chevron_left),
                    tooltip: '',
                    onPressed: pageIndex == 0
                        ? null
                        : () => _animateToPage(pageIndex - 1),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AppIconButton(
                    kind: AppIconButtonKind.surface,
                    icon: Icon(Icons.chevron_right),
                    tooltip: '',
                    onPressed: pageIndex >= posts.length - 1
                        ? null
                        : () => _animateToPage(pageIndex + 1),
                  ),
                ),
              ),
            ],
          ],
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  kind: AppIconButtonKind.surface,
                  icon: Icon(Icons.zoom_out_map_outlined),
                  tooltip: t.postDetail.viewOriginal,
                  onPressed: () => onOpen(selectedPost),
                ),
                const SizedBox(width: 8),
                AppIconButton(
                  kind: AppIconButtonKind.surface,
                  icon: Icon(Icons.download_outlined),
                  tooltip: t.postDetail.download,
                  onPressed: () => onDownload(selectedPost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _animateToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PostImagePage extends StatelessWidget {
  const _PostImagePage({
    required this.post,
    required this.onOpen,
    required this.onDownload,
  });

  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final thumbnail = post.variant(MediaVariantKind.thumbnail);
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _fitImage(
          post: post,
          maxWidth: math.max(1.0, constraints.maxWidth),
          maxHeight: math.max(1.0, constraints.maxHeight),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          onLongPress: onDownload,
          child: Center(
            child: SizedBox(
              width: imageSize.width,
              height: imageSize.height,
              child: BooruImage(
                post.sampleUrl ?? post.previewUrl,
                sourceId: post.sourceId,
                postId: post.id,
                variant:
                    post.variant(MediaVariantKind.sample)?.kind ??
                    post.displayMedia.kind,
                width: imageSize.width,
                height: imageSize.height,
                fit: BoxFit.contain,
                placeholderWidget: switch (thumbnail) {
                  null => null,
                  _ => BooruImage(
                    thumbnail.url,
                    sourceId: post.sourceId,
                    postId: post.id,
                    variant: thumbnail.kind,
                    width: imageSize.width,
                    height: imageSize.height,
                    fit: BoxFit.contain,
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.pageIndex, required this.pageCount});

  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '${pageIndex + 1} / $pageCount',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RelatedLoadError extends StatelessWidget {
  const _RelatedLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.36)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: describeBooruError(error),
                child: Icon(
                  Icons.error_outline,
                  size: 18,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.postDetail.relatedLoadFailed,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AppButton(
                label: t.generic.retry,
                kind: AppButtonKind.ghost,
                compact: true,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Size _fitImage({
  required Post post,
  required double maxWidth,
  required double maxHeight,
}) {
  final width = post.width.toDouble();
  final height = post.height.toDouble();
  if (width <= 0 || height <= 0) return Size(maxWidth, maxHeight);
  final scale = math.min(maxWidth / width, maxHeight / height);
  return Size(width * scale, height * scale);
}
