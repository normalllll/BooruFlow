import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/browse_v2_test.dart' show browsePost;
import '../discovery/home_page_test.dart' show browseTestApp;

void main() {
  for (final width in [390.0, 1000.0]) {
    testWidgets(
      'copy shows loading and a cancellable slow-operation modal at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final image = await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          ui.Canvas(
            recorder,
          ).drawColor(const ui.Color(0xff00ff00), ui.BlendMode.src);
          final picture = recorder.endRecording();
          try {
            return await picture.toImage(16, 8);
          } finally {
            picture.dispose();
          }
        });
        final frame = DisplayedMediaFrame();
        final pending = Completer<Uint8List?>();
        frame.show(
          'yande:1',
          Object(),
          image!,
          frame.begin(),
          cachedPng: () => pending.future,
        );
        addTearDown(frame.dispose);
        addTearDown(image.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageClipboardProvider.overrideWithValue(
                ImageClipboard(
                  writePng: (_) async =>
                      fail('A cancelled copy must not write to the clipboard.'),
                ),
              ),
            ],
            child: browseTestApp(
              Center(
                child: PostDetailActions(
                  post: Post(browsePost(1)),
                  displayedFrame: frame,
                  onOpen: () {},
                ),
              ),
            ),
          ),
        );
        final copy = find
            .byWidgetPredicate(
              (w) => w is FrostButton && w.label == t.discovery.copyImage,
            )
            .hitTestable();
        await tester.tap(copy);
        await tester.pump();
        await tester.pump();
        expect(frame.copying, true);
        expect(tester.widget<FrostButton>(copy).loading, true);
        await tester.pump(const Duration(milliseconds: 301));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(FrostDialog), findsOneWidget);
        final cancel = find.text(t.frost.cancel).hitTestable();
        await tester.tap(cancel);
        await tester.pump();
        expect(frame.copying, false);
        pending.complete(Uint8List.fromList([1, 2, 3]));
        await tester.pumpAndSettle();
        expect(find.byType(FrostDialog), findsNothing);
        expect(tester.widget<FrostButton>(copy).loading, false);
        // A late result must not reach the injected clipboard writer.
        expect(tester.takeException(), isNull);
      },
    );
  }
}
