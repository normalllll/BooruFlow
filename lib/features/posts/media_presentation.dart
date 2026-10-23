import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

enum PostMediaPurpose { thumbnail, stage, original, copy }

enum PostMediaFormat { image, animation, video, unsupported }

/// Synchronous counterpart of MediaType.kind for UI selection. Calling the
/// generated Rust method would cross FFI asynchronously during widget build.
MediaKind? postMediaKind(MediaVariant media) => switch (postMediaType(media)) {
  MediaType.jpeg ||
  MediaType.png ||
  MediaType.gif ||
  MediaType.webp ||
  MediaType.avif ||
  MediaType.otherImage => MediaKind.image,
  MediaType.mp4 || MediaType.webm || MediaType.otherVideo => MediaKind.video,
  null => null,
};

MediaType? postMediaType(MediaVariant media) =>
    media.mediaType ??
    mediaTypeForExtension(
      media.extension_ ?? Uri.tryParse(media.url)?.path.split('.').last,
    );

MediaType? mediaTypeForExtension(String? extension) =>
    switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => MediaType.jpeg,
      'png' => MediaType.png,
      'gif' => MediaType.gif,
      'webp' => MediaType.webp,
      'avif' => MediaType.avif,
      'bmp' || 'wbmp' => MediaType.otherImage,
      'mp4' => MediaType.mp4,
      'webm' => MediaType.webm,
      _ => null,
    };

bool postImageDecodable(MediaVariant media) =>
    postMediaKind(media) == MediaKind.image &&
    (postMediaType(media) != MediaType.otherImage ||
        {'bmp', 'wbmp'}.contains(media.extension_?.toLowerCase()));

PostMediaFormat postMediaFormat(Post post) {
  if (post.data.media.isEmpty) return PostMediaFormat.unsupported;
  final original = post.originalMedia;
  // Ugoira is an archive, not an image codec. Its video sample can be played
  // externally; the archive itself remains the original download.
  final archive = {
    'zip',
    'ugoira',
  }.contains(original.extension_?.toLowerCase());
  if (postMediaKind(original) == MediaKind.video || archive) {
    return PostMediaFormat.video;
  }
  if (!postImageDecodable(original)) return PostMediaFormat.unsupported;
  return switch (postMediaType(original)) {
    MediaType.gif => PostMediaFormat.animation,
    MediaType.jpeg ||
    MediaType.png ||
    MediaType.webp ||
    MediaType.avif ||
    MediaType.otherImage => PostMediaFormat.image,
    _ => PostMediaFormat.unsupported,
  };
}

/// Only image variants may enter the decoder. Grid codecs show their first
/// frame; stage/viewer codecs retain GIF/WebP animation. AVIF travels through
/// the existing authenticated Rust AVIF-to-PNG conversion on every platform.
List<MediaVariant> postImageVariants(
  Post post, {
  PostMediaPurpose purpose = PostMediaPurpose.thumbnail,
  MediaVariant? preferred,
}) {
  final format = postMediaFormat(post);
  if (format == PostMediaFormat.unsupported) return const [];
  final previewFirst =
      purpose == PostMediaPurpose.thumbnail &&
      (format != PostMediaFormat.image ||
          postMediaType(post.originalMedia) == MediaType.webp);
  final order = switch ((previewFirst, format, purpose)) {
    (true, _, _) => const [
      MediaVariantKind.thumbnail,
      MediaVariantKind.preview,
      MediaVariantKind.sample,
      MediaVariantKind.original,
    ],
    (_, PostMediaFormat.video, _) ||
    (_, _, PostMediaPurpose.thumbnail) => const [
      MediaVariantKind.sample,
      MediaVariantKind.preview,
      MediaVariantKind.thumbnail,
      MediaVariantKind.original,
    ],
    (_, _, PostMediaPurpose.stage) => const [
      MediaVariantKind.sample,
      MediaVariantKind.preview,
      MediaVariantKind.original,
      MediaVariantKind.thumbnail,
    ],
    _ => const [
      MediaVariantKind.original,
      MediaVariantKind.sample,
      MediaVariantKind.preview,
      MediaVariantKind.thumbnail,
    ],
  };
  final urls = <String>{};
  final candidates = [
    for (final kind in order)
      for (final media in post.data.media)
        if (media.kind == kind &&
            postImageDecodable(media) &&
            urls.add(media.url))
          media,
  ];
  if (preferred == null || !postImageDecodable(preferred)) return candidates;
  return [
    preferred,
    ...candidates.where((media) => media.url != preferred.url),
  ];
}

/// Only an unsupported AVIF decode may fall back to the next image variant.
/// Authentication/transport failures must remain visible instead of silently
/// changing resources. Display widgets do not choose a different policy.
MediaVariant? postImageFallback(
  List<MediaVariant> candidates,
  MediaVariant failed, {
  required bool decodeFailed,
}) {
  if (!decodeFailed || postMediaType(failed) != MediaType.avif) return null;
  return candidates
      .skipWhile((media) => media.url != failed.url)
      .skip(1)
      .firstOrNull;
}

MediaVariant? postStageMedia(Post post) =>
    postImageVariants(post, purpose: PostMediaPurpose.stage).firstOrNull;

/// Prefer the original video; ugoira archives instead use their video sample.
/// Opaque archives and image covers never reach the native decoder.
MediaVariant? postPlaybackMedia(Post post) {
  for (final kind in [
    MediaVariantKind.original,
    MediaVariantKind.sample,
    MediaVariantKind.preview,
  ]) {
    for (final media in post.data.media) {
      if (media.kind == kind && postMediaKind(media) == MediaKind.video) {
        return media;
      }
    }
  }
  return null;
}
