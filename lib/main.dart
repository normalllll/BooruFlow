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
import 'package:yande_gui/themes.dart';

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

    return StreamBuilder(
      stream: rootUpdateController.stream,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        final locale = I18n.getLocale(SettingsService.language);
        TagTranslationsService.update(SettingsService.language ?? I18n.getSystemLocaleIndex());
        I18n.update(locale);
        return MaterialApp(
          title: 'Yande GUI',
          home: IndexPage(language: SettingsService.language),
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
