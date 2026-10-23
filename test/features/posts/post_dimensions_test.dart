import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_test/flutter_test.dart';

Post listing({
  int? width,
  int? height,
  int? previewWidth,
  int? previewHeight,
  String? originalSize,
  String? originalExtension,
  Checksum? originalChecksum,
}) => Post(
  BooruPost(
    sourceId: 'anime_pictures',
    postId: '1',
    postKey: 'anime_pictures:1',
    width: width,
    height: height,
    originalFileSizeDecimal: originalSize,
    originalFileExtension: originalExtension,
    originalChecksum: originalChecksum,
    rating: ContentRating.general,
    tags: const [],
    media: [
      MediaVariant(
        kind: MediaVariantKind.sample,
        url: 'https://opreviews.anime-pictures.net/abc/example_bp.avif',
        width: previewWidth,
        height: previewHeight,
        extension_: 'avif',
      ),
    ],
    flags: const PostFlags(
      hasChildren: false,
      isPending: false,
      isDeleted: false,
      isAiGenerated: false,
    ),
  ),
);

void main() {
  test('original metadata survives a preview-only listing', () {
    final post = listing(width: 1309, height: 2000);
    expect(post.fileUrl, isNull);
    expect(post.dimensions, (1309, 2000));
    expect(post.aspectRatio, 1309 / 2000);
    expect(post.displayMedia.width, isNull);
  });
  test('artwork dimensions do not overwrite resized preview dimensions', () {
    final post = listing(
      width: 1309,
      height: 2000,
      previewWidth: 393,
      previewHeight: 600,
    );
    expect((post.width, post.height), (1309, 2000));
    expect((post.previewWidth, post.previewHeight), (393, 600));
  });
  test('original file facts survive without an original URL', () {
    final post = listing(
      originalSize: '2397010',
      originalExtension: 'png',
      originalChecksum: const Checksum(
        algorithm: ChecksumAlgorithm.md5,
        value: '0123456789abcdef0123456789abcdef',
      ),
    );
    expect(post.fileUrl, isNull);
    expect(post.fileSize, 2397010);
    expect(post.fileExt, 'png');
    expect(post.md5, '0123456789abcdef0123456789abcdef');
    expect(post.displayMedia.extension_, 'avif');
    expect(post.displayMedia.checksum, isNull);
  });
  test(
    'preview metadata never substitutes for unknown original file facts',
    () {
      final post = listing();
      expect(post.displayMedia.extension_, 'avif');
      expect(post.fileExt, isEmpty);
      expect(post.fileSize, 0);
      expect(post.md5, isEmpty);
    },
  );
  test('a different checksum algorithm is never exposed as MD5', () {
    final post = listing(
      originalChecksum: const Checksum(
        algorithm: ChecksumAlgorithm.sha256,
        value: 'a-different-algorithm',
      ),
    );
    expect(post.md5, isEmpty);
  });
  test('media-only posts retain their existing geometry', () {
    final post = listing(previewWidth: 400, previewHeight: 600);
    expect(post.dimensions, (400, 600));
    expect(post.aspectRatio, 2 / 3);
  });
  test(
    'partial original metadata never mixes with a different file height',
    () {
      final post = listing(width: 1309, previewWidth: 400, previewHeight: 600);
      expect(post.dimensions, (400, 600));
    },
  );
  for (final size in [(null, null), (0, 0), (-1, 2000), (1309, null)]) {
    test(
      'unknown or invalid dimensions $size retain only the geometry fallback',
      () {
        final post = listing(width: size.$1, height: size.$2);
        expect(post.dimensions, isNull);
        expect((post.width, post.height), (1, 1));
        expect(post.aspectRatio, 1);
      },
    );
  }
}
