import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'jpeg_scan_buffer.dart';
import 'progressive_image_stream.dart';

/// Preview pixels use the shared LRU; full-resolution display pixels are live
/// only, even when a source aliases its sample and original URLs.
enum DecodedImageRetention { cached, liveOnly }

@immutable
final class RustExtendedNetworkImageProvider
    extends ImageProvider<RustExtendedNetworkImageProvider> {
  const RustExtendedNetworkImageProvider({
    required this.request,
    this.scale = 1,
    this.retries = 2,
    this.decodeWidth,
    this.reloadRevision = 0,
    this.firstFrameOnly = false,
    this.progressive = false,
    this.retention,
    required this.mediaStream,
    this.cacheFile,
  }) : assert(retries >= 0),
       assert(decodeWidth == null || decodeWidth > 0);

  final MediaRequest request;
  final double scale;
  final int retries;
  final int? decodeWidth;
  final int reloadRevision;
  final bool firstFrameOnly;
  final bool progressive;
  final DecodedImageRetention? retention;
  DecodedImageRetention get decodedRetention =>
      retention ??
      (request.variant == MediaVariantKind.original
          ? DecodedImageRetention.liveOnly
          : DecodedImageRetention.cached);

  /// Fetch with the same injected engine that prepared this request.
  final Stream<MediaFetchEvent> Function(MediaRequest) mediaStream;
  @visibleForTesting
  final File? cacheFile;

  Future<void> clearCache() async {
    await evict();
    await _deleteCache();
  }

  @override
  Future<RustExtendedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    RustExtendedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunks = StreamController<ImageChunkEvent>();
    final ImageStreamCompleter completer;
    if (progressive && decodeWidth != null) {
      completer = ProgressiveImageStreamCompleter(
        load: (loading) => _load(key, chunks, decode, loading),
        scale: scale,
        chunkEvents: chunks.stream,
        debugLabel:
            '${request.sourceId}/${request.postId}/${request.variant.name}',
        evictIncomplete: () {
          final cache = PaintingBinding.instance.imageCache;
          final status = cache.statusForKey(key);
          // clear() removes pending listeners while iterating its pending map.
          // Never re-enter that removal. Only completed preview entries need
          // our eviction; Flutter already owns pending/live cleanup.
          if (!status.pending && status.keepAlive) {
            cache.evict(key, includeLive: false);
          }
        },
      );
    } else {
      completer = MultiFrameImageStreamCompleter(
        codec: _load(key, chunks, decode),
        scale: scale,
        chunkEvents: chunks.stream,
        debugLabel:
            '${request.sourceId}/${request.postId}/${request.variant.name}',
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<String>('Source', request.sourceId),
          DiagnosticsProperty<String>('Post', request.postId),
        ],
      );
    }
    if (decodedRetention == DecodedImageRetention.liveOnly) {
      // Originals share their live completer across visible subscribers, but
      // never retain decoded pixels after the final subscriber leaves. Encoded
      // disk data remains available for export and the next display decode.
      completer.addOnLastListenerRemovedCallback(() {
        final cache = PaintingBinding.instance.imageCache;
        if (!cache.statusForKey(key).pending) {
          cache.evict(key, includeLive: false);
        }
      });
    }
    return completer;
  }

  Future<ui.Codec> _load(
    RustExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode, [
    ProgressiveImageLoading? loading,
  ]) async {
    try {
      final cached = await _readCache();
      loading?.checkActive();
      if (cached != null) {
        try {
          final codec = await _decode(cached, decode, fromCache: true);
          return codec;
        } catch (_) {
          await _deleteCache();
        }
      }
      final bytes = await _loadRust(chunkEvents, loading);
      loading?.checkActive();
      // Codecs are lazy: creating one does not prove the first frame can decode.
      // Keep that frame for the image stream, and only cache validated bytes.
      final codec = await _decode(bytes, decode, fromCache: false);
      if (request.allowDiskCache) {
        await _writeCache(bytes);
      }
      return codec;
    } on ImageLoadCancelled {
      rethrow;
    } catch (error, stack) {
      PaintingBinding.instance.imageCache.evict(key);
      Error.throwWithStackTrace(switch (error) {
        MediaImageException() => error,
        _ => MediaImageException(
          request: request,
          stage: 'download',
          cause: makeBooruErrorReadable(error),
        ),
      }, stack);
    } finally {
      unawaited(chunkEvents.close());
    }
  }

  Future<ui.Codec> _decode(
    Uint8List bytes,
    ImageDecoderCallback decode, {
    required bool fromCache,
  }) async {
    ui.Codec? codec;
    MediaImageException failure(Object error) => MediaImageException(
      request: request,
      stage: 'decode',
      cause: error,
      byteCount: bytes.length,
      fromCache: fromCache,
    );
    try {
      // Engine JPEG decoding accepts an unfinished progressive scan. Such a
      // preview is useful while downloading but cannot validate a cache file.
      if (progressive && !_hasCompleteImageTrailer(bytes)) {
        throw StateError('Incomplete image trailer');
      }
      codec = await decode(
        await ui.ImmutableBuffer.fromUint8List(bytes),
        getTargetSize: switch (decodeWidth) {
          null => null,
          final targetWidth => (width, height) => ui.TargetImageSize(
            width: width < targetWidth ? width : targetWidth,
          ),
        },
      );
      final firstFrame = await codec.getNextFrame();
      return _ValidatedCodec(codec, firstFrame, (error) async {
        await _deleteCache();
        await evict();
        return failure(error);
      }, firstFrameOnly: firstFrameOnly);
    } catch (error, stack) {
      codec?.dispose();
      Error.throwWithStackTrace(failure(error), stack);
    }
  }

  Future<Uint8List> _loadRust(
    StreamController<ImageChunkEvent> chunkEvents,
    ProgressiveImageLoading? loading,
  ) async {
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 0; attempt <= retries; attempt++) {
      final builder = loading == null ? BytesBuilder(copy: false) : null;
      var received = 0;
      try {
        await loading?.begin(decodeWidth!);
        int? expectedBytes;
        final stream = mediaStream(request);
        final iterator = StreamIterator(
          stream.timeout(const Duration(seconds: 45)),
        );
        loading?.cancelStream = iterator.cancel;
        loading?.checkActive();
        try {
          while (await iterator.moveNext()) {
            loading?.checkActive();
            final event = iterator.current;
            switch (event) {
              case MediaFetchEvent_Failed(:final error):
                throw error;
              case MediaFetchEvent_Chunk(
                :final bytes,
                :final receivedBytesDecimal,
                :final totalBytesDecimal,
              ):
                received += bytes.length;
                if (loading == null) {
                  builder!.add(bytes);
                } else {
                  loading.add(bytes);
                }
                expectedBytes =
                    int.tryParse(totalBytesDecimal ?? '') ?? expectedBytes;
                chunkEvents.add(
                  ImageChunkEvent(
                    cumulativeBytesLoaded:
                        int.tryParse(receivedBytesDecimal) ?? received,
                    expectedTotalBytes: int.tryParse(totalBytesDecimal ?? ''),
                  ),
                );
            }
          }
        } finally {
          await iterator.cancel();
          loading?.cancelStream = null;
        }
        loading?.checkActive();
        final isEmpty = received == 0;
        final isLengthMismatch =
            expectedBytes != null && received != expectedBytes;
        if (isEmpty) {
          throw StateError(
            'Incomplete image: received 0 bytes, expected ${expectedBytes ?? "unknown"}',
          );
        }
        if (isLengthMismatch) {
          final expected = expectedBytes;
          debugPrint(
            'Image download size mismatch. source=${request.sourceId} '
            'post=${request.postId} variant=${request.variant.name} '
            'received=$received expected=$expected',
          );
        }
        return loading == null ? builder!.takeBytes() : await loading.finish();
      } catch (error, stack) {
        await loading?.endAttempt();
        if (error is ImageLoadCancelled) rethrow;
        if (error is BooruError &&
            ![
              BooruErrorCode.network,
              BooruErrorCode.timeout,
              BooruErrorCode.sourceUnavailable,
            ].contains(error.code)) {
          Error.throwWithStackTrace(makeBooruErrorReadable(error), stack);
        }
        lastError = error;
        lastStack = stack;
        if (attempt < retries) {
          await Future<void>.delayed(Duration(milliseconds: 120 << attempt));
        }
      }
    }
    Error.throwWithStackTrace(makeBooruErrorReadable(lastError!), lastStack!);
  }

  EncodedMediaCache get _cache => EncodedMediaCache(file: cacheFile);
  Future<Uint8List?> _readCache() => _cache.read(request);
  Future<void> _deleteCache() => _cache.remove(request);
  Future<void> _writeCache(Uint8List bytes) => _cache.write(request, bytes);

  /// Only a complete original PNG is eligible for direct clipboard bytes.
  Future<Uint8List?> cachedOriginalPng() =>
      request.variant == MediaVariantKind.original
      ? _cache.readPng(request)
      : Future.value(null);

  @override
  bool operator ==(Object other) =>
      other is RustExtendedNetworkImageProvider &&
      other.request.cacheKey == request.cacheKey &&
      other.scale == scale &&
      other.decodeWidth == decodeWidth &&
      other.reloadRevision == reloadRevision &&
      other.firstFrameOnly == firstFrameOnly &&
      other.decodedRetention == decodedRetention;

  @override
  int get hashCode => Object.hash(
    request.cacheKey,
    scale,
    decodeWidth,
    reloadRevision,
    firstFrameOnly,
    decodedRetention,
  );
}

