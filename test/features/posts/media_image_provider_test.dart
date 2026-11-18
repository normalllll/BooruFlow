import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/core/media/booru_media_source.dart';
import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/media_cache.dart';
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
  CachedMediaImage provider, {
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

/// A picture stored in [cache], fetched with [mediaStream].
CachedMediaImage storedImage({
  required MediaRequest request,
  required BooruMediaStream mediaStream,
  EncodedMediaCache? cache,
  int retries = 2,
  int? decodeWidth,
  int reloadRevision = 0,
}) => CachedMediaImage(
  BooruMediaSource(request, mediaStream),
  store: cache?.imageStore,
  retries: retries,
  reloadRevision: reloadRevision,
  decodeBox: decodeWidth == null
      ? null
      : Size(decodeWidth.toDouble(), double.infinity),
);

/// Waits for the unawaited write of a fetched picture to land.
Future<void> stored(File file) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!await file.exists()) {
    if (DateTime.now().isAfter(deadline)) fail("${file.path} was not written");
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
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
      CachedMediaImage provider(
        String id,
        MediaVariantKind variant, {
        bool? retainDecoded,
      }) => booruMediaImage(
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
        stream: (_, _) => chunks(png),
        retainDecoded: retainDecoded,
      );
      Future<(ImageStream, ImageStreamListener)> display(
        CachedMediaImage image,
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
        retainDecoded: false,
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

  test('a stored PNG without its proof is shown from disk and not handed to the clipboard', () async {
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
    final provider = storedImage(
      request: original,
      cache: fileMediaCache(cache),
      mediaStream: (_, _) {
        requests++;
        return chunks(png);
      },
    );
    final info = await load(provider);
    info.dispose();
    expect(requests, 0);
    expect(await fileMediaCache(cache).readPng(original), isNull);
    expect(await cache.readAsBytes(), png);
  });

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
        final provider = storedImage(
          request: request,
          cache: fileMediaCache(cache),
          mediaStream: (_, _) {
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

  test('transcoded payload validates delivered bytes rather than original download size', () async {
    final provider = storedImage(
      request: request,
      cache: fileMediaCache(cache),
      mediaStream: (_, _) async* {
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
    await stored(cache);
    expect(await cache.readAsBytes(), png);
  });

  test(
    'a lazy first-frame failure in disk cache is evicted and downloaded again',
    () async {
      await fileMediaCache(cache).write(request, png);
      var downloads = 0;
      var decodes = 0;
      final broken = LazyBrokenCodec();
      final provider = storedImage(
        request: request,
        cache: fileMediaCache(cache),
        mediaStream: (_, _) {
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
      await stored(cache);
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
      final provider = storedImage(
        request: request,
        cache: fileMediaCache(cache),
        mediaStream: (_, _) => chunks(Uint8List.fromList([1, 2, 3])),
      );
      await expectLater(
        load(provider),
        throwsA(
          isA<MediaImageException>()
              .having((e) => e.stage, 'stage', MediaImageStage.decode)
              .having((e) => e.byteCount, 'bytes', 3)
              .having(
                (e) => booruErrorDetails(e),
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

  test('a transfer that ends short of its announced length is retried and never stored', () async {
    var downloads = 0;
    final provider = storedImage(
      request: request,
      cache: fileMediaCache(cache),
      retries: 1,
      mediaStream: (_, _) {
        downloads++;
        return chunks(png, total: png.length + 10);
      },
    );
    await expectLater(
      load(provider),
      throwsA(
        isA<MediaImageException>().having(
          (e) => e.stage,
          'stage',
          MediaImageStage.fetch,
        ),
      ),
    );
    expect(downloads, 2);
    expect(await cache.exists(), isFalse);
  });

  test('cache write failure does not hide a valid decoded image', () async {
    final provider = storedImage(
      request: request,
      cache: fileMediaCache(File('${temp.path}/missing/image')),
      mediaStream: (_, _) => chunks(png),
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
      final bytes = (await original.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      original.dispose();
      final image = await load(
        storedImage(
          request: request,
          decodeWidth: 40,
          cache: fileMediaCache(cache),
          mediaStream: (_, _) => chunks(bytes),
        ),
      );
      expect(image.image.width, 40);
      expect(image.image.height, 20);
      image.dispose();
    },
  );

  test('card sizing is part of memory cache identity but shares encoded disk bytes', () {
    final small = storedImage(
      mediaStream: preseededMedia,
      request: request,
      decodeWidth: 240,
    );
    final large = storedImage(
      mediaStream: preseededMedia,
      request: request,
      decodeWidth: 480,
    );
    final retried = storedImage(
      mediaStream: preseededMedia,
      request: request,
      decodeWidth: 240,
      reloadRevision: 1,
    );
    expect(small, isNot(large));
    expect(small, isNot(retried));
    expect(small.request!.cacheKey, large.request!.cacheKey);
  });

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

  test('scans are previewed only for a picture decoded at a set width', () {
    const jpeg = MediaVariant(
      kind: MediaVariantKind.sample,
      url: 'https://example.invalid/a.jpg',
      mediaType: MediaType.jpeg,
    );
    const gif = MediaVariant(
      kind: MediaVariantKind.sample,
      url: 'https://example.invalid/a.gif',
      mediaType: MediaType.gif,
    );
    bool progressive(
      PostMediaPurpose purpose,
      MediaVariant media,
      int? width,
    ) => postMediaProgressive(
      purpose: purpose,
      media: media,
      decodeWidth: width,
    );
    expect(progressive(PostMediaPurpose.stage, jpeg, 800), isTrue);
    expect(progressive(PostMediaPurpose.stage, jpeg, null), isFalse);
    expect(progressive(PostMediaPurpose.thumbnail, jpeg, 800), isFalse);
    expect(progressive(PostMediaPurpose.stage, gif, 800), isFalse);
  });
}
