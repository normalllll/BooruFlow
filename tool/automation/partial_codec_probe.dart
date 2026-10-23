// R9 engine feasibility probe, shared by native Windows/Android test hosts.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Map<String, Object?>> partialCodecProbe(
  String directory, {
  bool terminateJpeg = false,
}) async {
  final result = <String, Object?>{'platform': Platform.operatingSystem};
  for (final name in [
    'r9-baseline.jpg',
    'r9-progressive.jpg',
    'r9-noninterlaced.png',
  ]) {
    final bytes = await File('$directory/$name').readAsBytes();
    final full = await _decode(bytes);
    final samples = <Map<String, Object?>>[];
    for (final fraction in [.02, .05, .1, .2, .35, .5, .65, .8, .95, 1.0]) {
      final length = (bytes.length * fraction).round();
      final watch = Stopwatch()..start();
      try {
        final partial = Uint8List.sublistView(bytes, 0, length);
        final pixels = await _decode(
          terminateJpeg && name.endsWith('.jpg') && fraction < 1
              ? (BytesBuilder(copy: false)
                      ..add(partial)
                      ..add([255, 217]))
                    .takeBytes()
              : partial,
        );
        var equal = 0, difference = 0;
        for (var i = 0; i < full.length; i++) {
          if (pixels[i] == full[i]) equal++;
          difference += (pixels[i] - full[i]).abs();
        }
        samples.add({
          'fraction': fraction,
          'bytes': length,
          'decoded': true,
          'decodeUs': watch.elapsedMicroseconds,
          'equalChannels': equal / full.length,
          'meanDifference': difference / full.length,
        });
      } catch (error) {
        samples.add({
          'fraction': fraction,
          'bytes': length,
          'decoded': false,
          'decodeUs': watch.elapsedMicroseconds,
          'error': '$error',
        });
      }
    }
    result[name] = {'bytes': bytes.length, 'samples': samples};
  }
  return result;
}

Future<Uint8List> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 256);
  try {
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      return data!.buffer.asUint8List();
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
