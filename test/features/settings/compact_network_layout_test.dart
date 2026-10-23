import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/booru/widgets/web_challenge_data_panel.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/settings/network/widgets/network_status_panel.dart';
import 'package:booruflow/features/settings/network/widgets/proxy_settings_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;
import 'network_status_panel_test.dart' show snapshot, result;

void main() {
  setUpAll(initializeDateFormatting);
  for (final width in [360.0, 760.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('compact network geometry $width/$scale', (tester) async {
        LocaleSettings.setLocaleSync(AppLocale.en);
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final sources = [
          'Yande.re',
          'Konachan.net',
          'Konachan.com',
          'Danbooru',
          'AIBooru',
          'Gelbooru',
          'Wallhaven',
          'Anime-Pictures',
        ].map(testSource).toList();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              booruServiceProvider.overrideWithValue(
                BooruService()..useSourcesForTesting(sources),
              ),
              proxySettingsProvider.overrideWith(PreviewProxyController.new),
              networkProbeBackendProvider.overrideWithValue(
                NetworkProbeBackend(
                  sources: sources,
                  read: () async => snapshot,
                  refresh: () async => snapshot,
                  probe: (id) async => result(id, true, true),
                  load: () => null,
                  save: (_) async {},
                ),
              ),
            ],
            child: browseTestApp(
              Builder(
                builder: (context) => SingleChildScrollView(
                  primary: false,
                  child: Padding(
                    padding: const EdgeInsets.all(FrostGap.rowInset),
                    child: Column(
                      children: [
                        FrostButton(
                          label: 'Proxy details',
                          onPressed: () => showProxySettingsDialog(
                            context: context,
                            appliedUrl: 'http://127.0.0.1:7890',
                            onApply: (_) async => true,
                            probe: (_) async =>
                                const ProxyConnectivityResult(reachable: true),
                          ),
                        ),
                        const NetworkStatusPanel(),
                        WebChallengeDataPanel(
                          compact: true,
                          sources: sources,
                          readState: (id) async => WebChallengeState(
                            sourceId: id,
                            hasSavedData: false,
                            verified: false,
                            revision: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              scale: scale,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EditableText), findsNothing);
        await tester.tap(find.text('Proxy details'));
        await tester.pumpAndSettle();
        final host = find.byKey(const ValueKey('proxy-host')),
            port = find.byKey(const ValueKey('proxy-port'));
        if (scale > 1.3) {
          expect(
            tester.getTopLeft(port).dy,
            greaterThan(tester.getBottomLeft(host).dy),
          );
        } else {
          expect(tester.getTopLeft(port).dy, tester.getTopLeft(host).dy);
          expect(
            tester.getTopLeft(port).dx,
            greaterThan(tester.getTopRight(host).dx),
          );
        }
        expect(find.byType(FrostPicker<String>), findsOneWidget);
        expect(find.byType(FrostSwitch), findsNothing);
        expect(find.text(t.settings.network.proxyDisable), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(t.frost.cancel));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(t.webChallenge.title));
        await tester.tap(find.text(t.webChallenge.title));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('web-data-${sources.first.sourceId}')),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

class PreviewProxyController extends ProxySettings {
  @override
  ProxySettingsState build() =>
      ProxySettingsState.fromUrl('http://127.0.0.1:7890');
}
