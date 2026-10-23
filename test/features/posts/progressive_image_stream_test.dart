import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/features/posts/widgets/progressive_image_stream.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousHttp = HttpOverrides.current;
  HttpOverrides.global = null;
  tearDownAll(() => HttpOverrides.global = previousHttp);
  for (final name in [
    'r9-baseline.jpg',
    'r9-progressive.jpg',
    'r9-noninterlaced.png',
  ]) {
    test(
      'slow HTTP $name uses its scan contract, final exact pixels and complete-only cache',
      () async {
        final fixture = await _SlowFixture.open(name);
        addTearDown(fixture.close);
        final provider = fixture.provider;
        final stream = provider.resolve(ImageConfiguration.empty);
        final frames = <Future<Uint8List>>[];
        final done = Completer<void>();
        var partials = 0;
        final listener = ImageStreamListener(
          (info, _) {
            final complete =
                (stream.completer! as ProgressiveImageStreamCompleter).complete;
            if (!complete) {
              partials++;
              expect(fixture.cache.existsSync(), isFalse);
            }
            final image = info.image.clone();
            info.dispose();
            frames.add(_pixels(image));
            if (complete && !done.isCompleted) done.complete();
          },
          onError: (Object error, StackTrace? stack) {
            if (!done.isCompleted) done.completeError(error, stack);
          },
        );
        stream.addListener(listener);
        try {
          await done.future.timeout(const Duration(seconds: 15));
          expect(
            partials,
            name == 'r9-progressive.jpg' ? greaterThanOrEqualTo(3) : 0,
          );
          final all = await Future.wait(frames);
          final codec = await ui.instantiateImageCodec(
            fixture.bytes,
            targetWidth: 128,
          );
          final full = await codec.getNextFrame();
          codec.dispose();
          expect(all.last, await _pixels(full.image));
          expect(await fixture.cache.readAsBytes(), fixture.bytes);
          if (name.endsWith('.jpg')) {
            var previous = double.infinity;
            for (final pixels in all.take(partials)) {
              var error = 0;
              for (var i = 0; i < pixels.length; i++) {
                error += (pixels[i] - all.last[i]).abs();
              }
              final mean = error / pixels.length;
              expect(mean, lessThanOrEqualTo(previous));
              previous = mean;
            }
          }
        } finally {
          stream.removeListener(listener);
          await provider.evict();
        }
      },
    );
  }
  test(
    'clearing a pending preview cache cancels once without re-entering cache iteration',
    () async {
      final transport = StreamController<MediaFetchEvent>();
      final provider = RustExtendedNetworkImageProvider(
        request: const MediaRequest(
          sourceId: 'test',
          postId: 'clear',
          variant: MediaVariantKind.original,
          url: 'https://example.invalid/image.jpg',
          headers: [],
          routeKey: 'test',
          cacheKey: 'clear-pending',
          authRevision: 0,
          routeRevision: 'test',
          allowDiskCache: false,
        ),
        progressive: true,
        decodeWidth: 128,
        retries: 0,
        mediaStream: (_) => transport.stream,
      );
      final stream = provider.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener((info, _) => info.dispose());
      stream.addListener(listener);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      stream.removeListener(listener);
      expect(
        PaintingBinding.instance.imageCache.statusForKey(provider).pending,
        isTrue,
      );
      PaintingBinding.instance.imageCache.clear();
      expect(
        (stream.completer! as ProgressiveImageStreamCompleter)
            .loading
            .cancelled,
        isTrue,
      );
      await transport.close();
      PaintingBinding.instance.imageCache.clearLiveImages();
    },
  );
  test(
    'an unknown-length truncated progressive JPEG is never promoted into disk cache',
    () async {
      final fixture = await _SlowFixture.open('r9-progressive.jpg');
      addTearDown(fixture.close);
      final provider = RustExtendedNetworkImageProvider(
        request: fixture.provider.request,
        cacheFile: fixture.cache,
        decodeWidth: 128,
        progressive: true,
        retries: 0,
        mediaStream: (_) async* {
          yield MediaFetchEvent.chunk(
            bytes: Uint8List.sublistView(
              fixture.bytes,
              0,
              fixture.bytes.length ~/ 2,
            ),
            receivedBytesDecimal: '${fixture.bytes.length ~/ 2}',
          );
        },
      );
      final stream = provider.resolve(ImageConfiguration.empty);
      final failed = Completer<Object>();
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
        },
        onError: (Object error, StackTrace? _) {
          if (!failed.isCompleted) failed.complete(error);
        },
      );
      stream.addListener(listener);
      try {
        expect(
          await failed.future.timeout(const Duration(seconds: 5)),
          isA<MediaImageException>(),
        );
        expect(fixture.cache.existsSync(), isFalse);
      } finally {
        stream.removeListener(listener);
        await provider.evict();
      }
    },
  );
  test(
    'last consumer cancellation stops preview frames and never caches a prefix',
    () async {
      final fixture = await _SlowFixture.open('r9-progressive.jpg');
      addTearDown(fixture.close);
      final stream = fixture.provider.resolve(ImageConfiguration.empty);
      final first = Completer<void>();
      var count = 0;
      final listener = ImageStreamListener((info, _) {
        count++;
        info.dispose();
        if (!first.isCompleted) first.complete();
      });
      stream.addListener(listener);
      await first.future.timeout(const Duration(seconds: 10));
      stream.removeListener(listener);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final before = count;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(count, before);
      expect(
        (stream.completer! as ProgressiveImageStreamCompleter)
            .loading
            .cancelled,
        isTrue,
      );
      expect(fixture.cache.existsSync(), isFalse);
      expect(fixture.clientClosed, isTrue);
    },
  );
}

