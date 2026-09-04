import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('long source labels fit on one menu line at $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 160,
                    child: AppSelect<String>(
                      value: 'short',
                      items: const [
                        AppSelectItem(value: 'short', label: 'yande.re'),
                        AppSelectItem(value: 'long', label: 'Anime-Pictures'),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('yande.re'));
        await tester.pumpAndSettle();
        final text = find
            .descendant(
              of: find.widgetWithText(MenuItemButton, 'Anime-Pictures'),
              matching: find.byType(RichText),
            )
            .first;
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.maxLines, 1);
        if (scale == 1 || width >= 600) {
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        final shortRow = find.widgetWithText(MenuItemButton, 'yande.re');
        final longRow = find.widgetWithText(MenuItemButton, 'Anime-Pictures');
        expect(tester.getSize(longRow).height, tester.getSize(shortRow).height);
        expect(tester.getRect(longRow).right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'compact selector keeps menu bounded and later options reachable',
    (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 180,
                child: AppSelect<int>(
                  value: 0,
                  items: List.generate(
                    30,
                    (i) => AppSelectItem(value: i, label: 'Option $i'),
                  ),
                  onChanged: (value) => selected = value,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppSelect<int>)).height, 36);
      await tester.tap(find.text('Option 0'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MenuAnchor>(find.byType(MenuAnchor)).clipBehavior,
        Clip.antiAlias,
      );
      final option = find.widgetWithText(MenuItemButton, 'Option 29');
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(selected, 29);
      expect(tester.takeException(), isNull);
    },
  );
}
