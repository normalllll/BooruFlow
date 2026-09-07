import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';

const request = MediaRequestDto(
  sourceId: 'source',
  postId: '1268303',
  variant: MediaVariantKind.sample,
  url: 'https://example.com/image.png?token=secret',
  headers: [],
  routeKey: 'route',
  cacheKey: 'image',
  authRevision: 0,
  routeRevision: '0',
  allowDiskCache: true,
);

Future<ImageInfo> load(
  RustExtendedNetworkImageProvider provider, {
  ImageDecoderCallback? decode,
}) {
  final result = Completer<ImageInfo>();
  final stream = provider.loadImage(
    provider,
    decode ??
        (buffer, {getTargetSize}) => ui.instantiateImageCodecWithSize(
          buffer,
          getTargetSize: getTargetSize,
        ),
  );
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, _) {
      if (!result.isCompleted) result.complete(image);
      stream.removeListener(listener);
    },
    onError: (Object error, StackTrace? stack) {
      result.completeError(error, stack);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return result.future;
}

Stream<MediaFetchEventDto> chunks(Uint8List bytes, {int? total}) =>
    Stream.value(
      MediaFetchEventDto.chunk(
        bytes: bytes,
        receivedBytesDecimal: '${bytes.length}',
        totalBytesDecimal: '${total ?? bytes.length}',
      ),
    );

