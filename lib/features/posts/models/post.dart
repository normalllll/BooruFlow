import 'package:booruflow/src/rust/api/booru_models.dart';

extension ContentRatingLabel on ContentRating {
  String get shortLabel => switch (this) {
    ContentRating.general => 'G',
    ContentRating.sensitive => 'S',
    ContentRating.questionable => 'Q',
    ContentRating.explicit => 'E',
    ContentRating.unknown => '?',
  };
}

final class Post {
  const Post(this.dto);

  final BooruPostDto dto;

  String get id => dto.postId;
  String get sourceId => dto.sourceId;
  String get postKey => dto.postKey;
  ContentRating get rating => dto.rating;
  int get score => dto.score ?? 0;
  String get tags => dto.tags.map((tag) => tag.name).join(' ');
  String get author => dto.author?.trim() ?? '';
  String get source => dto.sourceUrl ?? dto.webUrl ?? '';
  bool get hasChildren => dto.flags.hasChildren;
  String? get parentId => dto.flags.parentId;
  bool get isPending => dto.flags.isPending;
  String? get webUrl => dto.webUrl;

  MediaVariantDto? variant(MediaVariantKind kind) {
    for (final media in dto.media) {
      if (media.kind == kind) return media;
    }
    return null;
  }

  MediaVariantDto get displayMedia =>
      variant(MediaVariantKind.sample) ??
      variant(MediaVariantKind.preview) ??
      variant(MediaVariantKind.thumbnail) ??
      dto.media.first;

  MediaVariantDto get originalMedia =>
      variant(MediaVariantKind.original) ?? displayMedia;

  String get previewUrl => displayMedia.url;
  String? get fileUrl => variant(MediaVariantKind.original)?.url;
  String? get jpegUrl => variant(MediaVariantKind.sample)?.url;
  String? get sampleUrl => variant(MediaVariantKind.sample)?.url;
  int get width => originalMedia.width ?? displayMedia.width ?? 1;
  int get height => originalMedia.height ?? displayMedia.height ?? 1;
  int get previewWidth => displayMedia.width ?? width;
  int get previewHeight => displayMedia.height ?? height;
  int get actualPreviewWidth => previewWidth;
  int get actualPreviewHeight => previewHeight;
  int get sampleWidth => variant(MediaVariantKind.sample)?.width ?? width;
  int get sampleHeight => variant(MediaVariantKind.sample)?.height ?? height;
  int get jpegWidth => sampleWidth;
  int get jpegHeight => sampleHeight;
  int get fileSize => int.tryParse(originalMedia.byteLengthDecimal ?? '') ?? 0;
  int get sampleFileSize =>
      int.tryParse(variant(MediaVariantKind.sample)?.byteLengthDecimal ?? '') ??
      0;
  int get jpegFileSize => sampleFileSize;
  String get fileExt => originalMedia.extension_ ?? 'jpg';
  String get md5 => originalMedia.checksum?.value ?? '';
  int get createdAt {
    final value = DateTime.tryParse(dto.createdAtIso8601 ?? '');
    return value == null ? 0 : value.millisecondsSinceEpoch ~/ 1000;
  }

  int get resourceId {
    var hash = 0x811c9dc5;
    for (final unit in postKey.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
