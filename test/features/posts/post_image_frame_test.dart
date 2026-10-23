import 'dart:async';
import 'dart:ui' as ui;
import 'package:booruflow/features/posts/widgets/post_image_frame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _UncachedImage extends ImageProvider<_UncachedImage> {
  _UncachedImage(this.image);
  final ui.Image image;
  var loads = 0;
  @override
  Future<_UncachedImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    _UncachedImage key,
    ImageErrorListener handleError,
  ) {
    loads++;
    stream.setCompleter(
      OneFrameImageStreamCompleter(
        Future.value(ImageInfo(image: image.clone())),
      ),
    );
  }
}

void main() {
  testWidgets(
    'a retained original renders synchronously without another resolve or LRU entry',
    (tester) async {
      final image = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(
          recorder,
        ).drawColor(const ui.Color(0xff2498cb), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final result = await picture.toImage(80, 40);
        picture.dispose();
        return result;
      }))!;
      final provider = _UncachedImage(image);
      final stream = provider.resolve(ImageConfiguration.empty);
      final ready = Completer<void>();
      final listener = ImageStreamListener((info, _) {
        info.dispose();
        if (!ready.isCompleted) ready.complete();
      });
      stream.addListener(listener);
      final handle = stream.completer!.keepAlive();
      await tester.pump();
      await ready.future;
      stream.removeListener(listener);
      expect(provider.loads, 1);
      for (var visit = 0; visit < 3; visit++) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: PostImageFrame(
              provider: provider,
              stream: stream,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => const Text('Loading'),
              errorBuilder: (_) => const Text('Failed'),
            ),
          ),
        );
        expect(find.text('Loading'), findsNothing);
        expect(find.text('Failed'), findsNothing);
        final pixels = tester
            .renderObject<RenderImage>(find.byType(RawImage))
            .image!;
        expect(pixels.isCloneOf(image), isTrue);
        expect(provider.loads, 1);
        expect(
          PaintingBinding.instance.imageCache.statusForKey(provider).tracked,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
      }
      handle.dispose();
      expect(() => stream.addListener(listener), throwsStateError);
      image.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
