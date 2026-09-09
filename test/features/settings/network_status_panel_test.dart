import 'dart:async';

import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/widgets/network_status_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../discovery/search_interaction_test.dart' show testSource;

const snapshot = RouteCacheState(
  initialized: true,
  refreshing: false,
  routeRevision: '1',
  provider: RouteProvider.uncensoredDns,
  routes: [],
  diagnostics: [
    RouteDiagnostic(
      sourceIds: ['yande'],
      logicalHost: 'yande.re',
      status: 'cached',
      candidates: ['198.251.89.183'],
      updatedAtIso8601: '2026-09-08T05:00:00Z',
    ),
    RouteDiagnostic(
      sourceIds: ['danbooru'],
      logicalHost: 'danbooru.donmai.us',
      status: 'failed',
      candidates: [],
      error: 'DNS fixture failure',
    ),
  ],
);
SourceConnectionCheck result(String id, bool api, bool media) =>
    SourceConnectionCheck(
      sourceId: id,
      apiAvailable: api,
      mediaAvailable: media,
    );
Widget panel({
  Future<SourceConnectionCheck> Function(String)? probe,
  VoidCallback? refresh,
  double scale = 1,
}) => ProviderScope(
  overrides: [
    networkProbeBackendProvider.overrideWithValue(
      NetworkProbeBackend(
        sources: ['yande', 'danbooru', 'wallhaven'].map(testSource).toList(),
        read: () async => snapshot,
        refresh: () async {
          refresh?.call();
          return snapshot;
        },
        probe: probe ?? (id) async => result(id, true, true),
        load: () => null,
        save: (_) async {},
      ),
    ),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: const Scaffold(
        body: SingleChildScrollView(child: NetworkStatusPanel()),
      ),
    ),
  ),
);
Icon dot(WidgetTester tester, String id) =>
    tester.widget<Icon>(find.byKey(ValueKey('source-status-$id')));
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  for (final width in [360.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('source list fits $width/$scale and opens selected details', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(panel(scale: scale));
        await tester.pumpAndSettle();
        expect(find.byType(TabBar), findsNothing);
        expect(find.byType(TabBarView), findsNothing);
        for (final id in ['yande', 'danbooru', 'wallhaven']) {
          expect(find.byKey(ValueKey('source-details-$id')), findsOneWidget);
        }
        expect(find.text('198.251.89.183'), findsNothing);
        expect(find.text('DNS fixture failure'), findsNothing);
        await tester.ensureVisible(find.text('danbooru'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('source-details-danbooru')));
        await tester.pumpAndSettle();
        expect(find.text('DNS fixture failure'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets(
    'all probes start without DNS and publish green/yellow while first hangs',
    (tester) async {
      final pending = Completer<SourceConnectionCheck>();
      final calls = <String>[];
      var refreshes = 0;
      await tester.pumpWidget(
        panel(
          refresh: () => refreshes++,
          probe: (id) {
            calls.add(id);
            return id == 'yande'
                ? pending.future
                : Future.value(result(id, true, id == 'danbooru'));
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.network.checkCompact));
      await tester.pump();
      await tester.pump();
      expect(calls, ['yande', 'danbooru', 'wallhaven']);
      expect(refreshes, 0);
      expect(dot(tester, 'danbooru').color, Colors.greenAccent.shade400);
      expect(dot(tester, 'wallhaven').color, Colors.amber);
      expect(dot(tester, 'yande').color, Colors.blue);
      await tester.pump(const Duration(seconds: 27));
      await tester.pump();
      expect(dot(tester, 'yande').color, Colors.redAccent);
      pending.complete(result('yande', true, true));
      await tester.pump();
      expect(dot(tester, 'yande').color, Colors.redAccent);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('DNS refresh does not silently run source tests', (tester) async {
    var calls = 0;
    var refreshes = 0;
    await tester.pumpWidget(
      panel(
        refresh: () => refreshes++,
        probe: (id) async {
          calls++;
          return result(id, true, true);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('source-details-yande')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.network.refreshRoutes));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(calls, 0);
    expect(dot(tester, 'yande').color, Colors.grey);
    await tester.pumpWidget(const SizedBox());
  });
}
