import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../features/discovery/home_page_test.dart' show browseTestApp;

void main() {
  for (final width in [320.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'long source labels wrap fully within the value panel at $width/$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String selected = 'short';
          await tester.pumpWidget(
            browseTestApp(
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 160,
                  child: FrostPicker<String>.menu(
                    value: 'short',
                    label: 'Source',
                    options: const [
                      FrostPickerOption(value: 'short', label: 'yande.re'),
                      FrostPickerOption(value: 'long', label: 'Anime-Pictures'),
                    ],
                    onChanged: (value) => selected = value,
                  ),
                ),
              ),
              scale: scale,
            ),
          );
          await tester.tap(find.text('yande.re'));
          await tester.pumpAndSettle();
          final label = find.text('Anime-Pictures');
          final paragraph = tester.renderObject<RenderParagraph>(label);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.getRect(label).left, greaterThanOrEqualTo(0));
          expect(tester.getRect(label).right, lessThanOrEqualTo(width));
          expect(
            find.byWidgetPredicate(
              (w) => w is FrostSurface && w.role == FrostSurfaceRole.sheet,
            ),
            width < 600 ? findsOneWidget : findsNothing,
          );
          await tester.tap(label);
          await tester.pumpAndSettle();
          expect(selected, 'long');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'compact picker keeps fitted sheet bounded and later lazy options reachable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int selected = 0;
      await tester.pumpWidget(
        browseTestApp(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              child: FrostPicker<int>.menu(
                value: 0,
                label: 'Option',
                options: List.generate(
                  30,
                  (i) => FrostPickerOption(value: i, label: 'Option $i'),
                ),
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Option 0'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(
              find.byWidgetPredicate(
                (w) => w is FrostSurface && w.role == FrostSurfaceRole.sheet,
              ),
            )
            .bottom,
        lessThanOrEqualTo(800),
      );
      final list = find
          .descendant(
            of: find.byWidgetPredicate(
              (w) => w is FrostSurface && w.role == FrostSurfaceRole.sheet,
            ),
            matching: find.byType(Scrollable),
          )
          .last;
      await tester.scrollUntilVisible(
        find.text('Option 29'),
        240,
        scrollable: list,
      );
      await tester.tap(find.text('Option 29'));
      await tester.pumpAndSettle();
      expect(selected, 29);
      expect(
        find.byWidgetPredicate(
          (w) => w is FrostSurface && w.role == FrostSurfaceRole.sheet,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
