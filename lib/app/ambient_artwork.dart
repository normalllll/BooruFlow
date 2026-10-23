import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/media_presentation_cache.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/painting.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ambient_artwork.g.dart';

/// Selects window artwork independently of the detail's display resolution.
/// The host retains decoded pixels until this provider's replacement is ready.
@Riverpod(keepAlive: true)
class AmbientArtwork extends _$AmbientArtwork {
  int _generation = 0;
  (String, String)? _identity;
  @override
  ImageProvider? build() => null;

  void show(ImageProvider image) {
    _generation++;
    _identity = null;
    if (state != image) state = image;
  }

  Future<void> select(Post post, {ImageProvider? preview}) async {
    final media = postImageVariants(post).firstOrNull;
    if (media == null) return;
    final identity = (post.postKey, media.url);
    if (_identity == identity) return;
    _identity = identity;
    final generation = ++_generation;
    if (preview != null) {
      // Reuse the grid's already decoded small frame rather than a stage image.
      if (state != preview) state = preview;
      return;
    }
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
      if (ref.mounted && generation == _generation && state != provider) {
        state = provider;
      }
    } catch (_) {
      // Artwork is optional. Its failure must neither replace the last usable
      // backdrop nor hide the independent foreground image's recovery controls.
      if (ref.mounted && generation == _generation) _identity = null;
    }
  }
}
