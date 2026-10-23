import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'R7 public ugoira decodes in Flutter with exact RGBA pixels and delays',
    () async {
      final root = Directory('build/r7-ugoira');
      final codec = await ui.instantiateImageCodec(
        await File('${root.path}/image-webp.webp').readAsBytes(),
      );
      addTearDown(codec.dispose);
      expect(codec.frameCount, 10);
      for (var i = 0; i < 10; i++) {
        final frame = await codec.getNextFrame();
        expect(frame.duration, const Duration(milliseconds: 100));
        expect(frame.image.width, 2000);
        expect(frame.image.height, 2000);
        final source = await ui.instantiateImageCodec(
          await File(
            '${root.path}/frames/${i.toString().padLeft(6, '0')}.png',
          ).readAsBytes(),
        );
        final original = await source.getNextFrame();
        final actual = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        final expected = await original.image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        expect(
          actual!.buffer.asUint8List(),
          expected!.buffer.asUint8List(),
          reason: 'frame $i',
        );
        original.image.dispose();
        source.dispose();
        frame.image.dispose();
      }
    },
  );
}
