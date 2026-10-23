import 'dart:async';
import 'dart:io';

import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/settings/network/widgets/proxy_settings_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

import '../discovery/home_page_test.dart' show browseTestApp;

class Store implements SettingsServiceStore {
  final data = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => data;
  @override
  Future<void> write(String key, dynamic value) async {
    data[key] = value;
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  test('proxy connectivity opens and closes a TCP connection', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<void>();
    final subscription = server.listen((socket) {
      socket.destroy();
      accepted.complete();
    });
    final endpoint = 'http://127.0.0.1:${server.port}';
    final result = await probeProxyConnectivity(endpoint);
    expect(result.reachable, isTrue);
    expect(result.latency, greaterThan(Duration.zero));
    expect(result.latencyMs, greaterThan(0));
    await accepted.future;
    await subscription.cancel();
    await server.close();
    final failed = await probeProxyConnectivity(endpoint);
    expect(failed.reachable, isFalse);
    expect(failed.latencyMs, isNull);
  });
  test('only positive measured durations produce a latency label', () {
    expect(const ProxyConnectivityResult(reachable: true).latencyMs, isNull);
    expect(
      const ProxyConnectivityResult(
        reachable: true,
        latency: Duration.zero,
      ).latencyMs,
      isNull,
    );
    expect(
      const ProxyConnectivityResult(
        reachable: true,
        latency: Duration(microseconds: 250),
      ).latencyMs,
      1,
    );
    expect(
      const ProxyConnectivityResult(
        reachable: true,
        latency: Duration(milliseconds: 128),
      ).latencyMs,
      128,
    );
  });
  testWidgets(
    'proxy displays supplied measured latency and clears it on edit',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proxySettingsProvider.overrideWith(TestProxyController.new),
          ],
          child: browseTestApp(
            ProxySettingsPanel(
              appliedUrl: 'http://127.0.0.1:7890',
              onApply: (_) async => true,
              probe: (_) async => const ProxyConnectivityResult(
                reachable: true,
                latency: Duration(milliseconds: 128),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('${t.settings.network.proxyReachable} · 128 ms'),
        findsOneWidget,
      );
      expect(find.textContaining('0 ms'), findsNothing);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('proxy-port')),
          matching: find.byType(TextField),
        ),
        '7891',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('128 ms'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'fresh settings use system DNS and explicit mode survives reload',
    () async {
      final store = Store();
      await SettingsService.initialize(store: store);
      expect(SettingsService.networkFallbackMode, NetworkFallbackMode.off);
      SettingsService.networkFallbackMode =
          NetworkFallbackMode.persistedIpOverride;
      await SettingsService.initialize(store: store);
      expect(
        SettingsService.networkFallbackMode,
        NetworkFallbackMode.persistedIpOverride,
      );
    },
  );
  test('separate endpoint fields validate ports and preserve IPv6', () {
    expect(proxyEndpoint('http', '127.0.0.1', '7890'), 'http://127.0.0.1:7890');
    expect(proxyEndpoint('socks5h', '::1', '1080'), 'socks5h://[::1]:1080');
    for (final port in ['0', '65536', 'abc']) {
      expect(proxyEndpoint('http', 'localhost', port), isNull);
    }
    expect(proxyEndpoint('http', 'http://localhost', '7890'), isNull);
  });
  testWidgets(
    'proxy checks once on entry and rechecks draft manually without applying',
    (tester) async {
      final applied = <String?>[];
      final probed = <String>[];
      final pending = Completer<ProxyConnectivityResult>();
      String? active = 'http://127.0.0.1:7890';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proxySettingsProvider.overrideWith(TestProxyController.new),
          ],
          child: browseTestApp(
            Builder(
              builder: (context) => FrostButton(
                label: 'Open proxy',
                onPressed: () => showProxySettingsDialog(
                  context: context,
                  appliedUrl: active,
                  onApply: (value) async {
                    applied.add(value);
                    active = value;
                    return true;
                  },
                  probe: (value) {
                    probed.add(value);
                    return probed.length == 1
                        ? Future.value(
                            const ProxyConnectivityResult(reachable: true),
                          )
                        : pending.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open proxy'));
      await tester.pumpAndSettle();
      expect(probed, ['http://127.0.0.1:7890']);
      expect(find.text(t.settings.network.proxyReachable), findsOneWidget);
      await tester.pump();
      expect(probed.length, 1);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('proxy-port')),
          matching: find.byType(TextField),
        ),
        '7891',
      );
      await tester.pump();
      expect(find.text(t.settings.network.proxyApply), findsOneWidget);
      await tester.tap(find.text(t.settings.network.checkCompact));
      await tester.pump();
      await tester.pump();
      expect(probed, ['http://127.0.0.1:7890', 'http://127.0.0.1:7891']);
      expect(applied, isEmpty);
      pending.complete(const ProxyConnectivityResult(reachable: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.network.proxyApply));
      await tester.pumpAndSettle();
      expect(applied, ['http://127.0.0.1:7891']);
      expect(find.byType(FrostDialog), findsNothing);
      await tester.tap(find.text('Open proxy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.network.proxyDisable));
      await tester.pumpAndSettle();
      expect(applied.last, isNull);
      expect(find.byType(FrostDialog), findsNothing);
      await tester.tap(find.text('Open proxy'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FrostDialog>(find.byType(FrostDialog))
            .leadingAction!
            .enabled,
        false,
      );
      await tester.tap(find.text(t.settings.network.proxyApply));
      await tester.pumpAndSettle();
      expect(applied.last, 'http://127.0.0.1:7891');
    },
  );
}

class TestProxyController extends ProxySettings {
  @override
  ProxySettingsState build() =>
      ProxySettingsState.fromUrl('http://127.0.0.1:7890');
}
