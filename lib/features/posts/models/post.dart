import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

extension ContentRatingLabel on ContentRating {
  String get displayLabel => switch (this) {
    ContentRating.general => t.postDetail.ratingGeneral,
    ContentRating.sensitive => t.postDetail.ratingSensitive,
    ContentRating.questionable => t.postDetail.ratingQuestionable,
    ContentRating.explicit => t.postDetail.ratingExplicit,
    ContentRating.unknown => t.postDetail.ratingUnknown,
  };
  String get shortLabel => switch (this) {
    ContentRating.general => 'G',
    ContentRating.sensitive => 'S',
    ContentRating.questionable => 'Q',
    ContentRating.explicit => 'E',
    ContentRating.unknown => '?',
  };
}

final class Post {
  const Post(this.data);

  final BooruPost data;

  String get id => data.postId;
  String get sourceId => data.sourceId;
  String get postKey => data.postKey;
  ContentRating get rating => data.rating;
  int get score => data.score ?? 0;
  String get tags => data.tags.map((tag) => tag.name).join(' ');
  String get author => data.author?.trim() ?? '';
  String get source => data.sourceUrl ?? data.webUrl ?? '';
  bool get hasChildren => data.flags.hasChildren;
  String? get parentId => data.flags.parentId;
  bool get isPending => data.flags.isPending;
  String? get webUrl => data.webUrl;

  MediaVariant? variant(MediaVariantKind kind) {
    for (final media in data.media) {
      if (media.kind == kind) return media;
    }
    return null;
  }

  MediaVariant get displayMedia =>
      variant(MediaVariantKind.sample) ??
      variant(MediaVariantKind.preview) ??
      variant(MediaVariantKind.thumbnail) ??
      data.media.first;

  MediaVariant get originalMedia =>
      variant(MediaVariantKind.original) ?? displayMedia;

  String get previewUrl => displayMedia.url;
  String? get fileUrl => variant(MediaVariantKind.original)?.url;
  String? get jpegUrl => variant(MediaVariantKind.sample)?.url;
  String? get sampleUrl => variant(MediaVariantKind.sample)?.url;

  /// The artwork can have known dimensions before its original URL is loaded.
  /// Preview-file dimensions remain separate from the original metadata.
  (int, int)? get dimensions =>
      _dimensions(data.width, data.height) ??
      _dimensions(originalMedia.width, originalMedia.height) ??
      _dimensions(displayMedia.width, displayMedia.height);
  int get width => dimensions?.$1 ?? 1;
  int get height => dimensions?.$2 ?? 1;
  double get aspectRatio => width > 0 && height > 0 ? width / height : 1;
  int get previewWidth => displayMedia.width ?? width;
  int get previewHeight => displayMedia.height ?? height;
  int get actualPreviewWidth => previewWidth;
  int get actualPreviewHeight => previewHeight;
  int get sampleWidth => variant(MediaVariantKind.sample)?.width ?? width;
  int get sampleHeight => variant(MediaVariantKind.sample)?.height ?? height;
  int get jpegWidth => sampleWidth;
  int get jpegHeight => sampleHeight;
  int get fileSize =>
      int.tryParse(data.originalFileSizeDecimal ?? '') ??
      int.tryParse(
        variant(MediaVariantKind.original)?.byteLengthDecimal ?? '',
      ) ??
      0;
  int get sampleFileSize =>
      int.tryParse(variant(MediaVariantKind.sample)?.byteLengthDecimal ?? '') ??
      0;
  int get jpegFileSize => sampleFileSize;
  String get fileExt =>
      data.originalFileExtension ??
      variant(MediaVariantKind.original)?.extension_ ??
      '';
  String get md5 {
    final checksum =
        data.originalChecksum ?? variant(MediaVariantKind.original)?.checksum;
    return switch (checksum) {
      Checksum(algorithm: ChecksumAlgorithm.md5, :final value) => value,
      _ => '',
    };
  }

  int get createdAt {
    final value = DateTime.tryParse(data.createdAtIso8601 ?? '');
    return switch (value) {
      null => 0,
      _ => value.millisecondsSinceEpoch ~/ 1000,
    };
  }

  int get resourceId {
    var hash = 0x811c9dc5;
    for (final unit in postKey.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

(int, int)? _dimensions(int? width, int? height) =>
    width != null && height != null && width > 0 && height > 0
    ? (width, height)
    : null;

String postCreator(Post post, {String? Function(String tag)? translate}) {
  for (final category in postHeadlineCategories) {
    final names = post.data.tags
        .where((tag) => tag.category == category && tag.name.trim().isNotEmpty)
        .map(
          (tag) => translate?.call(tag.name) ?? tag.name.replaceAll('_', ' '),
        )
        .toList();
    if (names.isNotEmpty) return names.join(' · ');
  }
  return '#${post.id}';
}

const postHeadlineCategories = [
  TagCategory.artist,
  TagCategory.character,
  TagCategory.copyright,
];

TagCategory? postHeadlineCategory(Post post) => postHeadlineCategories
    .where(
      (category) => post.data.tags.any(
        (tag) => tag.category == category && tag.name.trim().isNotEmpty,
      ),
    )
    .firstOrNull;

/// Copyright belongs in metadata only when the character is the headline.
List<String> postCopyrightMetadata(Post post) =>
    postHeadlineCategory(post) == TagCategory.character
    ? post.data.tags
          .where((tag) => tag.category == TagCategory.copyright)
          .map((tag) => tag.name.replaceAll('_', ' '))
          .toList()
    : const [];
