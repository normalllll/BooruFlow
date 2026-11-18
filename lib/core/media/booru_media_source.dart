import 'dart:async';
import 'dart:typed_data';

import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

/// Makes the handle that stops one download; replaced in tests that run
/// without the native library.
@visibleForTesting
MediaCancel Function() createMediaCancel = MediaCancel.new;

/// Opens the stream of a prepared request on the engine that prepared it.
typedef BooruMediaStream = Stream<MediaFetchEvent> Function(
  MediaRequest request,
  MediaCancel cancel,
);

/// A picture fetched through the Rust engine, which owns its headers, proxy
/// and sign-in. The request's cache key already includes the address, account
/// and route revisions.
final class BooruMediaSource extends MediaSource {
  const BooruMediaSource(this.request, this.stream);

  final MediaRequest request;
  final BooruMediaStream stream;

  @override
  String get cacheKey => request.cacheKey;

  @override
  bool get cacheOnDisk => request.allowDiskCache;

  @override
  Stream<MediaChunk> open() {
    final cancel = createMediaCancel();
    return stopOnCancel(
      stream(request, cancel),
      stop: cancel.cancel,
      release: cancel.dispose,
    ).map(_chunkOf);
  }

  MediaChunk _chunkOf(MediaFetchEvent event) => switch (event) {
    MediaFetchEvent_Chunk(
      :final bytes,
      :final receivedBytesDecimal,
      :final totalBytesDecimal,
    ) =>
      MediaChunk(
        bytes: bytes,
        received: int.tryParse(receivedBytesDecimal) ?? bytes.length,
        total: int.tryParse(totalBytesDecimal ?? ''),
      ),
    MediaFetchEvent_Failed(:final error) => throw makeBooruErrorReadable(error),
  };

  /// Only transport failures are worth another try; the engine's other errors
  /// (a sign-in, a rejected request, an invalid file) repeat.
  @override
  bool shouldRetry(Object error) => switch (booruErrorOf(error)) {
    BooruError(:final code) => const {
      BooruErrorCode.network,
      BooruErrorCode.timeout,
      BooruErrorCode.sourceUnavailable,
    }.contains(code),
    _ => true,
  };

  @override
  String get description =>
      '${request.sourceId}/${request.postId}/${request.variant.name}';

  /// Diagnostics never carry the request's headers, credentials or signed
  /// query parameters.
  @override
  String describe(Object cause) {
    final location = mediaLocation(request);
    return '$location\n'
        '${describeBooruError(cause).replaceAll(request.url, location)}';
  }
}

/// The address of [request] without its query or credentials.
String mediaLocation(MediaRequest request) {
  final uri = Uri.tryParse(request.url);
  return uri == null
      ? '(invalid URL)'
      : '${uri.scheme}://${uri.host}${uri.path}';
}

/// [source] as a stream that calls [stop] when a listener cancels it before it
/// ends, and [release] once it has ended or been stopped.
@visibleForTesting
Stream<T> stopOnCancel<T>(
  Stream<T> source, {
  required void Function() stop,
  required void Function() release,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  var over = false;
  void end() {
    if (over) return;
    over = true;
    release();
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        controller.add,
        // The engine reports an error only as the download ends.
        onError: (Object error, StackTrace stack) {
          end();
          controller.addError(error, stack);
        },
        onDone: () {
          end();
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      if (!over) stop();
      end();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}

/// The engine error [error] carries, readable or not.
BooruError? booruErrorOf(Object? error) => switch (error) {
  BooruReadableException(:final cause) => cause,
  BooruError value => value,
  _ => null,
};

/// The request behind a picture loaded through [BooruMediaSource].
extension BooruMediaImage on CachedMediaImage {
  BooruMediaStream? get stream => switch (source) {
    BooruMediaSource(:final stream) => stream,
    _ => null,
  };

  MediaRequest? get request => switch (source) {
    BooruMediaSource(:final request) => request,
    _ => null,
  };

  /// The width, in pixels, the picture is decoded at; null for its own size.
  int? get decodeWidth => decodeBox?.width.round();

  /// Forgets the picture in memory and on disk, so the next load fetches it
  /// again.
  Future<void> clearCache() async {
    await evict();
    if (source.cacheOnDisk) await store?.remove(source.cacheKey);
  }

  /// The encoded PNG of an original that is complete on disk, for the
  /// clipboard.
  Future<Uint8List?> cachedOriginalPng() async {
    final request = this.request;
    final proven = store;
    if (request == null ||
        request.variant != MediaVariantKind.original ||
        proven is! ProvenMediaStore) {
      return null;
    }
    return EncodedMediaCache(store: proven.disk).readPng(request);
  }
}

/// Keep decode and transport failures distinct without interpreting
/// translated text.
Object mediaImageCause(Object error) {
  final cause = error is MediaImageException ? error.cause : error;
  return cause is BooruReadableException ? cause.cause : cause;
}

bool isMediaImageDecodeFailure(Object error) {
  final cause = mediaImageCause(error);
  return error is MediaImageException &&
          error.stage == MediaImageStage.decode ||
      cause is BooruError &&
          cause.userMessageKey == 'booru.error.imageDecodeFailed';
}

/// A picture of [request], decoded at most [decodeWidth] pixels wide, kept on
/// disk with its proof. An original's decoded pixels live only while it is
/// shown unless [retainDecoded] says otherwise.
CachedMediaImage booruMediaImage({
  required MediaRequest request,
  required BooruMediaStream stream,
  int? decodeWidth,
  int reloadRevision = 0,
  bool firstFrameOnly = false,
  bool progressive = false,
  bool? retainDecoded,
  double scale = 1,
}) {
  assert(decodeWidth == null || decodeWidth > 0);
  return CachedMediaImage(
    BooruMediaSource(request, stream),
    store: const EncodedMediaCache().imageStore,
    scale: scale,
    decodeBox: decodeWidth == null
        ? null
        : Size(decodeWidth.toDouble(), double.infinity),
    reloadRevision: reloadRevision,
    firstFrameOnly: firstFrameOnly,
    progressive: progressive,
    retainDecoded:
        retainDecoded ?? request.variant != MediaVariantKind.original,
  );
}
