import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_artwork.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/home_page_test.dart' show browseTestApp;

void main() {
  testWidgets(
    'restored saved image uses local display-size decode and missing image uses icon',
    (tester) async {
      late Directory folder;
      late File file;
      await tester.runAsync(() async {
        folder = await Directory.systemTemp.createTemp('booruflow-artwork-');
        file = File('${folder.path}/image.png');
        final recorder = ui.PictureRecorder();
        ui.Canvas(
          recorder,
        ).drawColor(const Color(0xffeeeeee), ui.BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(128, 128);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await file.writeAsBytes(Uint8List.view(bytes.buffer));
        image.dispose();
        picture.dispose();
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await tester.runAsync(() => folder.delete(recursive: true));
      });
      BooruDownloadItem item(String path) => BooruDownloadItem(
        snapshot: DownloadTaskSnapshot(
          id: 'restored',
          resourceId: 1,
          variantIndex: 0,
          title: '#1',
          filename: 'image.png',
          status: DownloadStatus.downloaded,
          saveState: SaveState.saved,
          receivedBytes: 1,
          totalBytes: 1,
          progress: 1,
          localPath: path,
          error: null,
          log: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      Future<void> show(String path) async {
        await tester.pumpWidget(
          ProviderScope(
            child: browseTestApp(
              SizedBox(
                width: 48,
                height: 48,
                child: DownloadArtwork(task: item(path), decodeWidth: 24),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          // Complete the real local filesystem operation outside FakeAsync.
          for (var i = 0; i < 100; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 1));
            await tester.pump();
            if (find
                    .byType(FutureBuilder<ImageProvider?>)
                    .evaluate()
                    .isNotEmpty &&
                find.byType(FrostMediaFrame).evaluate().isNotEmpty) {
              return;
            }
          }
        });
        await tester.pump();
      }

      await show(file.path);
      final provider =
          tester.widget<FrostMediaFrame>(find.byType(FrostMediaFrame)).image!
              as ResizeImage;
      expect(provider.width, 24);
      expect(provider.imageProvider, isA<FileImage>());
      await tester.runAsync(() async {
        final decoded = Completer<void>();
        final stream = provider.resolve(ImageConfiguration.empty);
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (info, _) {
            info.dispose();
            decoded.complete();
          },
          onError: (Object error, StackTrace? stack) =>
              decoded.completeError(error, stack),
        );
        stream.addListener(listener);
        try {
          await decoded.future.timeout(const Duration(seconds: 5));
        } finally {
          stream.removeListener(listener);
        }
      });
      await show('${folder.path}/missing.png');
      expect(
        tester.widget<FrostMediaFrame>(find.byType(FrostMediaFrame)).image,
        isNull,
      );
      expect(find.byType(FrostIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
