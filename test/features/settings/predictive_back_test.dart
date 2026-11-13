import 'dart:math' as math;

import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../../support/browse_support.dart' show browseTestApp;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
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
    LocaleSettings.setLocaleSync(AppLocale.en);
  });
  test(
    'predictive preference defaults on and survives reload; invalid data is discarded',
    () async {
      expect(SettingsService.predictiveBack, isTrue);
      final saved = SettingsService.changes.first;
      SettingsService.predictiveBack = false;
      await saved;
      await SettingsService.initialize(store: store);
      expect(SettingsService.predictiveBack, isFalse);
      store.values['predictiveBack'] = 'off';
      await SettingsService.initialize(store: store);
      expect(SettingsService.predictiveBack, isTrue);
    },
  );
  for (final supported in [false, true]) {
    for (final locale in AppLocale.values) {
      testWidgets(
        'predictive control follows capability $supported at $locale with large text',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1500);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          LocaleSettings.setLocaleSync(locale);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                predictiveBackAvailableProvider.overrideWith(
                  (ref) async => supported,
                ),
              ],
              child: browseTestApp(
                const SingleChildScrollView(child: AppearanceSettings()),
                scale: 2,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final row = find.byWidgetPredicate(
            (widget) =>
                widget is FrostListRow &&
                widget.title == t.settingsV2.predictiveBack,
          );
          expect(row, supported ? findsOneWidget : findsNothing);
          expect(
            find.text(t.settingsV2.predictiveBackScope),
            supported ? findsOneWidget : findsNothing,
          );
          if (supported) {
            await tester.ensureVisible(row);
            await tester.tap(row);
            await tester.pumpAndSettle();
            expect(SettingsService.predictiveBack, isFalse);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'download landing starts continuously and coalesces repeated arrivals',
    (tester) async {
      final host = GlobalKey<DownloadFlightHostState>();
      await tester.pumpWidget(
        browseTestApp(
          DownloadFlightHost(
            key: host,
            child: const DownloadFlightTarget(
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      final scale = find.descendant(
        of: find.byType(DownloadFlightTarget),
        matching: find.byType(ScaleTransition),
      );
      double value() => tester.widget<ScaleTransition>(scale).scale.value;
      expect(value(), 1);
      host.currentState!.landed.value++;
      await tester.pump();
      expect(value(), 1);
      var maximum = 1.0, minimum = 1.0, lobes = 0;
      var above = false;
      // The bouncy spring rings below rest by a bounded fraction of its lobe.
      final spring = FrostMotion.bouncy;
      final damping =
          spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));
      final undershoot =
          .06 * math.exp(-math.pi * damping / math.sqrt(1 - damping * damping));
      for (var frame = 0; frame < 80; frame++) {
        if (frame < 12) {
          final before = value();
          host.currentState!.landed.value++;
          await tester.pump();
          expect(value(), closeTo(before, .0001));
        }
        await tester.pump(const Duration(milliseconds: 8));
        maximum = math.max(maximum, value());
        minimum = math.min(minimum, value());
        if (value() > 1.0005 && !above) lobes++;
        above = value() > 1.0005;
        expect(value(), inInclusiveRange(1 - undershoot - .0005, 1.061));
      }
      await tester.pumpAndSettle();
      expect(maximum, greaterThan(1.04));
      expect(lobes, 1);
      expect(minimum, lessThanOrEqualTo(1));
      expect(value(), 1);
    },
  );
  testWidgets(
    'reduced motion settles an active landing and suppresses subsequent pulses',
    (tester) async {
      var reduced = false;
      late StateSetter update;
      final host = GlobalKey<DownloadFlightHostState>();
      await tester.pumpWidget(
        browseTestApp(
          StatefulBuilder(
            builder: (context, set) {
              update = set;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
                child: DownloadFlightHost(
                  key: host,
                  child: const DownloadFlightTarget(
                    child: SizedBox(width: 40, height: 40),
                  ),
                ),
              );
            },
          ),
        ),
      );
      double value() => tester
          .widget<ScaleTransition>(
            find.descendant(
              of: find.byType(DownloadFlightTarget),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
      host.currentState!.landed.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(value(), greaterThan(1));
      update(() => reduced = true);
      await tester.pump();
      expect(value(), 1);
      host.currentState!.landed.value++;
      await tester.pumpAndSettle();
      expect(value(), 1);
    },
  );
}
