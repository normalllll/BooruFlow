import 'package:booruflow/app/frost_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'search keeps magnifier and submits with a mirrored forward arrow $direction',
      (tester) async {
        final controller = TextEditingController(text: 'sky'),
            focus = FocusNode();
        String? submitted;
        await tester.pumpWidget(
          browseTestApp(
            Directionality(
              textDirection: direction,
              child: Center(
                child: SizedBox(
                  width: 500,
                  child: FrostSearchInput(
                    controller: controller,
                    focusNode: focus,
                    leadingIcon: true,
                    placeholder: 'Search',
                    onSubmitted: (value) => submitted = value,
                  ),
                ),
              ),
            ),
          ),
        );
        final icons = tester.widgetList<FrostIcon>(find.byType(FrostIcon));
        expect(icons.any((icon) => icon.icon == appIcons.search), true);
        final submit = find.byWidgetPredicate(
          (w) => w is FrostButton && w.icon == appIcons.forward,
        );
        expect(submit, findsOneWidget);
        expect(
          tester.widget<FrostButton>(submit).label,
          FrostScope.labelsOf(tester.element(submit)).search,
        );
        await tester.tap(submit);
        await tester.pump();
        expect(submitted, 'sky');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        focus.dispose();
      },
    );
  }
}
