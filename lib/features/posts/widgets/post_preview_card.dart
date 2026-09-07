import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_preview_footer.dart';
import 'package:booruflow/features/posts/post_attribution.dart';
import 'package:booruflow/features/posts/widgets/booru_image.dart';
import 'package:booruflow/features/posts/resolution.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

class PostPreviewCard extends StatelessWidget {
  const PostPreviewCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLongPress,
    this.imageRefreshRevision = 0,
  });

  final Post post;
  final int imageRefreshRevision;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final radius = BorderRadius.circular(8);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              tokens.brand.withValues(alpha: 0.018),
              tokens.surfaceRaised,
            ),
            Color.alphaBlend(
              tokens.surfaceTint.withValues(alpha: 0.20),
              tokens.surfaceRaised,
            ),
            tokens.surfaceRaised,
          ],
          stops: const [0, 0.62, 1],
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: tokens.brand.withValues(alpha: 0.06),
            highlightColor: tokens.brand.withValues(alpha: 0.035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PostPreviewImage(
                  post: post,
                  refreshRevision: imageRefreshRevision,
                ),
                PostPreviewFooter(
                  postId: post.id,
                  author: post.authorLabel,
                  score: post.score,
                  accentColor: tokens.brand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostPreviewImage extends StatelessWidget {
  const _PostPreviewImage({required this.post, required this.refreshRevision});

  final Post post;
  final int refreshRevision;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = post.width > 0 && post.height > 0
        ? (post.width / post.height).clamp(0.6, 1.6).toDouble()
        : 1.0;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => BooruImage(
              post.previewUrl,
              refreshRevision: refreshRevision,
              decodeWidth:
                  (constraints.maxWidth *
                          MediaQuery.devicePixelRatioOf(context))
                      .ceil()
                      .clamp(1, 1536),
              sourceId: post.sourceId,
              postId: post.id,
              variant: post.displayMedia.kind,
              fit: BoxFit.cover,
              imageBuilder: (child) => child.animate().fade(duration: 250.ms),
            ),
          ),
          if (post.rating != ContentRating.general)
            PositionedDirectional(
              top: 8,
              end: 8,
              child: _RatingBadge(rating: post.rating),
            ),
          if (post.parentId != null || post.hasChildren)
            const PositionedDirectional(
              top: 8,
              start: 8,
              child: _CollectionBadge(),
            ),
          if (Resolution.match(post.width * post.height).title
              case final resolutionLabel when resolutionLabel.isNotEmpty)
            PositionedDirectional(
              end: 8,
              bottom: 8,
              child: _ResolutionBadge(label: resolutionLabel),
            ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final ContentRating rating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExplicit = rating == ContentRating.explicit;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isExplicit
            ? const Color(0xFFE53935)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
        border: isExplicit
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
        boxShadow: isExplicit
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          rating.shortLabel,
          style: TextStyle(
            color: isExplicit ? Colors.white : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _CollectionBadge extends StatelessWidget {
  const _CollectionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Icon(Icons.collections_outlined, size: 13, color: Colors.white),
      ),
    );
  }
}

class _ResolutionBadge extends StatelessWidget {
  const _ResolutionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
