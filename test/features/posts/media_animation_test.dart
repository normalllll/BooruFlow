import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/preseeded_media.dart';

class _TrackedCodec implements ui.Codec {
  _TrackedCodec(this.codec) : sourceFrameCount = codec.frameCount;
  final int sourceFrameCount;
  final ui.Codec codec;
  int decoded = 0;
  @override
  int get frameCount => sourceFrameCount;
  @override
  int get repetitionCount => codec.repetitionCount;
  @override
  Future<ui.FrameInfo> getNextFrame() {
    decoded++;
    return codec.getNextFrame();
  }

  @override
  void dispose() => codec.dispose();
}

void main() {
  for (final extension in ['gif', 'webp']) {
    for (final frozen in [true, false]) {
      testWidgets(
        '$extension ${frozen ? 'grid decodes only one frame' : 'stage and viewer retain animation'}',
        (tester) async {
          final bytes = File(
            'test/fixtures/media/two_frames.$extension',
          ).readAsBytesSync();
          final request = MediaRequest(
            sourceId: 'test',
            postId: 'animation',
            variant: MediaVariantKind.original,
            url: 'https://example.invalid/a.$extension',
            headers: const [],
            routeKey: 'test',
            cacheKey: '$extension/$frozen',
            authRevision: 0,
            routeRevision: 'test',
            allowDiskCache: false,
          );
          final provider = RustExtendedNetworkImageProvider(
            request: request,
            firstFrameOnly: frozen,
            mediaStream: (_) => Stream.value(
              MediaFetchEvent.chunk(
                bytes: bytes,
                receivedBytesDecimal: '${bytes.length}',
                totalBytesDecimal: '${bytes.length}',
              ),
            ),
          );
          _TrackedCodec? tracked;
          final stream = provider.loadImage(provider, (
            buffer, {
            getTargetSize,
          }) async {
            final codec = await ui.instantiateImageCodecWithSize(
              buffer,
              getTargetSize: getTargetSize,
            );
            return tracked = _TrackedCodec(codec);
          });
          var displayed = 0;
          final errors = <Object>[];
          final listener = ImageStreamListener((image, _) {
            displayed++;
            image.dispose();
          }, onError: (Object error, StackTrace? _) => errors.add(error));
          final handle = stream.keepAlive();
          stream.addListener(listener);
          try {
            for (var i = 0; i < 12; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await tester.pump(const Duration(milliseconds: 300));
            }
            expect(errors, isEmpty);
            expect(tracked, isNotNull);
            expect(tracked!.frameCount, greaterThan(1));
            expect(displayed, frozen ? 1 : greaterThan(1));
            expect(tracked!.decoded, frozen ? 1 : greaterThan(1));
          } finally {
            stream.removeListener(listener);
            handle.dispose();
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final extension in ['gif', 'webp']) {
    testWidgets('scan-enabled $extension retains animation and cache pause', (
      tester,
    ) async {
      final bytes = File(
        'test/fixtures/media/two_frames.$extension',
      ).readAsBytesSync();
      final provider = RustExtendedNetworkImageProvider(
        request: MediaRequest(
          sourceId: 'test',
          postId: 'animation',
          variant: MediaVariantKind.original,
          url: 'https://example.invalid/a.$extension',
          headers: const [],
          routeKey: 'test',
          cacheKey: 'scan/$extension',
          authRevision: 0,
          routeRevision: 'test',
          allowDiskCache: false,
        ),
        progressive: true,
        decodeWidth: 16,
        mediaStream: (_) => Stream.value(
          MediaFetchEvent.chunk(
            bytes: bytes,
            receivedBytesDecimal: '${bytes.length}',
            totalBytesDecimal: '${bytes.length}',
          ),
        ),
      );
      final stream = provider.loadImage(
        provider,
        (buffer, {getTargetSize}) => ui.instantiateImageCodecWithSize(
          buffer,
          getTargetSize: getTargetSize,
        ),
      );
      var displayed = 0;
      final listener = ImageStreamListener((image, _) {
        displayed++;
        image.dispose();
      });
      final handle = stream.keepAlive();
      stream.addListener(listener);
      Future<void> advance() async {
        for (var i = 0; i < 12; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      await advance();
      expect(displayed, greaterThan(1));
      stream.removeListener(listener);
      final paused = displayed;
      await advance();
      expect(displayed, paused);
      stream.addListener(listener);
      await advance();
      expect(displayed, greaterThan(paused + 1));
      stream.removeListener(listener);
      handle.dispose();
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'static thumbnail and animated original do not share decoded cache identity',
    () {
      const request = MediaRequest(
        sourceId: 'test',
        postId: 'animation',
        variant: MediaVariantKind.original,
        url: 'https://example.invalid/a.gif',
        headers: [],
        routeKey: 'test',
        cacheKey: 'same',
        authRevision: 0,
        routeRevision: 'test',
        allowDiskCache: false,
      );
      const thumbnail = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: request,
        firstFrameOnly: true,
      );
      const original = RustExtendedNetworkImageProvider(
        mediaStream: preseededMedia,
        request: request,
      );
      expect(thumbnail, isNot(original));
      expect(thumbnail.request.cacheKey, original.request.cacheKey);
    },
  );
  test(
    'current host Flutter AVIF codec capability is observed independently of Rust conversion',
    () async {
      final bytes = File('test/fixtures/media/white.avif').readAsBytesSync();
      Object? failure;
      ui.Codec? codec;
      try {
        codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 16);
        frame.image.dispose();
      } catch (error) {
        failure = error;
      } finally {
        codec?.dispose();
      }
      // Diagnostic only: AVIF preview success relies on the separately tested
      // existing Rust conversion, never on this platform-dependent result.
      // ignore: avoid_print
      print('R5 host Flutter AVIF native decoding: ${failure ?? 'supported'}');
    },
  );
}
