import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/features/settings/network_status_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import '../discovery/search_interaction_test.dart' show testSource;

const _cached = RouteDiagnosticDto(
  sourceIds: ['yande'],
  logicalHost: 'yande.re',
  status: 'cached',
  candidates: ['198.251.89.183', '2605:6400:30:f1ee:f6a4:e578:483f:2a64'],
  updatedAtIso8601: '2026-09-08T05:00:00Z',
  elapsedMs: 720,
);
const _failed = RouteDiagnosticDto(
  sourceIds: ['danbooru'],
  logicalHost: 'danbooru.donmai.us',
  status: 'failed',
  candidates: [],
  error: 'DNS request timed out (8s)',
  elapsedMs: 8000,
);

RouteCacheStateDto state(
  List<RouteDiagnosticDto> reports, {
  bool refreshing = false,
}) => RouteCacheStateDto(
  initialized: true,
  refreshing: refreshing,
  routeRevision: '1',
  provider: RouteProvider.uncensoredDns,
  routes: const [],
  diagnostics: reports,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  for (final locale in AppLocale.values) {
    testWidgets('network messages follow locale ${locale.name}', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(locale);
      final snapshot = state([_cached]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NetworkStatusPanel(
                sources: [testSource('yande')],
                readState: () async => snapshot,
                refreshRoutes: () async => snapshot,
                checkSource: (_) async {},
                onBusyChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.settings.network.servicesTitle), findsOneWidget);
      expect(find.textContaining(t.settings.network.dnsCached), findsOneWidget);
      expect(find.text(t.settings.network.apiUnchecked), findsOneWidget);
      if (locale != AppLocale.en) {
        expect(
          find.text(AppLocale.en.buildSync().settings.network.servicesTitle),
          findsNothing,
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'shows cached IPs, local timestamp, failures and every source without fetching',
    (tester) async {
      var refreshes = 0;
      var checks = 0;
      final snapshot = state([_cached, _failed]);
      final sources = [
        'yande',
        'danbooru',
        'aibooru',
        'gelbooru',
        'konachan_net',
        'wallhaven',
        'anime_pictures',
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NetworkStatusPanel(
                sources: sources.map(testSource).toList(),
                readState: () async => snapshot,
                refreshRoutes: () async {
                  refreshes++;
                  return snapshot;
                },
                checkSource: (_) async {
                  checks++;
                },
                onBusyChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final source in sources) {
        expect(find.text(source), findsOneWidget);
      }
      expect(find.textContaining('198.251.89.183'), findsOneWidget);
      expect(
        find.textContaining('IP cached · Updated at 2026-09-08'),
        findsOneWidget,
      );
      expect(find.textContaining('Using cached IPs'), findsOneWidget);
      expect(find.text('DNS request timed out (8s)'), findsOneWidget);
      expect(refreshes, 0);
      expect(checks, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'refresh preserves the source list and shows progress and final API error',
    (tester) async {
      final done = Completer<RouteCacheStateDto>();
      final check = Completer<void>();
      var snapshot = state([_cached, _failed]);
      final busy = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NetworkStatusPanel(
                sources: [testSource('yande'), testSource('danbooru')],
                readState: () async => snapshot,
                refreshRoutes: () => done.future,
                checkSource: (id) async {
                  if (id == 'yande') {
                    await check.future;
                  } else {
                    throw Exception('HTTP 403');
                  }
                },
                onBusyChanged: busy.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.network.refreshRoutes));
      await tester.pump();
      snapshot = state([
        const RouteDiagnosticDto(
          sourceIds: ['yande'],
          logicalHost: 'yande.re',
          status: 'resolving',
          candidates: [],
        ),
        _failed,
      ], refreshing: true);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('yande'), findsOneWidget);
      expect(find.textContaining('Resolving'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      snapshot = state([_cached, _failed]);
      done.complete(snapshot);
      await tester.pump();
      expect(find.text(t.settings.network.apiChecking), findsOneWidget);
      check.complete();
      await tester.pumpAndSettle();
      expect(find.text(t.settings.network.apiAvailable), findsOneWidget);
      expect(find.text(t.settings.network.apiFailed), findsOneWidget);
      expect(find.textContaining('HTTP 403'), findsOneWidget);
      expect(busy, [true, false]);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [360.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('network results fit width $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final snapshot = state([_cached, _failed]);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: NetworkStatusPanel(
                    sources: [testSource('yande'), testSource('danbooru')],
                    readState: () async => snapshot,
                    refreshRoutes: () async => snapshot,
                    checkSource: (_) async {},
                    onBusyChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('2605:6400'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

