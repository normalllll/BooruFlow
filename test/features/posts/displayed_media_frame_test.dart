import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'asynchronous copy retains the displayed frame through replacement and disposal',
    (tester) async {
      await tester.runAsync(() async {
        Future<ui.Image> picture(ui.Color color) async {
          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
          final drawing = recorder.endRecording();
          try {
            return await drawing.toImage(16, 8);
          } finally {
            drawing.dispose();
          }
        }

        final green = await picture(const ui.Color(0xff00ff00));
        final red = await picture(const ui.Color(0xffff0000));
        final shown = DisplayedMediaFrame();
        final generation = shown.begin();
        shown.show('post', Object(), green, generation);
        final copying = shown.copy(
          'post',
          write: (bytes) async {
            final codec = await ui.instantiateImageCodec(bytes);
            final image = (await codec.getNextFrame()).image;
            try {
              final pixels = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              expect(pixels.buffer.asUint8List().take(4), [0, 255, 0, 255]);
              expect((image.width, image.height), (16, 8));
            } finally {
              image.dispose();
              codec.dispose();
            }
          },
        );
        shown.show('post', Object(), red, generation);
        shown.dispose();
        green.dispose();
        red.dispose();
        await copying;
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'first shown frame stays frozen; identity, replacement and disposal invalidate copying',
    (tester) async {
      final frame = DisplayedMediaFrame();
      final source = Object();
      final generation = frame.begin();
      var notifications = 0;
      frame.addListener(() => notifications++);
      expect(frame.readyFor('a'), isFalse);
      await expectLater(frame.copy('a'), throwsStateError);
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(
          recorder,
        ).drawPaint(ui.Paint()..color = const ui.Color(0xff00ff00));
        final picture = recorder.endRecording();
        final image = await picture.toImage(16, 8);
        frame.show('a', source, image, generation);
        picture.dispose();
        final secondPicture = ui.PictureRecorder();
        ui.Canvas(
          secondPicture,
        ).drawPaint(ui.Paint()..color = const ui.Color(0xffff0000));
        final second = secondPicture.endRecording();
        final other = await second.toImage(32, 32);
        frame.show(
          'a',
          source,
          other,
          generation,
        ); // A later animation frame cannot replace the first.
        second.dispose();
        expect(frame.readyFor('a'), isTrue);
        expect(frame.readyFor('b'), isFalse);
        await frame.copy(
          'a',
          write: (bytes) async {
            final codec = await ui.instantiateImageCodec(bytes);
            final copied = (await codec.getNextFrame()).image;
            expect((copied.width, copied.height), (16, 8));
            final pixels = (await copied.toByteData())!;
            expect(pixels.getUint8(1), 255);
            copied.dispose();
            codec.dispose();
          },
        );
        final nextGeneration = frame.begin();
        frame.show('b', Object(), image, nextGeneration);
        frame.show('a', source, other, generation);
        frame.invalidate(generation);
        expect(frame.readyFor('b'), isTrue);
        expect(frame.readyFor('a'), isFalse);
        frame.show('a', source, image, nextGeneration);
        image.dispose();
        other.dispose();
      });
      await tester.pump();
      expect(
        notifications,
        5,
        reason:
            "frame/copy events notify directly; begin and stale generations are silent",
      );
      frame.begin();
      expect(frame.readyFor('a'), isFalse);
      await expectLater(frame.copy('a'), throwsStateError);
      frame.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'original encoded PNG avoids re-encoding and cancellation discards late data',
    (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(
          recorder,
        ).drawColor(const ui.Color(0xff00ff00), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(16, 8);
        picture.dispose();
        final frame = DisplayedMediaFrame();
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        final source = Object();
        frame.show(
          'a',
          source,
          image,
          frame.begin(),
          cachedPng: () async => bytes,
        );
        Uint8List? copied;
        expect(
          await frame.copy(
            'a',
            write: (value) async {
              copied = value;
            },
          ),
          true,
        );
        expect(
          copied,
          same(bytes),
          reason: 'the exact encoded input bypasses the engine encode',
        );
        final pending = Completer<Uint8List?>();
        frame.show(
          'a',
          Object(),
          image,
          frame.begin(),
          cachedPng: () => pending.future,
        );
        var writes = 0;
        final cancelled = frame.copy(
          'a',
          write: (_) async {
            writes++;
          },
        );
        expect(frame.copying, true);
        frame.cancelCopy();
        expect(frame.copying, false);
        pending.complete(bytes);
        expect(await cancelled, false);
        expect(writes, 0);
        frame.dispose();
        image.dispose();
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
