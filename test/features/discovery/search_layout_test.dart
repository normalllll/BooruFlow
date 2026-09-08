import 'package:booruflow/features/search/post_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('raw query parsing preserves operators and rejects whitespace', () {
    expect(parseQueryInput('  '), isEmpty);
    expect(parseQueryInput('sky -cloud rating:s'), [
      'sky',
      '-cloud',
      'rating:s',
    ]);
    expect(
      parseQueryInput(
        '~sky -cloud source:"two words" { blue_hair ~green_hair }',
      ),
      ['~sky', '-cloud', 'source:"two words"', '{ blue_hair ~green_hair }'],
    );
  });
  for (final width in [320.0, 360.0, 600.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('selected tags remain bounded at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectedTags(
                    tags: List.generate(30, (i) => 'とても長いキャラクター名_超长角色名称_$i'),
                    displayName: (tag) => tag,
                    onRemove: (_) {},
                    onMore: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(ActionChip), findsOneWidget);
        final chips = tester.widgetList<InputChip>(find.byType(InputChip));
        expect(chips.length, lessThan(30));
        final rows = <int>{
          for (final element in find.byType(InputChip).evaluate())
            tester.getTopLeft(find.byWidget(element.widget)).dy.round(),
          tester.getTopLeft(find.byType(ActionChip)).dy.round(),
        };
        expect(rows.length, lessThanOrEqualTo(2));
        final topPositions = tester.getTopLeft(find.byType(SelectedTags)).dy;
        final bottom = tester.getBottomLeft(find.byType(SelectedTags)).dy;
        expect(bottom - topPositions, lessThan(160 * scale));
      });
    }
  }
}
