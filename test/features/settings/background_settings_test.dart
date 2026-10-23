import 'dart:async';

import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  Completer<void>? pending;
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async {
    await pending?.future;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

Future<void> focusSlider(WidgetTester tester, Finder slider) async {
  final focus = tester
      .widgetList<Focus>(
        find.descendant(of: slider, matching: find.byType(Focus)),
      )
      .map((widget) => widget.focusNode)
      .whereType<FocusNode>();
  for (var step = 0; step < 40 && !focus.any((node) => node.hasFocus); step++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(focus.any((node) => node.hasFocus), isTrue);
}

void main() {
  late _Store store;
  setUp(() async {
    store = _Store();
    await SettingsService.initialize(store: store);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });
  Widget app({bool mica = true, bool reduced = false, double scale = 1}) =>
      ProviderScope(
        child: browseTestApp(
          FrostWindowCaptionScope(
            systemBackdropAvailable: mica,
            child: SystemTransparencyPreference(
              disabled: reduced,
              child: const SingleChildScrollView(child: AppearanceSettings()),
            ),
          ),
          scale: scale,
        ),
      );
  for (final locale in AppLocale.values) {
    for (final width in [390.0, 1024.0]) {
      testWidgets(
        'background controls preserve all labels at $locale width=$width scale=2',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          LocaleSettings.setLocaleSync(locale);
          await tester.pumpWidget(app(scale: 2));
          await tester.pumpAndSettle();
          expect(find.text(t.settingsV2.ambientBlur), findsOneWidget);
          expect(find.text(t.settingsV2.mica), findsOneWidget);
          expect(find.text(t.settingsV2.backgroundOff), findsOneWidget);
          expect(find.byType(FrostColorSwatch), findsNWidgets(7));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'real slider previews during drag, saves on release, restores on material change and steps 5 percent',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final intensityRow = find.byWidgetPredicate(
        (widget) =>
            widget is FrostListRow &&
            widget.title == t.settingsV2.backgroundIntensity,
      );
      expect(tester.widget<FrostListRow>(intensityRow).value, isNull);
      final slider = find.byType(FrostSlider);
      await tester.ensureVisible(slider);
      final rect = tester.getRect(slider);
      final gesture = await tester.startGesture(rect.center);
      await gesture.moveTo(Offset(rect.left + rect.width * .4, rect.center.dy));
      await tester.pump();
      expect(SettingsService.background.intensity, 100);
      expect(tester.widget<FrostSlider>(slider).value, lessThan(100));
      await gesture.up();
      await tester.pumpAndSettle();
      final saved = SettingsService.background.intensity;
      expect(saved, lessThan(100));
      await tester.tap(find.text(t.settingsV2.backgroundOff));
      await tester.pumpAndSettle();
      expect(SettingsService.background.material, BackgroundMaterial.off);
      expect(find.byType(FrostSlider), findsNothing);
      await tester.tap(find.text(t.settingsV2.ambientBlur));
      await tester.pumpAndSettle();
      expect(SettingsService.background.intensity, saved);
      await tester.ensureVisible(slider);
      await tester.tap(slider);
      await tester.pumpAndSettle();
      await focusSlider(tester, slider);
      final before = SettingsService.background.intensity;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(SettingsService.background.intensity, before + 5);
      expect(
        tester.widget<FrostSlider>(slider).valueLabel!(before.toDouble()),
        '$before%',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'slider retains keyboard focus and latest value while persistence is pending',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final slider = find.byType(FrostSlider);
      await tester.ensureVisible(slider);
      await tester.tap(slider);
      await tester.pumpAndSettle();
      await focusSlider(tester, slider);
      final before = tester.widget<FrostSlider>(slider).value;
      final gate = store.pending = Completer<void>();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(tester.widget<FrostSlider>(slider).onChanged, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(tester.widget<FrostSlider>(slider).value, before - 10);
      gate.complete();
      await tester.pumpAndSettle();
      expect(SettingsService.background.intensity, before.round() - 10);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'unavailable Mica is omitted and system preference preserves saved ambient choice',
    (tester) async {
      await tester.pumpWidget(app(mica: false, reduced: true));
      await tester.pumpAndSettle();
      expect(find.text(t.settingsV2.mica), findsNothing);
      expect(find.text(t.settingsV2.systemTransparencyReduced), findsOneWidget);
      expect(SettingsService.background.material, BackgroundMaterial.ambient);
      expect(SettingsService.background.intensity, 100);
      expect(tester.takeException(), isNull);
    },
  );
}
