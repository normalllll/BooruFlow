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