Future<Uint8List> _pixels(ui.Image image) async {
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

class _SlowFixture {
  _SlowFixture(this.bytes, this.server, this.directory);
  final Uint8List bytes;
  final HttpServer server;
  final Directory directory;
  bool clientClosed = false;
  File get cache => File('${directory.path}/image');
  static Future<_SlowFixture> open(String name) async {
    final bytes = await File('test/fixtures/media/$name').readAsBytes();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _SlowFixture(
      bytes,
      server,
      await Directory.systemTemp.createTemp('r9-prefix-'),
    );
    server.listen((request) async {
      request.response.contentLength = bytes.length;
      request.response.bufferOutput = false;
      try {
        // A deterministic real socket, rather than synthetic ImageInfo events.
        final chunkSize = (bytes.length / 18).ceil();
        for (var offset = 0; offset < bytes.length; offset += chunkSize) {
          request.response.add(
            Uint8List.sublistView(
              bytes,
              offset,
              math.min(offset + chunkSize, bytes.length),
            ),
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        await request.response.close();
      } on IOException {
        /* Client cancellation is the expected second test. */
      }
    });
    return fixture;
  }

  late final provider = RustExtendedNetworkImageProvider(
    request: MediaRequest(
      sourceId: 'test',
      postId: 'prefix',
      variant: MediaVariantKind.original,
      url: 'http://127.0.0.1:${server.port}/image',
      headers: [],
      routeKey: 'test',
      cacheKey: directory.path,
      authRevision: 0,
      routeRevision: 'test',
      allowDiskCache: true,
    ),
    retries: 0,
    decodeWidth: 128,
    progressive: true,
    cacheFile: cache,
    mediaStream: (request) async* {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(
          Uri.parse(request.url),
        )).close();
        var received = 0;
        await for (final chunk in response) {
          received += chunk.length;
          yield MediaFetchEvent.chunk(
            bytes: Uint8List.fromList(chunk),
            receivedBytesDecimal: '$received',
            totalBytesDecimal: '${response.contentLength}',
          );
        }
      } finally {
        client.close(force: true);
        clientClosed = true;
      }
    },
  );
  Future<void> close() async {
    await server.close(force: true);
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await Future<void>.delayed(Duration.zero);
    await directory.delete(recursive: true);
  }
}
