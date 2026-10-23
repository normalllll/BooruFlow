import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/settings/settings_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/home_page_test.dart' show browseTestApp;
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => values;
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  late _Store store;
  late BooruService service;
  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    store = _Store();
    await SettingsService.initialize(store: store);
    service = BooruService()
      ..useSourcesForTesting(
        ['yande', 'danbooru', 'wallhaven'].map(testSource).toList(),
      );
  });
  Widget mount(Widget child, {double scale = 1}) => ProviderScope(
    overrides: [booruServiceProvider.overrideWithValue(service)],
    child: browseTestApp(child, scale: scale),
  );
  testWidgets('default source is explicit and browsing does not overwrite it', (
    tester,
  ) async {
    await tester.pumpWidget(
      mount(const SettingsPage(section: SettingsSection.browsing)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.source.defaultSource));
    await tester.pumpAndSettle();
    await tester.tap(find.text('danbooru'));
    await tester.pumpAndSettle();
    expect(SettingsService.defaultSourceId, 'danbooru');
    expect(service.selectedSourceId, 'yande');
    service.selectSource('wallhaven');
    expect(SettingsService.defaultSourceId, 'danbooru');
    await SettingsService.initialize(store: store);
    expect(SettingsService.defaultSourceId, 'danbooru');
    expect(tester.takeException(), isNull);
  });
  for (final width in [390.0, 720.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'separate browsing ratings and readonly source detail at $width/$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            mount(
              const SettingsPage(section: SettingsSection.browsing),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          final explicit = find.text(t.postDetail.ratingExplicit);
          await tester.ensureVisible(explicit);
          await tester.tap(explicit);
          await tester.pumpAndSettle();
          expect(SettingsService.ratings, [ContentRating.explicit]);
          expect(service.selectedSourceId, 'yande');
          expect(SettingsService.defaultSourceId, 'yande');
          expect(find.byType(FrostCheckboxRow), findsNWidgets(4));
          expect(find.byType(EditableText), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            mount(
              const SettingsPage(
                section: SettingsSection.sources,
                sourceId: 'danbooru',
              ),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(t.settings.source.supportedRatings), findsOneWidget);
          expect(find.text(t.settings.source.safetyRating), findsNothing);
          expect(find.byType(TabBar), findsNothing);
          expect(find.byType(EditableText), findsNothing);
          expect(SettingsService.ratings, [ContentRating.explicit]);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'general is language only and appearance mode is persisted separately',
    (tester) async {
      await tester.pumpWidget(
        mount(const SettingsPage(section: SettingsSection.general)),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.settings.language), findsOneWidget);
      expect(find.text(t.settings.theme), findsNothing);
      expect(find.text(t.settings.columnsPerRow), findsNothing);
      await tester.tap(find.text(t.settings.language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('日本語'));
      await tester.pumpAndSettle();
      expect(SettingsService.language, 1);
      await tester.pumpWidget(
        mount(const SettingsPage(section: SettingsSection.appearance)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.dark));
      await tester.pumpAndSettle();
      expect(SettingsService.appearance.mode, ThemeMode.dark);
      await SettingsService.initialize(store: store);
      expect(SettingsService.appearance.mode, ThemeMode.dark);
      expect(SettingsService.language, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'root settings is lazy in narrow layout; wide appearance State survives resize',
    (tester) async {
      tester.view.physicalSize = const Size(560, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(mount(const SettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text(t.settingsV2.appearance), findsOneWidget);
      expect(find.byType(FrostPicker<ThemeMode>), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      final picker = tester.state(find.byType(FrostPicker<ThemeMode>));
      tester.view.physicalSize = const Size(390, 900);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1024, 900);
      await tester.pumpAndSettle();
      expect(
        identical(tester.state(find.byType(FrostPicker<ThemeMode>)), picker),
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [390.0, 720.0, 1440.0]) {
    for (final routed in [false, true]) {
      testWidgets(
        'live locale updates retained settings at $width routed=$routed',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            mount(
              SettingsPage(section: routed ? SettingsSection.general : null),
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          final sections = tester.state(find.byType(FrostSettingsSections));
          final wide = width >= 720;
          if (wide) {
            await tester.tap(find.text(t.settings.sections.general).first);
            await tester.pumpAndSettle();
          }
          for (final locale in [
            AppLocale.ja,
            AppLocale.zhCn,
            AppLocale.zhTw,
            AppLocale.en,
          ]) {
            // Change only Slang's provider. Cached route elements must subscribe
            // themselves, without relying on unrelated settings/theme rebuilds.
            LocaleSettings.setLocaleSync(locale);
            await tester.pumpAndSettle();
            expect(
              identical(
                tester.state(find.byType(FrostSettingsSections)),
                sections,
              ),
              true,
            );
            if (wide) {
              final layout = tester.widget<FrostSettingsSections>(
                find.byType(FrostSettingsSections),
              );
              expect(layout.labels, [
                for (final section in SettingsSection.values) section.title,
              ]);
            }
            expect(
              find.text(t.settings.language).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
          if (wide) {
            tester.view.physicalSize = const Size(390, 1200);
            await tester.pumpAndSettle();
            expect(
              find.text(t.settings.language).hitTestable(),
              findsOneWidget,
            );
            LocaleSettings.setLocaleSync(AppLocale.ja);
            await tester.pumpAndSettle();
            expect(
              find.text(t.settings.language).hitTestable(),
              findsOneWidget,
            );
            tester.view.physicalSize = Size(width, 1200);
            await tester.pumpAndSettle();
            expect(
              find.text(t.settings.language).hitTestable(),
              findsOneWidget,
            );
            expect(
              identical(
                tester.state(find.byType(FrostSettingsSections)),
                sections,
              ),
              true,
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
  for (final platform in DownloadPlatform.values) {
    testWidgets('download storage follows $platform, not layout width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            booruServiceProvider.overrideWithValue(service),
            downloadPlatformProvider.overrideWithValue(platform),
          ],
          child: browseTestApp(
            const SettingsPage(section: SettingsSection.downloads),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = switch (platform) {
        DownloadPlatform.desktop => t.settings.downloadDirectory,
        DownloadPlatform.android => t.ugoira.androidDestination,
        DownloadPlatform.ios => t.ugoira.iosDestination,
      };
      final row = tester.widget<FrostListRow>(
        find.byWidgetPredicate(
          (widget) => widget is FrostListRow && widget.title == title,
        ),
      );
      if (platform.canChooseDirectory) {
        expect(row.onPressed, isNotNull);
        expect(find.text(t.settingsDetails.change), findsOneWidget);
      } else {
        expect(row.onPressed, isNull);
        expect(row.trailing, isNull);
        expect(row.contextMenu, isEmpty);
        expect(find.text(t.settingsDetails.change), findsNothing);
        // Pointer and right-click have no native picker or process callback.
        await tester.tap(find.text(title));
        await tester.tap(find.text(title), buttons: 2);
        await tester.pumpAndSettle();
        expect(find.text(t.frost.showInFolder), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
