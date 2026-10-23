import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

/// Owns transport bytes and incremental JPEG parsing off the UI isolate.
/// Only one snapshot may be outstanding; acknowledgement pulls the newest scan.
final class JpegScanBuffer {
  JpegScanBuffer._(this.onPreview);
  final void Function(Uint8List bytes, int scanEnd) onPreview;
  final _events = ReceivePort();
  final _ready = Completer<SendPort>();
  final _result = Completer<Uint8List>();
  Isolate? _isolate;
  late final SendPort _commands;
  bool _closed = false;

  static Future<JpegScanBuffer> start({
    required void Function(Uint8List bytes, int scanEnd) onPreview,
  }) async {
    final buffer = JpegScanBuffer._(onPreview);
    // A worker failure may arrive before finish() is awaited. Keep the error
    // owned here; callers still receive it from finish().
    buffer._result.future.ignore();
    buffer._ready.future.ignore();
    buffer._events.listen(buffer._receive);
    try {
      buffer._isolate = await Isolate.spawn(
        _accumulate,
        buffer._events.sendPort,
        onError: buffer._events.sendPort,
        onExit: buffer._events.sendPort,
        errorsAreFatal: true,
        debugName: 'JPEG scan accumulator',
      );
      buffer._commands = await buffer._ready.future;
      return buffer;
    } catch (_) {
      buffer.cancel();
      rethrow;
    }
  }

  void add(Uint8List bytes) {
    if (_closed) throw const ImageLoadCancelled();
    _commands.send(_Append(TransferableTypedData.fromList([bytes])));
  }

  void nextPreview() {
    if (!_closed) _commands.send(const _Next());
  }

  Future<Uint8List> finish() async {
    if (_closed) throw const ImageLoadCancelled();
    _commands.send(const _Finish());
    return _result.future;
  }

  void cancel() {
    if (_closed) return;
    _closed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _events.close();
    if (!_result.isCompleted) {
      _result.completeError(const ImageLoadCancelled());
    }
  }

  void _receive(Object? message) {
    switch (message) {
      case SendPort():
        _ready.complete(message);
      case _Preview(:final bytes, :final scanEnd):
        onPreview(bytes.materialize().asUint8List(), scanEnd);
      case _Complete(:final bytes):
        _result.complete(bytes.materialize().asUint8List());
        _closed = true;
        _isolate = null;
        _events.close();
      case _:
        // Isolate error messages and an unexpected early exit share one owned
        // failure path. Neither can leave an image load waiting indefinitely.
        final error = StateError('JPEG accumulator exited: $message');
        if (!_ready.isCompleted) _ready.completeError(error);
        if (!_result.isCompleted) _result.completeError(error);
        cancel();
    }
  }
}

final class ImageLoadCancelled implements Exception {
  const ImageLoadCancelled();
}

sealed class _Command {
  const _Command();
}

final class _Append extends _Command {
  const _Append(this.bytes);
  final TransferableTypedData bytes;
}

final class _Next extends _Command {
  const _Next();
}

final class _Finish extends _Command {
  const _Finish();
}

final class _Preview {
  const _Preview(this.bytes, this.scanEnd);
  final TransferableTypedData bytes;
  final int scanEnd;
}

final class _Complete {
  const _Complete(this.bytes);
  final TransferableTypedData bytes;
}

void _accumulate(SendPort output) {
  final commands = ReceivePort();
  final chunks = <Uint8List>[];
  final parser = JpegScanParser();
  var sentEnd = 0, inFlight = false;
  void sendLatest() {
    final end = parser.completedScanEnd;
    if (inFlight || end <= sentEnd || parser.finished) return;
    // The only prefix assembly happens here. TransferableTypedData transfers
    // ownership back to the UI isolate without copying the encoded prefix there.
    var remaining = end;
    final prefix = <TypedData>[];
    for (final chunk in chunks) {
      if (remaining == 0) break;
      final count = remaining < chunk.length ? remaining : chunk.length;
      prefix.add(Uint8List.sublistView(chunk, 0, count));
      remaining -= count;
    }
    prefix.add(Uint8List.fromList(const [255, 217]));
    output.send(_Preview(TransferableTypedData.fromList(prefix), end));
    sentEnd = end;
    inFlight = true;
  }

  commands.listen((Object? command) {
    switch (command) {
      case _Append(:final bytes):
        final chunk = bytes.materialize().asUint8List();
        chunks.add(chunk);
        parser.add(chunk);
        sendLatest();
      case _Next():
        inFlight = false;
        sendLatest();
      case _Finish():
        output.send(_Complete(TransferableTypedData.fromList(chunks)));
        chunks.clear();
        commands.close();
    }
  });
  output.send(commands.sendPort);
}

enum _JpegState {
  soi,
  soiEnd,
  markerStart,
  marker,
  lengthHigh,
  lengthLow,
  skip,
  entropy,
  entropyMarker,
  stopped,
}

/// A streaming marker parser: each incoming byte is inspected at most once.
/// Baseline JPEG and other formats never produce an intermediate scan.
final class JpegScanParser {
  var _state = _JpegState.soi;
  int _offset = 0, _marker = 0, _length = 0, _remaining = 0, _markerOffset = 0;
  bool progressive = false, finished = false;
  int completedScanEnd = 0, completedScans = 0;
  int get inspectedBytes => _offset;

  void add(Uint8List bytes) {
    for (final byte in bytes) {
      final position = _offset++;
      switch (_state) {
        case _JpegState.soi:
          _state = byte == 255 ? _JpegState.soiEnd : _JpegState.stopped;
        case _JpegState.soiEnd:
          _state = byte == 216 ? _JpegState.markerStart : _JpegState.stopped;
        case _JpegState.markerStart:
          _state = byte == 255 ? _JpegState.marker : _JpegState.stopped;
        case _JpegState.marker:
          if (byte != 255) _beginMarker(byte);
        case _JpegState.lengthHigh:
          _length = byte << 8;
          _state = _JpegState.lengthLow;
        case _JpegState.lengthLow:
          _remaining = (_length | byte) - 2;
          if (_remaining < 0) {
            _state = _JpegState.stopped;
          } else if (_remaining == 0) {
            _endSegment();
          } else {
            _state = _JpegState.skip;
          }
        case _JpegState.skip:
          if (--_remaining == 0) _endSegment();
        case _JpegState.entropy:
          if (byte == 255) {
            _markerOffset = position;
            _state = _JpegState.entropyMarker;
          }
        case _JpegState.entropyMarker:
          if (byte == 0 || byte >= 208 && byte <= 215) {
            _state = _JpegState.entropy;
          } else if (byte != 255) {
            completedScanEnd = _markerOffset;
            completedScans++;
            _beginMarker(byte);
          }
        case _JpegState.stopped:
          return;
      }
    }
  }

  void _beginMarker(int marker) {
    _marker = marker;
    if (marker == 217) {
      finished = true;
      _state = _JpegState.stopped;
    } else if (marker == 0 || marker == 216) {
      _state = _JpegState.stopped;
    } else if (marker >= 192 &&
        marker <= 207 &&
        marker != 196 &&
        marker != 200 &&
        marker != 204) {
      // Only SOF2 has the progressive scan contract used by Flutter previews.
      progressive = marker == 194;
      _state = progressive ? _JpegState.lengthHigh : _JpegState.stopped;
    } else {
      _state = _JpegState.lengthHigh;
    }
  }

  void _endSegment() {
    _state = _marker == 218
        ? (progressive ? _JpegState.entropy : _JpegState.stopped)
        : _JpegState.markerStart;
  }
}
