import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/services/tag_translations_service.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';
import 'package:yande_gui/src/rust/frb_generated.dart';

import 'pages/index/index_page.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final packageInfo = await PackageInfo.fromPlatform();
  Global.appVersion = packageInfo.version;
  Global.buildNumber = packageInfo.buildNumber;
  await SettingsService.initialize();
  await TagTranslationsService.loadAll();
  TagTranslationsService.update(SettingsService.language);
  if (!SettingsService.prefetchDns) {
    setYandeClient(YandeClient(ips: null, forLargeFile: false));
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const darkPrimaryColor = Color(0xfff175a9);
    const lightPrimaryColor = Color(0xffef83be);
    const secondaryColor = Color(0xff28a4ff);

    return StreamBuilder(
      stream: rootUpdateController.stream,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        final locale = I18n.getLocale(SettingsService.language);
        TagTranslationsService.update(SettingsService.language ?? I18n.getSystemLocaleIndex());
        I18n.update(locale);
        return MaterialApp(
          title: 'Yande GUI',
          home: IndexPage(language: SettingsService.language),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: darkPrimaryColor,
            useMaterial3: true,
            colorScheme: const ColorScheme.dark(
              primary: darkPrimaryColor,
              secondary: secondaryColor,
              surface: Color.fromARGB(255, 26, 26, 26),
              onSurface: Color.fromARGB(255, 216, 216, 216),
            ),
            scaffoldBackgroundColor: const Color(0xff1c1c1c),
            inputDecorationTheme: const InputDecorationTheme(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              fillColor: Color.fromARGB(255, 32, 35, 39),
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 113, 117, 123),
              ),
            ),
            navigationRailTheme: const NavigationRailThemeData(
              indicatorColor: darkPrimaryColor,
            ),
            cardTheme: const CardTheme(
              color: Color(0xff181818),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: darkPrimaryColor,
              unselectedItemColor: Color.fromARGB(255, 216, 216, 216),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 15)),
              ),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              linearTrackColor: Color(0xff181818),
            ),
          ),
          theme: ThemeData(
            primaryColor: lightPrimaryColor,
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: lightPrimaryColor,
              secondary: secondaryColor,
              surface: Color(0xffffffff),
              onSurface: Color.fromARGB(255, 16, 19, 24),
            ),
            scaffoldBackgroundColor: const Color(0xfff0f0f0),
            inputDecorationTheme: const InputDecorationTheme(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              fillColor: Color.fromARGB(255, 239, 242, 244),
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 86, 99, 112),
              ),
            ),
            navigationRailTheme: const NavigationRailThemeData(
              indicatorColor: lightPrimaryColor,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: lightPrimaryColor,
              unselectedItemColor: Color.fromARGB(255, 16, 19, 24),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 15)),
                minimumSize: WidgetStateProperty.all(const Size(20, 35)),
              ),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              linearTrackColor: Color(0xffffffff),
            ),
          ),
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
          supportedLocales: const [
            Locale('en'),
            Locale('ja'),
            Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode && supportedLocale.countryCode == locale?.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(
            builder: (context, child) {
              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}
