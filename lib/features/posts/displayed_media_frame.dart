import 'dart:ui' as ui;

import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:flutter/foundation.dart';

/// UI-owned first decoded frame of the image actually shown by PostMedia.
/// Keeps one cloned image handle, never a request or a second image stream.
class DisplayedMediaFrame extends ChangeNotifier {
  ui.Image? _image;
  String? _identity;
  Object? _source;
  int _generation = 0, _copyEpoch = 0;
  bool _copying = false;
  bool get copying => _copying;
  Future<Uint8List?> Function()? _cachedPng;
  bool _disposed = false;
  bool readyFor(String identity) =>
      !_disposed && _identity == identity && _image != null;

  /// A new presented occurrence invalidates callbacks from an outgoing widget.
  int begin() {
    _generation++;
    // The new owner is mounting/updating and derives readiness by identity.
    // Lifecycle invalidation is silent; actual frame and failure events notify.
    _clear();
    return _generation;
  }

  void show(
    String identity,
    Object source,
    ui.Image image,
    int generation, {
    Future<Uint8List?> Function()? cachedPng,
  }) {
    if (_disposed ||
        generation != _generation ||
        (_identity == identity && identical(source, _source))) {
      return;
    }
    _image?.dispose();
    _image = image.clone();
    _identity = identity;
    _source = source;
    _cachedPng = cachedPng;
    _notify();
  }

  void _clear() {
    _image?.dispose();
    _image = null;
    _identity = null;
    _source = null;
    _cachedPng = null;
  }

  void invalidate(int generation) {
    if (_disposed || generation != _generation || _image == null) return;
    _clear();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Cancels before the clipboard commit. Native I/O/encoding already in
  /// flight may finish, but its result is discarded and cannot write later.
  void cancelCopy() {
    if (!_copying) return;
    _copyEpoch++;
    _copying = false;
    _notify();
  }

  /// Prefer complete original PNG bytes; otherwise encode the captured display
  /// frame asynchronously in the engine. A source disposal cannot invalidate
  /// the cloned image handle while the operation is in flight.
  Future<bool> copy(
    String identity, {
    Future<void> Function(Uint8List)? write,
  }) async {
    if (!readyFor(identity)) {
      throw StateError('The displayed image is not decoded.');
    }
    if (_copying) return false;
    final epoch = ++_copyEpoch;
    final image = _image!.clone();
    final cachedPng = _cachedPng;
    _copying = true;
    _notify();
    try {
      Uint8List? png;
      try {
        png = await cachedPng?.call();
      } catch (_) {
        /* Optional encoded cache cannot prevent a display-frame copy. */
      }
      if (epoch != _copyEpoch) return false;
      if (png == null) {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw StateError('The displayed frame has no PNG representation.');
        }
        png = bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      }
      if (epoch != _copyEpoch) return false;
      await (write ?? ImageClipboard.system.write)(png);
      return true;
    } finally {
      image.dispose();
      if (epoch == _copyEpoch) {
        _copying = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _image?.dispose();
    _image = null;
    super.dispose();
  }
}