final class MediaImageException implements Exception {
  const MediaImageException({
    required this.request,
    required this.stage,
    required this.cause,
    this.byteCount,
    this.fromCache = false,
  });
  final MediaRequest request;
  final String stage;
  final Object cause;
  final int? byteCount;
  final bool fromCache;

  @override
  String toString() {
    final uri = Uri.tryParse(request.url);
    // Authentication headers and signed query parameters are never diagnostics.
    final location = switch (uri) {
      null => '(invalid URL)',
      _ => '${uri.scheme}://${uri.host}${uri.path}',
    };
    return 'source=${request.sourceId} · post=${request.postId} · variant=${request.variant.name}\n'
        'stage=$stage · cache=$fromCache${switch (byteCount) {
          null => "",
          _ => " · bytes=$byteCount",
        }}\n'
        '$location\n${describeBooruError(cause).replaceAll(request.url, location)}';
  }
}

/// Keep decode/transport failures distinct without interpreting translated text.
Object mediaImageCause(Object error) {
  final cause = error is MediaImageException ? error.cause : error;
  return cause is BooruReadableException ? cause.cause : cause;
}

bool isMediaImageDecodeFailure(Object error) {
  final cause = mediaImageCause(error);
  return error is MediaImageException && error.stage == 'decode' ||
      cause is BooruError &&
          cause.userMessageKey == 'booru.error.imageDecodeFailed';
}

