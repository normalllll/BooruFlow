import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'jpeg_scan_buffer.dart';

/// Previews own their load lifecycle. Once the validated final codec is ready,
/// Flutter's regular multi-frame completer owns animation timing and disposal.
final class ProgressiveImageStreamCompleter extends ImageStreamCompleter {
  ProgressiveImageStreamCompleter({
    required Future<ui.Codec> Function(ProgressiveImageLoading) load,
    required double scale,
    required Stream<ImageChunkEvent> chunkEvents,
    required String debugLabel,
    required void Function() evictIncomplete,
  }) {
    this.debugLabel = debugLabel;
    loading.onImage = (image) =>
        setImage(ImageInfo(image: image, scale: scale));
    _chunks = chunkEvents.listen(reportImageChunkEvent);
    addOnLastListenerRemovedCallback(() {
      if (!complete) {
        loading.cancel();
        evictIncomplete();
      }
    });
    unawaited(_run(load, scale));
  }

  final loading = ProgressiveImageLoading();
  MultiFrameImageStreamCompleter? _finalStream;
  ImageStreamListener? _finalListener;
  ImageStreamCompleterHandle? _finalHandle;
  late final StreamSubscription<ImageChunkEvent> _chunks;
  bool _disposed = false, _finalListening = false;
  bool get complete => loading.complete;

  Future<void> _run(
    Future<ui.Codec> Function(ProgressiveImageLoading) load,
    double scale,
  ) async {
    try {
      final codec = await load(loading);
      if (loading.cancelled || _disposed) {
        codec.dispose();
        return;
      }
      loading.complete = true;
      final stream = MultiFrameImageStreamCompleter(
        codec: SynchronousFuture(codec),
        scale: scale,
        debugLabel: debugLabel,
      );
      _finalStream = stream;
      _finalHandle = stream.keepAlive();
      final listener = ImageStreamListener(
        (image, _) => setImage(image),
        onError: (Object error, StackTrace? stack) => reportError(
          exception: error,
          stack: stack,
          context: ErrorDescription('decoding a complete image'),
        ),
      );
      _finalListener = listener;
      if (hasListeners) {
        _finalListening = true;
        stream.addListener(listener);
      }
    } catch (error, stack) {
      if (!loading.cancelled && !_disposed) {
        reportError(
          exception: error,
          stack: stack,
          context: ErrorDescription('loading an image'),
        );
      }
    } finally {
      await loading.endAttempt();
      await _chunks.cancel();
    }
  }

  @override
  void addListener(ImageStreamListener listener) {
    final resume = !hasListeners && _finalListener != null;
    super.addListener(listener);
    if (resume) {
      _finalListening = true;
      _finalStream!.addListener(_finalListener!);
    }
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    if (!_disposed && !hasListeners && _finalListening) {
      _finalListening = false;
      _finalStream!.removeListener(_finalListener!);
    }
  }

  @override
  void onDisposed() {
    _disposed = true;
    loading.cancel();
    final listener = _finalListener;
    if (listener != null && _finalListening) {
      _finalStream!.removeListener(listener);
    }
    _finalHandle?.dispose();
    super.onDisposed();
  }
}

class ProgressiveImageLoading {
  JpegScanBuffer? _buffer;
  Future<void>? _pending;
  bool _ended = false;
  bool cancelled = false, complete = false;
  final decodeMicros = <int>[];
  final decodedScanEnds = <int>[];
  void Function(ui.Image)? onImage;
  Future<void> Function()? cancelStream;

  void cancel() {
    if (cancelled || complete) return;
    cancelled = true;
    _buffer?.cancel();
    final cancel = cancelStream;
    if (cancel != null) {
      // Cancellation is owned, including asynchronous teardown failures. It
      // never leaves an unobserved FRB Future or a permanently pending codec.
      unawaited(
        cancel().catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'image transport cleanup',
            ),
          );
        }),
      );
    }
  }

  void checkActive() {
    if (cancelled) throw const ImageLoadCancelled();
  }

  Future<void> begin(int targetWidth) async {
    checkActive();
    _ended = false;
    final buffer = await JpegScanBuffer.start(
      onPreview: (bytes, scanEnd) {
        if (cancelled || _ended) return;
        assert(_pending == null);
        _pending = _decode(bytes, targetWidth, scanEnd).whenComplete(() {
          _pending = null;
          if (!_ended && !cancelled) _buffer?.nextPreview();
        });
      },
    );
    _buffer = buffer;
    if (cancelled) buffer.cancel();
    checkActive();
  }

  void add(Uint8List bytes) {
    checkActive();
    _buffer!.add(bytes);
  }

  Future<Uint8List> finish() async {
    _ended = true;
    final bytes = await _buffer!.finish();
    await _pending;
    checkActive();
    return bytes;
  }

  Future<void> endAttempt() async {
    _ended = true;
    _buffer?.cancel();
    await _pending;
    _buffer = null;
  }

  Future<void> _decode(Uint8List bytes, int targetWidth, int scanEnd) async {
    ui.Image? image;
    final decoding = Stopwatch()..start();
    try {
      // The worker has already found a complete progressive scan. The engine
      // asynchronously decodes at display size on its native worker threads;
      // no encoded-prefix copy or pixel work runs on the main Dart isolate.
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        allowUpscaling: false,
      );
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } catch (_) {
      // A preview does not validate a file. Final decode reports corruption.
      image?.dispose();
      return;
    }
    if (cancelled || _ended) {
      image.dispose();
      return;
    }
    decodeMicros.add(decoding.elapsedMicroseconds);
    decodedScanEnds.add(scanEnd);
    final callback = onImage;
    if (callback == null) {
      image.dispose();
    } else {
      callback(image);
    }
  }
}
