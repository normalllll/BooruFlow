import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../support/browse_support.dart' show browseTestApp;
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
      final steppers = tester
          .widgetList<FrostStepper>(find.byType(FrostStepper))
          .toList();
      expect(steppers, hasLength(2));
      for (final stepper in steppers) {
        expect(find.text('${stepper.value.toInt()}'), findsWidgets);
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
      final appearance = find.byWidgetPredicate(
        (w) => w is FrostListRow && w.title == t.settingsV2.appearance,
      );
      expect(
        find.descendant(of: appearance, matching: find.text(t.settings.system)),
        findsOneWidget,
      );
      expect(find.text(t.settingsDetails.systemDnsShort), findsOneWidget);
      expect(find.byType(FrostPicker<ThemeMode>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'wide section starts 32 after the navigation hairline under the one title',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(mount(const SettingsPage()));
      await tester.pumpAndSettle();
      // The page header holds the only title; the section names itself in
      // the navigation column, not again above its settings.
      expect(
        find.byWidgetPredicate(
          (w) => w is FrostText && w.role == FrostTextRole.title2,
        ),
        findsNothing,
      );
      final title = find.byType(AppearanceSettings);
      final pane = tester.getRect(find.byType(FrostSettingsSections));
      // The navigation column's width follows the window; measure its hairline.
      final hairline = tester.getRect(
        find.descendant(
          of: find.byType(FrostSettingsSections),
          matching: find.byWidgetPredicate(
            (w) => w is FrostDivider && w.axis == Axis.vertical,
          ),
        ),
      );
      expect(hairline.left, greaterThanOrEqualTo(pane.left + 236));
      expect(tester.getTopLeft(title).dx, closeTo(hairline.right + 32, .001));
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
      'phone tone choice stays inside the row without clipping at $scale',
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
        // The tone is one segmented choice; no palette preview is drawn.
        final tone = find.byType(FrostPicker<FrostTone>);
        expect(tone, findsOneWidget);
        expect(find.byType(FrostThumbnail), findsNothing);
        expect(
          tester.getRect(tone).right,
          lessThanOrEqualTo(tester.view.physicalSize.width),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
