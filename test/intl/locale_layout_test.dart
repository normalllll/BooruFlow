import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

void main() {
  setUpAll(() async {
    for (final family in ['JP', 'SC']) {
      await (FontLoader('Noto Sans $family')..addFont(
            rootBundle.load('assets/fonts/NotoSans$family-Subset.ttf'),
          ))
          .load();
    }
  });
  for (final locale in AppLocale.values) {
    for (final width in [390.0, 860.0]) {
      testWidgets(
        'actual navigation, header, appearance, buttons fit $locale at $width / 1.3',
        (tester) async {
          await SettingsService.initialize(store: _Store());
          LocaleSettings.setLocaleSync(locale);
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final names = [
            t.navigation.browse,
            t.navigation.search,
            t.navigation.downloads,
            t.navigation.settings,
          ];
          await tester.pumpWidget(
            TranslationProvider(
              child: ProviderScope(
                child: FrostWindowCaptionScope(
                  systemBackdropAvailable: true,
                  child: FrostScope(
                    config: appFrostConfig,
                    child: MaterialApp(
                      locale: locale.flutterLocale,
                      supportedLocales: AppLocaleUtils.supportedLocales,
                      localizationsDelegates:
                          GlobalMaterialLocalizations.delegates,
                      theme: FrostTheme.build(
                        config: appFrostConfig,
                        brightness: Brightness.light,
                        platform: width == 390
                            ? TargetPlatform.android
                            : TargetPlatform.windows,
                        locale: locale.flutterLocale,
                      ),
                      home: Builder(
                        builder: (context) => MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: const TextScaler.linear(1.3)),
                          child: FrostLayoutScope(
                            child: FrostShell(
                              destinations: [
                                for (final name in names)
                                  FrostNavDestination(
                                    label: name,
                                    icon: appIcons.more,
                                  ),
                              ],
                              selectedIndex: 3,
                              canGoBack: false,
                              onBack: () {},
                              atDestinationRoot: true,
                              onDestinationSelected: (_) {},
                              showsMobileNavigation: true,
                              child: FrostShellDestination(
                                child: Column(
                                  children: [
                                    FrostPageHeader(
                                      title: FrostText(t.settingsV2.appearance),
                                    ),
                                    const Expanded(
                                      child: SingleChildScrollView(
                                        child: AppearanceSettings(),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FrostButton.quiet(
                                          label: t.generic.cancel,
                                          onPressed: () {},
                                        ),
                                        FrostButton(
                                          label: t.settings.account.save,
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final name in names) {
            final paragraphs = tester
                .renderObjectList<RenderParagraph>(
                  find.descendant(
                    of: find.byType(FrostShell),
                    matching: find.byType(RichText),
                  ),
                )
                .where((p) => p.text.toPlainText() == name)
                .toList();
            // Both windows are portrait, so the shell has the labelled bottom bar.
            expect(paragraphs, isNotEmpty, reason: name);
            for (final p in paragraphs) {
              expect(
                p.didExceedMaxLines,
                false,
                reason: '$locale navigation $name',
              );
              final boxes = p.getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: name.length),
              );
              expect(
                boxes.map((b) => b.top).toSet().length,
                1,
                reason: '$locale navigation wraps: $name',
              );
            }
          }
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          )) {
            expect(
              p.didExceedMaxLines,
              false,
              reason: '$locale / $width clipped: ${p.text.toPlainText()}',
            );
          }
          for (final label in [
            t.settingsV2.ambientBlur,
            t.settingsV2.mica,
            t.settingsV2.backgroundOff,
          ]) {
            expect(find.text(label), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
