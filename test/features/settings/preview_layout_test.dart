import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

class _Update extends UpdateCheck {
  @override
  UpdateCheckState build() => UpdateCheckState(
    result: UpdateInfo(
      version: '1.2.3',
      download: Uri.parse('https://example.invalid/update'),
    ),
  );
}

void main() {
  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await SettingsService.initialize(store: _Store());
  });
  Widget mount(Widget child, {double scale = 1}) => ProviderScope(
    overrides: [
      booruServiceProvider.overrideWithValue(
        BooruService()..useSourcesForTesting([testSource('danbooru')]),
      ),
      updateCheckProvider.overrideWith(_Update.new),
    ],
    child: browseTestApp(child, scale: scale),
  );

  testWidgets(
    'download settings show current numeric values beside shared steppers',
    (tester) async {
      await tester.pumpWidget(
        mount(const SettingsPage(section: SettingsSection.downloads)),
      );
      await tester.pumpAndSettle();
      final rows = tester
          .widgetList<FrostListRow>(find.byType(FrostListRow))
          .where((row) => row.trailing is FrostStepper)
          .toList();
      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(row.value, '${(row.trailing! as FrostStepper).value.toInt()}');
        expect(find.text(row.value!), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    },
  );
  test('DNS labels cover exactly the real protocol values', () {
    expect(RouteProvider.values.map((value) => value.displayName), [
      'UncensoredDNS',
      'doh.sb',
    ]);
  });
  testWidgets(
    'phone settings uses three grouped cards, current values and an update badge',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(mount(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.byType(FrostGroupedSection), findsNWidgets(3));
      expect(find.byType(FrostListRow), findsNWidgets(8));
      expect(find.byType(FrostCountBadge), findsOneWidget);
      final appearance = tester.widget<FrostListRow>(
        find.byWidgetPredicate(
          (w) => w is FrostListRow && w.title == t.settingsV2.appearance,
        ),
      );
      expect(appearance.value, t.settings.system);
      expect(find.text(t.settingsDetails.systemDnsShort), findsOneWidget);
      expect(find.byType(FrostPicker<ThemeMode>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'wide section title starts exactly 32 after the shared 236 pane and hairline',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(mount(const SettingsPage()));
      await tester.pumpAndSettle();
      final title = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is FrostText && w.role == FrostTextRole.title2,
        ),
        matching: find.text(t.settingsV2.appearance),
      );
      final pane = tester.getRect(find.byType(FrostSettingsSections));
      expect(
        tester.getTopLeft(title).dx,
        closeTo(pane.left + 236 + 1 + 32, .001),
      );
      expect(
        tester.getTopLeft(title).dy,
        closeTo(
          pane.top + tester.getSize(find.byType(FrostPageHeader)).height,
          .001,
        ),
      );
      expect(
        tester
            .widgetList<FrostSettingsSelectTile>(
              find.byWidgetPredicate((w) => w is FrostSettingsSelectTile),
            )
            .every((w) => w.icon == null),
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'phone tone previews remain on one row without text clipping at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          mount(
            const SettingsPage(section: SettingsSection.appearance),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        final previews = find
            .byType(FrostThumbnail)
            .evaluate()
            .map(
              (element) => tester.getRect(
                find.byElementPredicate((e) => identical(element, e)),
              ),
            )
            .toList();
        expect(previews, hasLength(3));
        expect(previews.map((r) => r.top).toSet(), hasLength(1));
        expect(previews.every((r) => r.height == 44), true);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
