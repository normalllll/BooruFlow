import 'package:booruflow/intl/translations.g.dart';

AppLocale appLocaleForLanguagePreference(int? language) {
  return switch (language) {
    null => AppLocaleUtils.findDeviceLocale(),
    0 => AppLocale.en,
    1 => AppLocale.ja,
    2 => AppLocale.zhTw,
    3 => AppLocale.zhCn,
    _ => AppLocale.en,
  };
}

AppLocale applyLanguagePreference(int? language) {
  if (language == null) {
    return LocaleSettings.useDeviceLocaleSync();
  }
  return LocaleSettings.setLocaleSync(appLocaleForLanguagePreference(language));
}

int languagePreferenceForAppLocale(AppLocale locale) {
  return switch (locale) {
    AppLocale.en => 0,
    AppLocale.ja => 1,
    AppLocale.zhTw => 2,
    AppLocale.zhCn => 3,
  };
}
