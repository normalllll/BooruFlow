import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart'
    show cacheImageFolderName, keyToMd5;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';

@immutable
final class RustExtendedNetworkImageProvider
    extends ImageProvider<RustExtendedNetworkImageProvider> {
  const RustExtendedNetworkImageProvider({
    required this.request,
    this.scale = 1,
    this.retries = 2,
    this.decodeWidth,
    this.reloadRevision = 0,
    this.mediaStream,
    this.cacheFile,
  }) : assert(retries >= 0),
       assert(decodeWidth == null || decodeWidth > 0);

  final MediaRequestDto request;
  final double scale;
  final int retries;
  final int? decodeWidth;
  final int reloadRevision;
  @visibleForTesting
  final Stream<MediaFetchEventDto> Function(MediaRequestDto)? mediaStream;
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
    return MultiFrameImageStreamCompleter(
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

  Future<ui.Codec> _load(
    RustExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      final cached = await _readCache();
      if (cached != null) {
        try {
          return await _decode(cached, decode, fromCache: true);
        } catch (_) {
          await _deleteCache();
        }
      }
      final bytes = await _loadRust(chunkEvents);
      // Codecs are lazy: creating one does not prove the first frame can decode.
      // Keep that frame for the image stream, and only cache validated bytes.
      final codec = await _decode(bytes, decode, fromCache: false);
      if (request.allowDiskCache) {
        await _writeCache(bytes);
      }
      return codec;
    } catch (error, stack) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      Error.throwWithStackTrace(
        error is MediaImageException
            ? error
            : MediaImageException(
                request: request,
                stage: 'download',
                cause: makeBooruErrorReadable(error),
              ),
        stack,
      );
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
      codec = await decode(
        await ui.ImmutableBuffer.fromUint8List(bytes),
        getTargetSize: decodeWidth == null
            ? null
            : (width, height) => ui.TargetImageSize(
                width: width < decodeWidth! ? width : decodeWidth,
              ),
      );
      final firstFrame = await codec.getNextFrame();
      return _ValidatedCodec(codec, firstFrame, (error) async {
        await _deleteCache();
        await evict();
        return failure(error);
      });
    } catch (error, stack) {
      codec?.dispose();
      Error.throwWithStackTrace(failure(error), stack);
    }
  }

  Future<Uint8List> _loadRust(
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 0; attempt <= retries; attempt++) {
      final builder = BytesBuilder(copy: false);
      try {
        int? expectedBytes;
        final stream =
            mediaStream?.call(request) ??
            BooruService.instance.engine.streamMedia(request: request);
        await for (final event in stream.timeout(const Duration(seconds: 45))) {
          switch (event) {
            case MediaFetchEventDto_Failed(:final error):
              throw error;
            case MediaFetchEventDto_Chunk(
              :final bytes,
              :final receivedBytesDecimal,
              :final totalBytesDecimal,
            ):
              builder.add(bytes);
              expectedBytes =
                  int.tryParse(totalBytesDecimal ?? '') ?? expectedBytes;
              chunkEvents.add(
                ImageChunkEvent(
                  cumulativeBytesLoaded:
                      int.tryParse(receivedBytesDecimal) ?? builder.length,
                  expectedTotalBytes: int.tryParse(totalBytesDecimal ?? ''),
                ),
              );
          }
        }
        final isEmpty = builder.isEmpty;
        final isLengthMismatch =
            expectedBytes != null && builder.length != expectedBytes;
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
            'received=${builder.length} expected=$expected',
          );
        }
        return builder.takeBytes();
      } catch (error, stack) {
        if (error is BooruErrorDto &&
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

  Future<File> _cacheFile() async {
    if (cacheFile != null) return cacheFile!;
    final temp = await getTemporaryDirectory();
    final directory = Directory(path.join(temp.path, cacheImageFolderName));
    await directory.create(recursive: true);
    return File(path.join(directory.path, keyToMd5(request.cacheKey)));
  }

  Future<Uint8List?> _readCache() async {
    if (!request.allowDiskCache) return null;
    try {
      final file = await _cacheFile();
      return await file.exists() ? await file.readAsBytes() : null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _deleteCache() async {
    if (!request.allowDiskCache) return;
    try {
      final file = await _cacheFile();
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Cache maintenance must not prevent an image retry.
    }
  }

  Future<void> _writeCache(Uint8List bytes) async {
    Directory? staging;
    try {
      final file = await _cacheFile();
      staging = await file.parent.createTemp('.image-');
      final temporary = File(path.join(staging.path, 'data'));
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } on FileSystemException {
      // A cache write failure must not discard a successfully decoded image.
    } finally {
      if (staging != null) {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException {
          /* Best effort. */
        }
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RustExtendedNetworkImageProvider &&
      other.request.cacheKey == request.cacheKey &&
      other.scale == scale &&
      other.decodeWidth == decodeWidth &&
      other.reloadRevision == reloadRevision;

  @override
  int get hashCode =>
      Object.hash(request.cacheKey, scale, decodeWidth, reloadRevision);
}

final class MediaImageException implements Exception {
  const MediaImageException({
    required this.request,
    required this.stage,
    required this.cause,
    this.byteCount,
    this.fromCache = false,
  });
  final MediaRequestDto request;
  final String stage;
  final Object cause;
  final int? byteCount;
  final bool fromCache;

  @override
  String toString() {
    final uri = Uri.tryParse(request.url);
    // Authentication headers and signed query parameters are never diagnostics.
    final location = uri == null
        ? '(invalid URL)'
        : '${uri.scheme}://${uri.host}${uri.path}';
    return 'source=${request.sourceId} · post=${request.postId} · variant=${request.variant.name}\n'
        'stage=$stage · cache=$fromCache${byteCount == null ? "" : " · bytes=$byteCount"}\n'
        '$location\n${describeBooruError(cause).replaceAll(request.url, location)}';
  }
}

/// Replays the validated first frame without losing animation timing/frames.
final class _ValidatedCodec implements ui.Codec {
  _ValidatedCodec(this.delegate, this.firstFrame, this.onError);
  final ui.Codec delegate;
  ui.FrameInfo? firstFrame;
  final Future<Object> Function(Object) onError;
  @override
  int get frameCount => delegate.frameCount;
  @override
  int get repetitionCount => delegate.repetitionCount;
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
