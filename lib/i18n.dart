import 'package:flutter/widgets.dart';
import 'package:yande_gui/intl/translations.g.dart';

class I18n {
  I18n._();

  static Translations _current = AppLocale.en.buildSync();

  static void update(Locale locale) {
    LocaleSettings.setLocaleSync(_appLocaleOf(locale));
    _current = LocaleSettings.instance.currentTranslations;
  }

  static List<Locale> get supportedLocales => AppLocaleUtils.supportedLocales;

  static Locale getLocale(int? index) {
    return _appLocaleOfIndex(index).flutterLocale;
  }

  static int? getSystemLocaleIndex() {
    return _indexOfAppLocale(
      _appLocaleOf(WidgetsBinding.instance.platformDispatcher.locale),
    );
  }

  static AppLocale _appLocaleOfIndex(int? index) {
    return switch (index) {
      null => _appLocaleOf(WidgetsBinding.instance.platformDispatcher.locale),
      0 => AppLocale.en,
      1 => AppLocale.ja,
      2 => AppLocale.zhTw,
      3 => AppLocale.zhCn,
      _ => AppLocale.en,
    };
  }

  static AppLocale _appLocaleOf(Locale locale) {
    return switch (locale.languageCode) {
      'en' => AppLocale.en,
      'ja' => AppLocale.ja,
      'zh' => _chineseAppLocaleOf(locale),
      _ => AppLocale.en,
    };
  }

  static AppLocale _chineseAppLocaleOf(Locale locale) {
    return switch ((locale.scriptCode, locale.countryCode)) {
      ('Hant', _) || (_, 'TW') || (_, 'HK') || (_, 'MO') => AppLocale.zhTw,
      _ => AppLocale.zhCn,
    };
  }

  static int? _indexOfAppLocale(AppLocale locale) {
    return switch (locale) {
      AppLocale.en => 0,
      AppLocale.ja => 1,
      AppLocale.zhTw => 2,
      AppLocale.zhCn => 3,
    };
  }
}

Translations get i18n => I18n._current;
