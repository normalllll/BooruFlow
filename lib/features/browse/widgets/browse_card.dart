import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_models.dart'
    show DownloadBlock;
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// Image and corner badges only; the one hover action is download.
class BrowseCard extends ConsumerStatefulWidget {
  const BrowseCard({
    required this.post,
    required this.onTap,
    this.imageRefreshRevision = 0,
    this.onRefresh,
    super.key,
  });
  final Post post;
  final int imageRefreshRevision;

  /// Refreshes the collection the card is listed in; the context menu offers
  /// it when set.
  final VoidCallback? onRefresh;
  final void Function(FrostMediaHeroTag? tag, ImageProvider? preview) onTap;

  @override
  ConsumerState<BrowseCard> createState() => _BrowseCardState();
}

class _BrowseCardState extends ConsumerState<BrowseCard> {
  bool _authenticationRequired = false;
  ImageProvider? _decodedPreview;
  FrostMediaHeroTag? _heroTag;

  @override
  void didUpdateWidget(BrowseCard oldWidget) {
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

  /// Claims the post first; only a claimed post flies. The add then runs in
  /// the background.
  void _download() {
    final post = widget.post;
    final preview = _decodedPreview;
    final host = DownloadFlightHost.maybeOf(context);
    unawaited(
      ref
          .read(booruDownloadsProvider)
          .add(
            post,
            flight: preview == null || host == null
                ? null
                : () {
                    final box = context.findRenderObject()! as RenderBox;
                    return host.fly(
                      source: box.localToGlobal(Offset.zero) & box.size,
                      image: preview,
                      claim: BooruDownloads.identityOf(post),
                    );
                  },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final labels = Translations.of(context);
    final resolution = switch (post.dimensions) {
      final dimensions? => resolutionClass(dimensions),
      null => null,
    };
    final hover = FrostInputCapability.of(context).hoverAvailable;
    final special = _authenticationRequired
        ? (labels.booruError.authenticationRequired, FrostBadgeTone.caution)
        : switch (postMediaFormat(post)) {
            PostMediaFormat.animation => (
              labels.discovery.mediaAnimation,
              FrostBadgeTone.onMedia,
            ),
            PostMediaFormat.video => (
              labels.discovery.mediaVideo,
              FrostBadgeTone.onMedia,
            ),
            _ when post.hasChildren || post.parentId != null => (
              labels.discovery.mediaCollection,
              FrostBadgeTone.onMedia,
            ),
            _ => null,
          };
    final tag = _heroTag;
    final sourceName =
        ref
            .read(booruServiceProvider)
            .sources
            .where((source) => source.sourceId == post.sourceId)
            .firstOrNull
            ?.displayName ??
        post.sourceId;
    final title = '$sourceName · #${post.id}';
    // Selecting this post's entry keeps a card from rebuilding on unrelated
    // progress.
    final block = ref.watch(
      downloadBlocksProvider.select(
        (blocks) => blocks[BooruDownloads.identityOf(post)],
      ),
    );
    final downloadButton = FrostButton.iconOnMedia(
      label: labels.postDetail.download,
      icon: appIcons.download,
      size: FrostControlSize.compact,
      onPressed: _download,
    );
    return FrostMediaCard(
      aspectRatio: post.width > 0 && post.height > 0
          ? (post.width / post.height).clamp(.6, 1.6)
          : 1,
      media: LayoutBuilder(
        builder: (context, constraints) => PostMedia(
          post: post,
          refreshRevision: widget.imageRefreshRevision,
          onAuthenticationRequired: _authenticationChanged,
          onImageReady: (image) {
            if (mounted && image != null && image != _decodedPreview) {
              setState(() {
                _decodedPreview = image;
                _heroTag ??= FrostMediaHeroTag(
                  image: image,
                  aspectRatio: post.aspectRatio,
                );
              });
            }
          },
          frameBuilder: (image) =>
              tag == null ? image : FrostMediaHero(tag: tag, child: image),
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
              tone: special.$2,
              style: special.$2 == FrostBadgeTone.caution
                  ? FrostBadgeStyle.solid
                  : FrostBadgeStyle.tinted,
            ),
      // A saved post keeps a mark that is not an action, and one being
      // downloaded offers nothing; otherwise the action waits for hover where
      // hover is available and is always shown elsewhere.
      topEnd: switch (block) {
        DownloadBlock.saved => FrostBadge(
          label: labels.downloads.downloaded,
          icon: appIcons.check,
          tone: FrostBadgeTone.onMedia,
        ),
        DownloadBlock.inProgress => null,
        null =>
          hover
              ? Builder(
                  builder: (context) => FrostPresence(
                    visible: FrostClickSurface.hoveredOf(context),
                    child: downloadButton,
                  ),
                )
              : downloadButton,
      },
      bottomEnd: resolution == null
          ? null
          : FrostBadge(label: resolution, tone: FrostBadgeTone.onMedia),
      contextMenu: [
        FrostMenuSection(
          header: title,
          entries: [
            ...postMenuEntries(
              context: context,
              post: post,
              download: _download,
              downloadEnabled: block == null,
            ),
            if (widget.onRefresh case final refresh?) ...[
              const FrostMenuDivider(),
              FrostMenuAction(
                labels.generic.refresh,
                leading: FrostGlyph.icon(appIcons.refresh),
                onSelected: refresh,
              ),
            ],
          ],
        ),
      ],
      onPressed: () =>
          widget.onTap(_decodedPreview == null ? null : tag, _decodedPreview),
      semanticLabel: title,
    );
  }
}
