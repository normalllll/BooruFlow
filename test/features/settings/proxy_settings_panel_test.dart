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
    expect(await probeProxyConnectivity(endpoint), isTrue);
    await accepted.future;
    await subscription.cancel();
    await server.close();
    expect(await probeProxyConnectivity(endpoint), isFalse);
  });
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
      final pending = Completer<bool>();
      String? active = 'http://127.0.0.1:7890';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proxySettingsProvider.overrideWith(TestProxyController.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (_, refresh) => ProxySettingsPanel(
                    appliedUrl: active,

                    onApply: (value) async {
                      applied.add(value);
                      refresh(() => active = value);
                      return true;
                    },
                    probe: (value) {
                      probed.add(value);
                      return probed.length == 1
                          ? Future.value(true)
                          : pending.future;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
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
      expect(find.byKey(const ValueKey('proxy-save')), findsOneWidget);
      await tester.tap(find.text(t.settings.network.checkCompact));
      await tester.pump();
      await tester.pump();
      expect(probed, ['http://127.0.0.1:7890', 'http://127.0.0.1:7891']);
      expect(applied, isEmpty);
      pending.complete(false);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('proxy-save')));
      await tester.pumpAndSettle();
      expect(applied, ['http://127.0.0.1:7891']);
      await tester.tap(find.byKey(const ValueKey('proxy-switch')));
      await tester.pumpAndSettle();
      expect(applied.last, isNull);
      expect(
        tester.widget<Switch>(find.byKey(const ValueKey('proxy-switch'))).value,
        isFalse,
      );
      expect(find.text(t.settings.network.proxyHelp), findsNothing);
      await tester.tap(find.byKey(const ValueKey('proxy-switch')));
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
