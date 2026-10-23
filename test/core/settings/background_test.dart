import 'dart:async';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements SettingsServiceStore {
  _Store(this.values);
  final Map<String, dynamic> values;
  Completer<void>? pending;
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async {
    if (pending case final wait?) await wait.future;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  for (final legacy in [null, false, true, 'invalid']) {
    test('migrates legacy transparency $legacy and deletes old key', () async {
      final store = _Store({'reduceTransparency': legacy});
      await SettingsService.initialize(store: store);
      expect(
        SettingsService.background.material,
        legacy == true ? BackgroundMaterial.off : BackgroundMaterial.ambient,
      );
      expect(SettingsService.background.intensity, 100);
      expect(store.values.containsKey('reduceTransparency'), isFalse);
      await SettingsService.initialize(store: store);
      expect(
        SettingsService.background.material,
        legacy == true ? BackgroundMaterial.off : BackgroundMaterial.ambient,
      );
    });
  }
  test(
    'typed background normalizes stored values and keeps independent intensity',
    () async {
      final store = _Store({
        'background': {'material': 'invalid', 'intensity': 43},
      });
      await SettingsService.initialize(store: store);
      expect(SettingsService.background.material, BackgroundMaterial.ambient);
      expect(SettingsService.background.intensity, 45);
      for (final material in BackgroundMaterial.values) {
        await SettingsService.saveBackground(
          BackgroundSettings(material: material, intensity: 40),
        );
        await SettingsService.initialize(store: store);
        expect(SettingsService.background.material, material);
        expect(SettingsService.background.intensity, 40);
      }
      expect(BackgroundSettings.normalizeIntensity(0), 10);
      expect(BackgroundSettings.normalizeIntensity(105), 100);
      expect(BackgroundSettings.normalizeIntensity(double.nan), 100);
    },
  );
  test(
    'drag preview is live, not written until completion, and a failed save rolls back',
    () async {
      final store = _Store({});
      await SettingsService.initialize(store: store);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final settings = container.read(settingsProvider.notifier);
      settings.previewBackgroundIntensity(40);
      expect(container.read(settingsProvider).background.intensity, 40);
      expect(SettingsService.background.intensity, 100);
      final pending = store.pending = Completer<void>();
      final save = settings.saveBackgroundIntensity(40);
      expect(SettingsService.background.intensity, 100);
      pending.complete();
      await save;
      expect(SettingsService.background.intensity, 40);
      store.pending = Completer<void>();
      settings.previewBackgroundIntensity(70);
      final failure = settings.saveBackgroundIntensity(70);
      final expectation = expectLater(failure, throwsStateError);
      store.pending!.completeError(StateError('storage'));
      await expectation;
      expect(container.read(settingsProvider).background.intensity, 40);
      expect(SettingsService.background.intensity, 40);
    },
  );
  test('material choice survives an earlier pending intensity write', () async {
    final store = _Store({});
    await SettingsService.initialize(store: store);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final settings = container.read(settingsProvider.notifier);
    final gate = store.pending = Completer<void>();
    settings.previewBackgroundIntensity(40);
    final intensity = settings.saveBackgroundIntensity(40);
    final material = settings.setBackgroundMaterial(BackgroundMaterial.mica);
    expect(SettingsService.background.material, BackgroundMaterial.ambient);
    gate.complete();
    await Future.wait([intensity, material]);
    expect(SettingsService.background.material, BackgroundMaterial.mica);
    expect(SettingsService.background.intensity, 40);
    expect(
      container.read(settingsProvider).background.material,
      BackgroundMaterial.mica,
    );
  });
  test(
    'custom accent source survives preset selection and identical preset/custom colours',
    () async {
      final store = _Store({});
      await SettingsService.initialize(store: store);
      final value = SettingsService.appearance;
      final custom = value.copyWith(lightCustomAccent: value.lightAccent);
      await SettingsService.saveAppearance(
        custom,
        accentBrightness: Brightness.light,
        customSelected: true,
      );
      expect(SettingsService.customAccentSelected(Brightness.light), isTrue);
      await SettingsService.saveAppearance(
        custom,
        accentBrightness: Brightness.light,
        customSelected: false,
      );
      await SettingsService.initialize(store: store);
      expect(SettingsService.customAccentSelected(Brightness.light), isFalse);
      expect(SettingsService.appearance.lightCustomAccent, value.lightAccent);
    },
  );
}