class LazyBrokenCodec implements ui.Codec {
  bool disposed = false;
  @override
  int get frameCount => 1;
  @override
  int get repetitionCount => 0;
  @override
  Future<ui.FrameInfo> getNextFrame() async =>
      throw Exception('Could not decompress image');
  @override
  void dispose() {
    disposed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  late Directory temp;
  late File cache;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('media-provider-test-');
    cache = File('${temp.path}/image');
  });
  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    await temp.delete(recursive: true);
  });

  for (final code in [
    BooruErrorCode.challengeRequired,
    BooruErrorCode.rateLimited,
  ]) {
    test(
      'stream failure $code retains the upstream error without immediate retries',
      () async {
        var calls = 0;
        final error = BooruErrorDto(
          code: code,
          sourceId: 'source',
          httpStatus: code == BooruErrorCode.rateLimited ? 429 : 403,
          userMessageKey: 'upstream',
          diagnosticId: 'stream-failed',
        );
        final provider = RustExtendedNetworkImageProvider(
          request: request,
          cacheFile: cache,
          mediaStream: (_) {
            calls++;
            return Stream.value(MediaFetchEventDto.failed(error: error));
          },
        );
        await expectLater(
          load(provider),
          throwsA(
            isA<MediaImageException>()
                .having(
                  (e) => e.toString(),
                  'upstream HTTP',
                  contains('HTTP=${error.httpStatus}'),
                )
                .having(
                  (e) => e.toString(),
                  'diagnostic',
                  contains('stream-failed'),
                )
                .having(
                  (e) => e.toString(),
                  'no false empty response',
                  isNot(contains('Incomplete image')),
                ),
          ),
        );
        expect(calls, 1);
        expect(await cache.exists(), isFalse);
      },
    );
  }

  test(
    'transcoded payload validates delivered bytes rather than original download size',
    () async {
      final provider = RustExtendedNetworkImageProvider(
        request: request,
        cacheFile: cache,
        mediaStream: (_) async* {
          yield MediaFetchEventDto.chunk(
            bytes: Uint8List(0),
            receivedBytesDecimal: '37923',
            totalBytesDecimal: '37923',
          );
          yield MediaFetchEventDto.chunk(
            bytes: png,
            receivedBytesDecimal: '${png.length}',
            totalBytesDecimal: '${png.length}',
          );
        },
      );
      final image = await load(provider);
      expect(image.image.width, 1);
      image.dispose();
      expect(await cache.readAsBytes(), png);
    },
  );

  test(
    'a lazy first-frame failure in disk cache is evicted and downloaded again',
    () async {
      await cache.writeAsBytes([1, 2, 3]);
      var downloads = 0;
      var decodes = 0;
      final broken = LazyBrokenCodec();
      final provider = RustExtendedNetworkImageProvider(
        request: request,
        cacheFile: cache,
        mediaStream: (_) {
          downloads++;
          return chunks(png);
        },
      );
      final image = await load(
        provider,
        decode: (buffer, {getTargetSize}) async {
          if (decodes++ == 0) {
            buffer.dispose();
            return broken;
          }
          return ui.instantiateImageCodecWithSize(
            buffer,
            getTargetSize: getTargetSize,
          );
        },
      );
      expect(broken.disposed, isTrue);
      expect(downloads, 1);
      expect(image.image.width, 1);
      image.dispose();
      expect(await cache.readAsBytes(), png);
      final cached = await load(provider);
      cached.dispose();
      expect(downloads, 1);
      await provider.clearCache();
      expect(await cache.exists(), isFalse);
      final retried = await load(provider);
      retried.dispose();
      expect(downloads, 2);
    },
  );

  test(
    'network decode failures retain context and never become disk cache',
    () async {
      final provider = RustExtendedNetworkImageProvider(
        request: request,
        cacheFile: cache,
        mediaStream: (_) => chunks(Uint8List.fromList([1, 2, 3])),
      );
      await expectLater(
        load(provider),
        throwsA(
          isA<MediaImageException>()
              .having((e) => e.stage, 'stage', 'decode')
              .having((e) => e.byteCount, 'bytes', 3)
              .having(
                (e) => e.toString(),
                'post context',
                contains('post=1268303'),
              )
              .having(
                (e) => e.toString(),
                'no signed query',
                isNot(contains('secret')),
              ),
        ),
      );
      expect(await cache.exists(), isFalse);
    },
  );

  test(
    'downloads with content-length mismatch still decode the received bytes',
    () async {
      var downloads = 0;
      final provider = RustExtendedNetworkImageProvider(
        request: request,
        cacheFile: cache,
        retries: 1,
        mediaStream: (_) {
          downloads++;
          return chunks(png, total: png.length + 10);
        },
      );
      final image = await load(provider);
      expect(image.image.width, 1);
      image.dispose();
      expect(downloads, 1);
      expect(await cache.exists(), isTrue);
    },
  );

  test('cache write failure does not hide a valid decoded image', () async {
    final provider = RustExtendedNetworkImageProvider(
      request: request,
      cacheFile: File('${temp.path}/missing/image'),
      mediaStream: (_) => chunks(png),
    );
    final image = await load(provider);
    expect(image.image.width, 1);
    image.dispose();
  });

  test(
    'card decoding keeps aspect ratio and limits decoded pixel dimensions',
    () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 200, 100),
        ui.Paint()..color = const ui.Color(0xFF008800),
      );
      final picture = recorder.endRecording();
      final original = await picture.toImage(200, 100);
      picture.dispose();
      final bytes = (await original.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      original.dispose();
      final image = await load(
        RustExtendedNetworkImageProvider(
          request: request,
          decodeWidth: 40,
          cacheFile: cache,
          mediaStream: (_) => chunks(bytes),
        ),
      );
      expect(image.image.width, 40);
      expect(image.image.height, 20);
      image.dispose();
    },
  );

  test(
    'card sizing is part of memory cache identity but shares encoded disk bytes',
    () {
      final small = RustExtendedNetworkImageProvider(
        request: request,
        decodeWidth: 240,
      );
      final large = RustExtendedNetworkImageProvider(
        request: request,
        decodeWidth: 480,
      );
      final retried = RustExtendedNetworkImageProvider(
        request: request,
        decodeWidth: 240,
        reloadRevision: 1,
      );
      expect(small, isNot(large));
      expect(small, isNot(retried));
      expect(small.request.cacheKey, large.request.cacheKey);
    },
  );

  test(
    'all sources prefer a sample for browsing and preserve the original',
    () {
      for (final source in ['yande', 'danbooru', 'custom']) {
        Post post(List<MediaVariantDto> media) => Post(
          BooruPostDto(
            sourceId: source,
            postId: '1',
            postKey: '$source:1',
            rating: ContentRating.general,
            tags: [],
            media: media,
            flags: const PostFlagsDto(
              hasChildren: false,
              isPending: false,
              isDeleted: false,
              isAiGenerated: false,
            ),
          ),
        );
        const sample = MediaVariantDto(
          kind: MediaVariantKind.sample,
          url: 'sample',
        );
        const preview = MediaVariantDto(
          kind: MediaVariantKind.preview,
          url: 'preview',
        );
        const original = MediaVariantDto(
          kind: MediaVariantKind.original,
          url: 'original',
        );
        expect(post([preview, original, sample]).displayMedia, sample);
        expect(post([preview, original, sample]).originalMedia, original);
        expect(post([preview, original]).displayMedia, preview);
      }
    },
  );
}