/// Replays the validated first frame without losing animation timing/frames.
final class _ValidatedCodec implements ui.Codec {
  _ValidatedCodec(
    this.delegate,
    this.firstFrame,
    this.onError, {
    required this.firstFrameOnly,
  });
  final bool firstFrameOnly;
  final ui.Codec delegate;
  ui.FrameInfo? firstFrame;
  final Future<Object> Function(Object) onError;
  @override
  int get frameCount => firstFrameOnly ? 1 : delegate.frameCount;
  @override
  int get repetitionCount => firstFrameOnly ? 0 : delegate.repetitionCount;
  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final frame = firstFrame;
    if (frame != null) {
      firstFrame = null;
      return frame;
    }
    try {
      return await delegate.getNextFrame();
    } catch (error, stack) {
      Error.throwWithStackTrace(await onError(error), stack);
    }
  }

  @override
  void dispose() {
    firstFrame?.image.dispose();
    firstFrame = null;
    delegate.dispose();
  }
}

// Only the unmodified transport bytes reach validation. Temporary JPEG EOI
// markers live solely in the background JPEG scan accumulator.
bool _hasCompleteImageTrailer(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255) {
    return bytes.length >= 4 &&
        bytes[bytes.length - 2] == 255 &&
        bytes.last == 217;
  }
  if (bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71) {
    const end = [0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
    return bytes.length >= end.length &&
        listEquals(bytes.sublist(bytes.length - end.length), end);
  }
  return true;
}
