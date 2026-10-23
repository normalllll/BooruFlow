// Fixed colorful image for background-window glass verification, not an App asset.
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

Future<ImageProvider> previewBackdrop() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const bounds = Rect.fromLTWH(0, 0, 1200, 900);
  canvas.drawRect(
    bounds,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        bounds.bottomRight,
        const [
          Color(0xff142c61),
          Color(0xff914da5),
          Color(0xfff99a58),
          Color(0xfff8e8ab),
        ],
        const [0, .35, .7, 1],
      ),
  );
  for (final (rect, color) in const [
    (Rect.fromLTWH(-120, 100, 650, 650), Color(0xff1eb8b1)),
    (Rect.fromLTWH(750, -100, 450, 500), Color(0xfff2cb53)),
    (Rect.fromLTWH(360, 400, 750, 600), Color(0xff8d318c)),
    (Rect.fromLTWH(720, 500, 500, 500), Color(0xff121936)),
  ]) {
    canvas.drawOval(rect, Paint()..color = color);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(1200, 900);
  try {
    return MemoryImage(
      (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List(),
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}
