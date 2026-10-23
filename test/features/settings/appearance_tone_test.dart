import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;
}

void main() {
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    LocaleSettings.setLocaleSync(AppLocale.en);
    await SettingsService.saveAppearance(
      SettingsService.appearance.copyWith(
        mode: ThemeMode.system,
        lightTone: FrostTone.cool,
        darkTone: FrostTone.warm,
      ),
    );
  });
  for (final width in [390.0, 1024.0]) {
    testWidgets(
      'system tone is disabled without a footer and preserves manual choices at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            ProviderScope(
              child: browseTestApp(
                const SingleChildScrollView(child: AppearanceSettings()),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final row = find.byWidgetPredicate(
            (w) => w is FrostListRow && w.title == t.settingsV2.tone,
          );
          final warm = find.byWidgetPredicate(
            (w) => w is FrostThumbnail && w.semanticLabel == t.settingsV2.warm,
          );
          expect(tester.widget<FrostListRow>(row).enabled, isFalse);
          expect(
            tester.getTopLeft(warm).dy - tester.getTopLeft(row).dy,
            greaterThanOrEqualTo(FrostGap.related),
          );
          expect(
            tester.getSemantics(row),
            matchesSemantics(
              hasEnabledState: true,
              isEnabled: false,
              label: t.settingsV2.tone,
              isSelected: false,
              hasSelectedState: true,
              hasToggledState: false,
              isButton: false,
              hasCheckedState: false,
            ),
          );
          expect(find.text('System mode uses a neutral tone.'), findsNothing);
          await tester.tap(warm, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(SettingsService.appearance.lightTone, FrostTone.cool);
          expect(SettingsService.appearance.darkTone, FrostTone.warm);
          expect(
            SettingsService.appearance.effectiveToneFor(Brightness.light),
            FrostTone.neutral,
          );
          await tester.tap(find.text(t.settings.light));
          await tester.pumpAndSettle();
          expect(tester.widget<FrostListRow>(row).enabled, isTrue);
          await tester.tap(warm);
          await tester.pumpAndSettle();
          expect(SettingsService.appearance.lightTone, FrostTone.warm);
          await tester.tap(find.text(t.settings.system));
          await tester.pumpAndSettle();
          expect(tester.widget<FrostListRow>(row).enabled, isFalse);
          expect(SettingsService.appearance.lightTone, FrostTone.warm);
          expect(
            SettingsService.appearance.effectiveToneFor(Brightness.light),
            FrostTone.neutral,
          );
          await tester.tap(find.text(t.settings.light));
          await tester.pumpAndSettle();
          expect(tester.widget<FrostThumbnail>(warm).selected, isTrue);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
