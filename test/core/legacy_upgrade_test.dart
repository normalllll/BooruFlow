import 'package:booruflow/core/legacy_upgrade.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements SettingsServiceStore {
  _Store(this.values);
  final Map<String, dynamic> values;
  final writes = <String>[];
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async {
    writes.add(key);
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  test(
    'old ordinals are upgraded once to stable names including legacy IP URL',
    () async {
      final store = _Store({
        'booruNetworkFallbackMode': 2,
        'booruDnsProvider': 1,
        'booruRatings': [0, 3],
      });
      await SettingsService.initialize(store: store);
      expect(
        SettingsService.networkFallbackMode,
        NetworkFallbackMode.persistedIpOverride,
      );
      expect(store.values['booruNetworkFallbackMode'], 'persistedIpOverride');
      expect(SettingsService.dnsProvider, RouteProvider.dohSb);
      expect(store.values['booruDnsProvider'], 'dohSb');
      expect(SettingsService.ratings, [
        ContentRating.general,
        ContentRating.explicit,
      ]);
      expect(store.values['booruRatings'], ['general', 'explicit']);
      expect(store.values[legacySettingsVersionKey], 1);
      store.writes.clear();
      await SettingsService.initialize(store: store);
      expect(store.writes, isEmpty);
    },
  );
  test('the old named mode upgrades and current writes remain named', () async {
    final store = _Store({'booruNetworkFallbackMode': 'legacyIpUrl'});
    await SettingsService.initialize(store: store);
    SettingsService.networkFallbackMode = NetworkFallbackMode.off;
    SettingsService.dnsProvider = RouteProvider.uncensoredDns;
    SettingsService.ratings = [ContentRating.sensitive];
    expect(store.values['booruNetworkFallbackMode'], 'off');
    expect(store.values['booruDnsProvider'], 'uncensoredDns');
    expect(store.values['booruRatings'], ['sensitive']);
  });
  test(
    'a failed migration does not publish its version and can retry',
    () async {
      final stored = <String, dynamic>{'reduceTransparency': true};
      await expectLater(
        upgradeLegacySettings(stored, (key, value) async {
          if (key == 'booruDnsProvider') throw StateError('disk');
          stored[key] = value;
        }),
        throwsStateError,
      );
      expect(stored.containsKey(legacySettingsVersionKey), false);
      final result = await upgradeLegacySettings(
        stored,
        (key, value) async => stored[key] = value,
      );
      expect(result[legacySettingsVersionKey], 1);
      expect((result['background'] as Map)['material'], 'off');
    },
  );
}
