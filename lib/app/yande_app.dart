import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/app/app_router.dart';
import 'package:yande_gui/core/app_runtime.dart';
import 'package:yande_gui/core/settings_service.dart';
import 'package:yande_gui/features/tags/tag_translations_service.dart';
import 'package:yande_gui/intl/locale_preferences.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/shared/app_toast.dart';
import 'package:yande_gui/shared/app_theme.dart';

class YandeApp extends ConsumerWidget {
  const YandeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const darkPrimaryColor = Color(0xFFFF79AD);
    const lightPrimaryColor = AppThemeTokens.brandPink;

    return AppToastWrapper(
      child: ValueListenableBuilder<int>(
        valueListenable: appSettingsRevision,
        builder: (context, revision, child) {
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
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
