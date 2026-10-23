import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

class PostPreviewCard extends ConsumerStatefulWidget {
  const PostPreviewCard({
    super.key,
    required this.post,
    required this.onTap,
    this.imageRefreshRevision = 0,
  });
  final Post post;
  final int imageRefreshRevision;
  final void Function(FrostMediaHeroTag? tag, ImageProvider? preview) onTap;

  @override
  ConsumerState<PostPreviewCard> createState() => _PostPreviewCardState();
}

class _PostPreviewCardState extends ConsumerState<PostPreviewCard> {
  bool _authenticationRequired = false;
  ImageProvider? _decodedPreview;
  FrostMediaHeroTag? _heroTag;
  @override
  void didUpdateWidget(PostPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postKey != widget.post.postKey) {
      _authenticationRequired = false;
      _decodedPreview = null;
      _heroTag = null;
    }
  }

  void _authenticationChanged(bool value) {
    if (mounted && value != _authenticationRequired) {
      setState(() => _authenticationRequired = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final imageRefreshRevision = widget.imageRefreshRevision;
    final onTap = widget.onTap;
    final labels = Translations.of(context);
    final dimensions = post.dimensions;
    Future<void> download() async {
      final host = DownloadFlightHost.maybeOf(context);
      final box = context.findRenderObject()! as RenderBox;
      final source = box.localToGlobal(Offset.zero) & box.size;
      final preview = _decodedPreview;
      final added = await ref.read(booruDownloadsProvider).add(post);
      if (mounted && added && preview != null) {
        host?.fly(source: source, image: preview);
      }
    }

    final special = _authenticationRequired
        ? (labels.booruError.authenticationRequired, appIcons.user)
        : switch (postMediaFormat(post)) {
            PostMediaFormat.animation => (
              labels.discovery.mediaAnimation,
              appIcons.play,
            ),
            PostMediaFormat.video => (
              labels.discovery.mediaVideo,
              appIcons.play,
            ),
            _ when post.hasChildren || post.parentId != null => (
              labels.discovery.mediaCollection,
              appIcons.multiPage,
            ),
            _ => null,
          };
    final entries = postMenuEntries(
      context: context,
      post: post,
      download: download,
    );
    Widget card(FrostMediaHeroTag? tag) => FrostMediaCard(
      aspectRatio: post.width > 0 && post.height > 0
          ? (post.width / post.height).clamp(.6, 1.6)
          : 1,
      media: LayoutBuilder(
        builder: (context, constraints) => PostMedia(
          post: post,
          refreshRevision: imageRefreshRevision,
          onAuthenticationRequired: _authenticationChanged,
          onImageReady: (image) {
            if (mounted && image != null && image != _decodedPreview) {
              setState(() {
                _decodedPreview = image;
                _heroTag ??= FrostMediaHeroTag(
                  image: image,
                  aspectRatio: post.aspectRatio,
                  sourceRadius: FrostRadius.borderRadius(FrostRadius.lg),
                );
              });
            }
          },
          frameBuilder: (image) => tag == null
              ? image
              : FrostMediaHero(
                  tag: tag,
                  radius: FrostRadius.borderRadius(FrostRadius.lg),
                  child: image,
                ),
          decodeWidth:
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(1, 1536),
        ),
      ),
      topStart: special == null
          ? null
          : FrostBadge(
              label: special.$1,
              icon: special.$2,
              tone: FrostBadgeTone.onMedia,
            ),
      topEnd: Builder(
        builder: (context) => FrostPresence(
          visible: FrostClickSurface.hoveredOf(context),
          child: FrostButton.icon(
            label: labels.postDetail.download,
            icon: appIcons.download,
            style: FrostIconButtonStyle.onMedia,
            size: FrostControlSize.compact,
            onPressed: download,
          ),
        ),
      ),
      bottomEnd: dimensions != null
          ? FrostBadge(
              label:
                  '${formatCount(dimensions.$1)} × ${formatCount(dimensions.$2)}',
              tone: FrostBadgeTone.onMedia,
            )
          : null,
      contextMenu: [
        FrostMenuSection(
          header: '${post.sourceId} · #${post.id}',
          entries: entries,
        ),
      ],
      onPressed: () =>
          onTap(_decodedPreview == null ? null : tag, _decodedPreview),
      semanticLabel: '${post.sourceId} · #${post.id}',
    );
    return card(_heroTag);
  }
}
