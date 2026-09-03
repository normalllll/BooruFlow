import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yande_gui/components/download_floating_window/download_floating_window.dart';
import 'package:yande_gui/features/downloads/application/yande_download_controller.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/intl/locale_preferences.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/router/app_router.dart';
import 'package:yande_gui/services/app_http_overrides.dart';
import 'package:yande_gui/services/app_toast.dart';
import 'package:yande_gui/services/custom_tags_service.dart';
import 'package:yande_gui/services/tag_translations_service.dart';
import 'package:yande_gui/services/yande_network_policy.dart';
import 'package:yande_gui/src/rust/frb_generated.dart';
import 'package:yande_gui/themes.dart';

import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();
  await RustLib.init();
  final packageInfo = await PackageInfo.fromPlatform();
  Global.appVersion = packageInfo.version;
  Global.buildNumber = packageInfo.buildNumber;
  await Hive.initFlutter();
  await SettingsService.initialize();
  await applyYandeNetworkSettings();
  final appLocale = applyLanguagePreference(SettingsService.language);
  await CustomTagsService.initialize();
  await TagTranslationsService.loadAll();
  TagTranslationsService.update(
    SettingsService.language ?? languagePreferenceForAppLocale(appLocale),
  );
  await YandeDownloadController.instance.initialize();
  runApp(TranslationProvider(child: const ProviderScope(child: MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const darkPrimaryColor = Color(0xFFFF79AD);
    const lightPrimaryColor = AppThemeTokens.brandPink;

    return AppToastWrapper(
      child: StreamBuilder(
        stream: rootUpdateController.stream,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          final appLocale = appLocaleForLanguagePreference(
            SettingsService.language,
          );
          final locale = appLocale.flutterLocale;
          TagTranslationsService.update(
            SettingsService.language ??
                languagePreferenceForAppLocale(appLocale),
          );
          return MaterialApp.router(
            title: 'Yande GUI',
            routerConfig: AppRouter.router,
            darkTheme: darkTheme(darkPrimaryColor),
            theme: lightTheme(lightPrimaryColor),
            themeMode: switch (SettingsService.themeMode) {
              null => ThemeMode.system,
              0 => ThemeMode.light,
              1 => ThemeMode.dark,
              _ => ThemeMode.system,
            },
            locale: locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocaleUtils.supportedLocales,
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode &&
                    supportedLocale.countryCode == locale?.countryCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: DownloadFloatingWindow(
                  onTaskTap: AppRouter.openPost,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
