import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/search/post_search_page.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'search_interaction_test.dart'
    show searchTestApp, SearchRepositoryFake, testSource;

void main() {
  test(
    'raw query preserves operators, quotes, braces and UTF-16 editing ranges',
    () {
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
      const query = '空😀 -sky source:"two words" ';
      final spans = querySpans(query);
      expect(spans.map((s) => query.substring(s.start, s.end)), [
        '空😀',
        '-sky',
        'source:"two words"',
      ]);
      expect(querySpanAt(query, 6)?.raw, '-sky');
      expect(querySpanAt(query, query.length), isNull);
    },
  );
  for (final width in [320.0, 360.0, 600.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'full token query stays in the bounded header at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          BooruService.instance.useSourcesForTesting([testSource('first')]);
          final tags = List.generate(30, (i) => 'とても長いキャラクター名_超长角色名称_$i');
          await tester.pumpWidget(
            searchTestApp(
              PostSearchPage(
                sourceId: 'first',
                initialTags: tags,
                repository: SearchRepositoryFake(),
                onSubmit: (_, _) {},
              ),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          final field = tester.widget<FrostTokenField>(
            find.byType(FrostTokenField),
          );
          expect(field.controller!.text.trim(), tags.join(' '));
          expect(
            tester.getSize(find.byType(FrostTokenField)).width,
            greaterThan(0),
          );
          // Full source labels retain their natural width. The existing
          // horizontal safety net keeps editors accessible at extreme width/scale.
          await tester.ensureVisible(find.byType(FrostTokenField));
          await tester.pump();
          expect(
            tester.getRect(find.byType(FrostTokenField)).right,
            lessThanOrEqualTo(width),
          );
          expect(
            tester
                .getRect(find.byType(FrostPageHeader))
                .contains(tester.getCenter(find.byType(FrostTokenField))),
            isTrue,
          );
          expect(find.byType(InputChip), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
