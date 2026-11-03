import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/media_presentation_cache.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/painting.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ambient_artwork.g.dart';

/// One page's artwork request; the newest live claim is the window artwork.
class _Claim {
  int generation = 0;
  (String, String)? identity;
  ImageProvider? image;
}

/// Window artwork chosen by the pages that show a work, independently of the
/// detail's display resolution. Each page claims it with itself as owner and
/// releases the claim when it goes away; the newest remaining claim wins, and
/// with none left the window has no artwork. The host retains decoded pixels
/// until a replacement is ready.
@Riverpod(keepAlive: true)
class AmbientArtwork extends _$AmbientArtwork {
  // Insertion order is recency: a claim moves to the end when it selects.
  final _claims = <Object, _Claim>{};

  @override
  ImageProvider? build() => null;

  /// The artwork [owner] last resolved, whether or not it is shown now.
  ImageProvider? imageOf(Object owner) => _claims[owner]?.image;

  void _publish() {
    final next = _claims.isEmpty ? null : _claims.values.last.image;
    if (state != next) state = next;
  }

  Future<void> select(Object owner, Post post, {ImageProvider? preview}) async {
    final media = postImageVariants(post).firstOrNull;
    if (media == null) return;
    final claim = _claims.remove(owner) ?? _Claim();
    _claims[owner] = claim;
    final identity = (post.postKey, media.url);
    if (claim.identity == identity) {
      // Still resolving: keep what the window shows until it is ready.
      if (claim.image != null) _publish();
      return;
    }
    claim.identity = identity;
    final generation = ++claim.generation;
    if (preview != null) {
      // Reuse the grid's already decoded small frame rather than a stage image.
      claim.image = preview;
      _publish();
      return;
    }
    bool current() =>
        ref.mounted &&
        identical(_claims[owner], claim) &&
        generation == claim.generation;
    try {
      final provider = await ref
          .read(mediaPresentationCacheProvider)
          .resolve(
            sourceId: post.sourceId,
            postId: post.id,
            media: media,
            decodeWidth: FrostAmbientBackdropHost.sampleWidth,
            reloadRevision: 0,
            firstFrameOnly: {
              MediaType.gif,
              MediaType.webp,
            }.contains(postMediaType(media)),
          );
      if (current()) {
        claim.image = provider;
        _publish();
      }
    } catch (_) {
      // Artwork is optional. Its failure must neither replace the last usable
      // backdrop nor hide the independent foreground image's recovery controls.
      if (current()) claim.identity = null;
    }
  }

  /// Drops [owner]'s claim; the window returns to the previous claim, or to no
  /// artwork when none is left.
  void release(Object owner) {
    // A page may outlive the app's providers when everything is torn down.
    if (_claims.remove(owner) != null && ref.mounted) _publish();
  }
}
