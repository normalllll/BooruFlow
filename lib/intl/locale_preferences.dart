import 'package:booruflow/intl/translations.g.dart';

/// Gives Slang the plural rule it lacks for Chinese, which has one form for
/// every count. English and Japanese use Slang's own rules.
void configurePluralRules() {
  LocaleSettings.setPluralResolverSync(
    language: 'zh',
    cardinalResolver: _single,
    ordinalResolver: _single,
  );
}

String _single(
  num n, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) => other!;

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
