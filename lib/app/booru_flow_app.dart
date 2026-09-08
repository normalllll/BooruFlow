import 'package:booruflow/shared/widgets/immersive_system_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/window/title_bar.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/app_theme.dart';

class BooruFlowApp extends ConsumerWidget {
  const BooruFlowApp({super.key});

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
            title: 'BooruFlow',
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
              return ImmersiveSystemUi(
                child: DesktopWindowFrame(
                  child: GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
