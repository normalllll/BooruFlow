import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/window/title_bar.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_theme.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/immersive_system_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BooruFlowApp extends ConsumerWidget {
  const BooruFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const darkPrimaryColor = Color(0xFFFF79AD);
    const lightPrimaryColor = AppThemeTokens.brandPink;

    final settings = ref.watch(settingsProvider);
    final appLocale = appLocaleForLanguagePreference(settings.language);
    ref.listen(settingsProvider.select((value) => value.language), (
      _,
      language,
    ) {
      final locale = applyLanguagePreference(language);
      TagTranslationsService.update(
        language ?? languagePreferenceForAppLocale(locale),
      );
    });
    final locale = appLocale.flutterLocale;
    return AppToastWrapper(
      child: MaterialApp.router(
        title: 'BooruFlow',
        routerConfig: AppRouter.router,
        darkTheme: darkTheme(darkPrimaryColor),
        theme: lightTheme(lightPrimaryColor),
        themeMode: switch (settings.themeMode) {
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
      ),
    );
  }
}
