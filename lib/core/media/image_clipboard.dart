import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_clipboard.g.dart';

/// Capability travels with the selected implementation, never with a UI
/// platform list. Pasteboard's IO backend has no Linux/Fuchsia PNG writer;
/// offering its no-op writeImage there would falsely report a successful copy.
class ImageClipboard {
  const ImageClipboard({this.writePng});
  final Future<void> Function(Uint8List)? writePng;
  bool get supportsImages => writePng != null;

  static ImageClipboard get system {
    if (kIsWeb) return ImageClipboard(writePng: Pasteboard.writeImage);
    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows) {
      return ImageClipboard(writePng: Pasteboard.writeImage);
    }
    return const ImageClipboard();
  }

  Future<void> write(Uint8List png) {
    final writer = writePng;
    return writer == null
        ? Future.error(
            UnsupportedError('No image clipboard writer is installed.'),
          )
        : writer(png);
  }
}

@Riverpod(keepAlive: true)
ImageClipboard imageClipboard(Ref ref) => ImageClipboard.system;
