import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:booruflow/features/downloads/downloads_page.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../../tool/automation/preview/downloads.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import 'support.dart';

void main() {
  for (final width in [1024.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '3x208 batch ink and action caps survive reveal with Inspector $width/$brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                downloadItemsProvider.overrideWith(
                  () => TestDownloadItems(largeDownloadPreviewItems()),
                ),
                downloadManagerProvider.overrideWithValue(
                  TestDownloadManager(),
                ),
              ],
              child: browseTestApp(
                RepaintBoundary(key: boundary, child: const DownloadsPage()),
                brightness: brightness,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final tile = find.byWidgetPredicate(
            (w) => w is DownloadTaskTile && w.task.snapshot.id == 'large-0-0',
          );
          await tester.tap(tile);
          await tester.pumpAndSettle();
          expect(tester.widget<DownloadTaskTile>(tile).selected, isTrue);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(tile));
          await tester.pumpAndSettle();
          final tokens = FrostThemeTokens.of(tester.element(tile));
          final selection = find.descendant(
            of: tile,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is AnimatedContainer &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration! as ShapeDecoration).color ==
                      tokens.selectionFill,
            ),
          );
          Future<({ByteData data, int width, Offset origin})> image() async {
            return (await tester.runAsync(() async {
              final shot = await tester
                  .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
                  .toImage();
              final data = (await shot.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              final result = (
                data: data,
                width: shot.width,
                origin: tester.getTopLeft(find.byKey(boundary)),
              );
              shot.dispose();
              return result;
            }))!;
          }

          int pixel(
            ({ByteData data, int width, Offset origin}) shot,
            Offset point,
          ) {
            final local = point - shot.origin;
            return shot.data.getUint32(
              (local.dy.floor() * shot.width + local.dx.floor()) * 4,
            );
          }

          Future<void> caps(String phase) async {
            final rect = tester.getRect(selection);
            final shot = await image();
            final left = pixel(shot, Offset(rect.left + 2, rect.center.dy));
            final right = pixel(shot, Offset(rect.right - 2, rect.center.dy));
            expect(
              right,
              left,
              reason:
                  '$phase: both granted horizontal caps must paint the same selected fill.',
            );
            expect(
              pixel(shot, rect.topLeft + const Offset(1, 1)),
              isNot(left),
              reason: '$phase left cap is round',
            );
            expect(
              pixel(shot, rect.topRight + const Offset(-2, 1)),
              isNot(right),
              reason: '$phase right cap is round',
            );
          }

          await caps('settled');
          final more = find.descendant(
            of: tile,
            matching: find.byWidgetPredicate(
              (w) => w is FrostTooltip && w.message == t.frost.more,
            ),
          );
          final control = find.descendant(
            of: more,
            matching: find.byType(FrostClickSurface),
          );
          final rect = tester.getRect(control.first);
          await mouse.moveTo(tester.getCenter(control.first));
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 200));
          final after = await image();
          for (final point in [
            Offset(rect.left + 2, rect.center.dy),
            Offset(rect.right - 2, rect.center.dy),
            Offset(rect.center.dx, rect.top + 2),
            Offset(rect.center.dx, rect.bottom - 2),
          ]) {
            expect(
              pixel(after, point),
              isNot(pixel(after, Offset(rect.left - 4, rect.center.dy))),
              reason:
                  'full More hover edge $point differs from the adjacent selected fill in the same frame',
            );
          }
          await tester.tap(find.text('muryo 1'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          await caps('closing intermediate');
          expect(find.byType(DownloadTaskTile).evaluate().length, lessThan(35));
          await tester.pumpAndSettle();
          await tester.tap(find.text('muryo 1'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 70));
          await caps('opening intermediate');
          await tester.pumpAndSettle();
          await caps('reopened');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
