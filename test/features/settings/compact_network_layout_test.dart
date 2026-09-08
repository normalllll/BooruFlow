import 'dart:io';
import 'dart:ui' as ui;

import 'package:booruflow/features/settings/network_settings_state.dart';
import 'package:booruflow/features/settings/network_status_panel.dart';
import 'package:booruflow/features/settings/proxy_settings_panel.dart';
import 'package:booruflow/features/settings/proxy_settings_state.dart';
import 'package:booruflow/features/settings/web_challenge_data_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../discovery/search_interaction_test.dart' show testSource;
import 'network_status_panel_test.dart' show snapshot, result;

void main() {
  for (final width in [360.0, 760.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('compact network geometry $width/$scale', (tester) async {
        final preview =
            Platform.environment['NETWORK_UI_PREVIEW'] == '1' &&
            width == 760 &&
            scale == 1;
        if (preview) {
          await tester.runAsync(() async {
            final bytes = await File('C:/Windows/Fonts/msyh.ttc').readAsBytes();
            final loader = FontLoader('PreviewUI')
              ..addFont(Future.value(ByteData.sublistView(bytes)));
            await loader.load();
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
          });
        }
        LocaleSettings.setLocaleSync(preview ? AppLocale.zhCn : AppLocale.en);
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
        final boundaryKey = GlobalKey();
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
        final theme = lightTheme();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
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
            child: MaterialApp(
              theme: preview
                  ? theme.copyWith(
                      textTheme: theme.textTheme.apply(fontFamily: 'PreviewUI'),
                    )
                  : theme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: Scaffold(
                    appBar: AppBar(title: Text(t.settings.sections.network)),
                    body: GroupedSettingsList(
                      groups: [
                        [
                          ProxySettingsPanel(
                            appliedUrl: 'http://127.0.0.1:7890',

                            onApply: (_) async => true,

                            probe: (_) async => true,
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.cell_tower,
                              color: Colors.grey,
                            ),
                            title: IgnorePointer(
                              child: Opacity(
                                opacity: 0.38,
                                child: AppSelect<String>(
                                  label: t.settings.network.connectionMode,
                                  value: 'system',
                                  items: [
                                    AppSelectItem(
                                      value: 'system',
                                      label: t.settings.network.systemDns,
                                    ),
                                  ],
                                  onChanged: (_) {},
                                ),
                              ),
                            ),
                          ),
                        ],
                        [const NetworkStatusPanel()],
                        [
                          ExpansionTile(
                            title: Text(t.settings.network.advancedCompact),
                            leading: const Icon(Icons.tune_rounded),
                            children: [
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
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final host = tester.getTopLeft(
          find.byKey(const ValueKey('proxy-host')),
        );
        final port = tester.getTopLeft(
          find.byKey(const ValueKey('proxy-port')),
        );
        final protocol = tester.getTopLeft(
          find.byKey(const ValueKey('proxy-protocol')),
        );
        if (scale == 1 || width == 760) {
          expect(host.dy, port.dy);
          expect(host.dy, protocol.dy);
        }
        if (scale == 1) {
          expect(
            tester.getSize(find.byType(ProxySettingsPanel)).height,
            lessThan(180),
          );
          expect(
            tester.getSize(find.byType(NetworkStatusPanel)).height,
            lessThan(600),
          );
        }
        expect(find.byType(Switch), findsOneWidget);
        expect(find.text(t.settings.network.proxyHelp), findsNothing);
        expect(find.text(t.settings.network.sourceProbeHelp), findsNothing);
        expect(tester.takeException(), isNull);
        if (preview) {
          await tester.tap(
            find.descendant(
              of: find.byType(NetworkStatusPanel),
              matching: find.text(t.settings.network.checkCompact),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1.5);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'build/compact-network.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.scrollUntilVisible(
          find.text(t.settings.network.advancedCompact),
          150,
          scrollable: find
              .descendant(
                of: find.byType(GroupedSettingsList),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text(t.settings.network.advancedCompact));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(t.webChallenge.title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.webChallenge.title));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('web-data-${sources.first.sourceId}')),
          findsOneWidget,
        );
        if (scale == 1) {
          expect(
            tester
                .getSize(
                  find.byKey(ValueKey('web-data-${sources.first.sourceId}')),
                )
                .height,
            lessThanOrEqualTo(64),
          );
        }
        expect(tester.takeException(), isNull);
        if (preview) {
          await tester.ensureVisible(find.text(t.webChallenge.clearAll));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1.5);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'build/compact-web-data.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

class PreviewProxyController extends ProxySettingsController {
  @override
  ProxySettingsState build() =>
      ProxySettingsState.fromUrl('http://127.0.0.1:7890');
}
