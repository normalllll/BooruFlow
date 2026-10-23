import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/preseeded_media.dart';

const request = MediaRequest(
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

Stream<MediaFetchEvent> chunks(Uint8List bytes, {int? total}) => Stream.value(
  MediaFetchEvent.chunk(
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

  test(
    'original decodes leave the LRU on last listener; card preview survives',
    () async {
      RustExtendedNetworkImageProvider provider(
        String id,
        MediaVariantKind variant, {
        DecodedImageRetention? retention,
      }) => RustExtendedNetworkImageProvider(
        request: MediaRequest(
          sourceId: 'source',
          postId: id,
          variant: variant,
          url: 'https://test/$id.png',
          headers: [],
          routeKey: 'route',
          cacheKey: 'cache-$id',
          authRevision: 0,
          routeRevision: '0',
          allowDiskCache: false,
        ),
        mediaStream: (_) => chunks(png),
        retention: retention,
      );
      Future<(ImageStream, ImageStreamListener)> display(
        RustExtendedNetworkImageProvider image,
      ) async {
        final ready = Completer<void>();
        final stream = image.resolve(ImageConfiguration.empty);
        final listener = ImageStreamListener(
          (info, _) {
            info.dispose();
            if (!ready.isCompleted) ready.complete();
          },
          onError: (Object error, StackTrace? stack) =>
              ready.completeError(error, stack),
        );
        stream.addListener(listener);
        await ready.future.timeout(const Duration(seconds: 5));
        expect(
          PaintingBinding.instance.imageCache.statusForKey(image).keepAlive,
          true,
        );
        return (stream, listener);
      }

      final card = provider('card', MediaVariantKind.sample);
      final (cardStream, cardListener) = await display(card);
      cardStream.removeListener(cardListener);
      for (final id in ['one', 'two', 'three']) {
        final original = provider(id, MediaVariantKind.original);
        final (stream, listener) = await display(original);
        stream.removeListener(listener);
        expect(
          PaintingBinding.instance.imageCache.statusForKey(original).keepAlive,
          false,
        );
        expect(
          PaintingBinding.instance.imageCache.statusForKey(card).keepAlive,
          true,
        );
      }
      final alias = provider(
        'card',
        MediaVariantKind.sample,
        retention: DecodedImageRetention.liveOnly,
      );
      expect(alias, isNot(card));
      final (stream, listener) = await display(alias);
      stream.removeListener(listener);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(alias).keepAlive,
        false,
      );
      expect(
        PaintingBinding.instance.imageCache.statusForKey(card).keepAlive,
        true,
      );
    },
  );

  test(
    'unvalidated legacy PNG is fetched once and only the new transfer becomes reusable',
    () async {
      await cache.writeAsBytes(png);
      var requests = 0;
      final original = MediaRequest(
        sourceId: request.sourceId,
        postId: request.postId,
        variant: MediaVariantKind.original,
        url: request.url,
        headers: [],
        routeKey: request.routeKey,
        cacheKey: request.cacheKey,
        authRevision: request.authRevision,
        routeRevision: request.routeRevision,
        allowDiskCache: true,
      );
      final provider = RustExtendedNetworkImageProvider(
        request: original,
        cacheFile: cache,
        mediaStream: (_) {
          requests++;
          return chunks(png);
        },
      );
      final info = await load(provider);
      info.dispose();
      expect(requests, 1);
      expect(await provider.cachedOriginalPng(), png);
      expect(await cache.readAsBytes(), png);
      final cached = await load(provider);
      cached.dispose();
      expect(requests, 1);
    },
  );

  for (final code in [
    BooruErrorCode.challengeRequired,
    BooruErrorCode.rateLimited,
  ]) {
    test(
      'stream failure $code retains the upstream error without immediate retries',
      () async {
        var calls = 0;
        final error = BooruError(
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
            return Stream.value(MediaFetchEvent.failed(error: error));
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
          yield MediaFetchEvent.chunk(
            bytes: Uint8List(0),
            receivedBytesDecimal: '37923',
            totalBytesDecimal: '37923',
          );
          yield MediaFetchEvent.chunk(
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
      await EncodedMediaCache(file: cache).write(request, png);
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
        mediaStream: preseededMedia,
        request: request,
        decodeWidth: 240,
      );
      final large = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: request,
        decodeWidth: 480,
      );
      final retried = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
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
        Post post(List<MediaVariant> media) => Post(
          BooruPost(
            sourceId: source,
            postId: '1',
            postKey: '$source:1',
            rating: ContentRating.general,
            tags: [],
            media: media,
            flags: const PostFlags(
              hasChildren: false,
              isPending: false,
              isDeleted: false,
              isAiGenerated: false,
            ),
          ),
        );
        const sample = MediaVariant(
          kind: MediaVariantKind.sample,
          url: 'sample',
        );
        const preview = MediaVariant(
          kind: MediaVariantKind.preview,
          url: 'preview',
        );
        const original = MediaVariant(
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
