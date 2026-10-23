import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

final class _MemoryStore implements SettingsServiceStore {
  _MemoryStore(this.values);
  final Map<String, dynamic> values;
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  for (final (legacy, expected) in [
    (0, ThemeMode.light),
    (1, ThemeMode.dark),
    (2, ThemeMode.system),
    (null, ThemeMode.system),
  ]) {
    test('legacy appearance fallback $legacy', () async {
      await SettingsService.initialize(
        store: _MemoryStore({'themeMode': legacy}),
      );
      expect(SettingsService.appearance.mode, expected);
      expect(SettingsService.background.material, BackgroundMaterial.ambient);
    });
  }

  test(
    'appearance and transparency survive reload without changing legacy UI mode',
    () async {
      final store = _MemoryStore({'themeMode': 1});
      await SettingsService.initialize(store: store);
      final appearance = FrostAppearance.initial(FrostPalettes.pink).copyWith(
        mode: ThemeMode.light,
        lightTone: FrostTone.warm,
        darkTone: FrostTone.cool,
      );
      var notifications = 0;
      final subscription = SettingsService.changes.listen(
        (_) => notifications++,
      );
      addTearDown(subscription.cancel);
      await SettingsService.saveAppearance(appearance);
      await SettingsService.saveBackground(
        const BackgroundSettings(material: BackgroundMaterial.off),
      );
      expect(notifications, 2);
      expect(store.values['appearance'], appearance.toRecord());
      expect(SettingsService.themeMode, 1);
      await SettingsService.initialize(store: store);
      expect(SettingsService.appearance.toRecord(), appearance.toRecord());
      expect(SettingsService.background.material, BackgroundMaterial.off);
      expect(SettingsService.themeMode, 1);
    },
  );

  test('invalid appearance storage retains a safe legacy fallback', () async {
    final store = _MemoryStore({
      'themeMode': 0,
      'appearance': 'invalid',
      'reduceTransparency': 'invalid',
    });
    await SettingsService.initialize(store: store);
    expect(SettingsService.appearance.mode, ThemeMode.light);
    expect(SettingsService.background.material, BackgroundMaterial.ambient);
    expect(store.values.containsKey('appearance'), false);
    expect(store.values.containsKey('reduceTransparency'), false);
  });
}
