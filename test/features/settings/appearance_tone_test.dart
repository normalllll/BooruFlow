import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../support/browse_support.dart' show browseTestApp;

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
          final tone = find.byType(FrostPicker<FrostTone>);
          final row = find.byWidgetPredicate(
            (w) => w is FrostListRow && w.title == t.settingsV2.tone,
          );
          FrostPicker<FrostTone> picker() =>
              tester.widget<FrostPicker<FrostTone>>(tone);
          expect(row, findsOneWidget);
          expect(picker().onChanged, isNull);
          expect(find.text('System mode uses a neutral tone.'), findsNothing);
          await tester.tap(find.text(t.settingsV2.warm), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(SettingsService.appearance.lightTone, FrostTone.cool);
          expect(SettingsService.appearance.darkTone, FrostTone.warm);
          expect(
            SettingsService.appearance.effectiveToneFor(Brightness.light),
            FrostTone.neutral,
          );
          await tester.tap(find.text(t.settings.light));
          await tester.pumpAndSettle();
          expect(picker().onChanged, isNotNull);
          await tester.tap(find.text(t.settingsV2.warm));
          await tester.pumpAndSettle();
          expect(SettingsService.appearance.lightTone, FrostTone.warm);
          await tester.tap(find.text(t.settings.system));
          await tester.pumpAndSettle();
          expect(picker().onChanged, isNull);
          expect(SettingsService.appearance.lightTone, FrostTone.warm);
          expect(
            SettingsService.appearance.effectiveToneFor(Brightness.light),
            FrostTone.neutral,
          );
          await tester.tap(find.text(t.settings.light));
          await tester.pumpAndSettle();
          expect(picker().value, FrostTone.warm);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
