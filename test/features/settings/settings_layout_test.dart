import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => values;
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  late _Store store;
  setUp(() async {
    store = _Store();
    await SettingsService.initialize(store: store);
    BooruService.instance.useSourcesForTesting([
      testSource('yande'),
      testSource('danbooru'),
      testSource('wallhaven'),
    ]);
  });

  testWidgets('default source is explicit and browsing does not overwrite it', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();
    expect(find.text(t.settings.source.defaultSource), findsOneWidget);
    await tester.tap(find.text('yande'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('danbooru'));
    await tester.pumpAndSettle();
    expect(SettingsService.defaultSourceId, 'danbooru');
    expect(BooruService.instance.selectedSource.value, 'yande');
    BooruService.instance.selectSource('wallhaven');
    expect(SettingsService.defaultSourceId, 'danbooru');
    await SettingsService.initialize(store: store);
    expect(SettingsService.defaultSourceId, 'danbooru');
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'source tabs separate global ratings from each source card at $width/$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const SettingsPage(section: SettingsSection.sources),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(Card), findsNWidgets(2));
          final global = find.text(t.settings.source.safetyRating);
          final globalPosition = tester.getTopLeft(global);
          final tabsPosition = tester.getTopLeft(find.byType(TabBar));
          final ratingOptions = find.byType(AppChoiceToggle);
          final firstRatingY = tester.getTopLeft(ratingOptions.first).dy;
          for (
            var index = 1;
            index < ratingOptions.evaluate().length;
            index++
          ) {
            expect(tester.getTopLeft(ratingOptions.at(index)).dy, firstRatingY);
          }
          expect(
            find.ancestor(of: global, matching: find.byType(Card)),
            findsOneWidget,
          );
          expect(find.text(t.settings.source.supportedRatings), findsOneWidget);
          await tester.tap(find.widgetWithText(AppChoiceToggle, 'E'));
          await tester.pumpAndSettle();
          final tab = find.widgetWithText(Tab, 'danbooru');
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('source-settings-danbooru')),
            findsOneWidget,
          );
          expect(tester.getTopLeft(global), globalPosition);
          expect(tester.getTopLeft(find.byType(TabBar)), tabsPosition);
          expect(
            tester
                .widget<Offstage>(
                  find.byKey(
                    const ValueKey('source-settings-yande'),
                    skipOffstage: false,
                  ),
                )
                .offstage,
            isTrue,
          );
          expect(SettingsService.ratings, [ContentRating.explicit]);
          expect(BooruService.instance.selectedSource.value, 'yande');
          expect(SettingsService.defaultSourceId, 'yande');
          expect(find.byType(Card), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('theme language and grid columns live together in general', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsPage(section: SettingsSection.general)),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.settings.theme), findsOneWidget);
    expect(find.text(t.settings.language), findsOneWidget);
    expect(find.text(t.settings.columnsPerRow), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
