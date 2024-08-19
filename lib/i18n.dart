import 'package:flutter/widgets.dart';
import 'package:yande_gui/intl/intl.i18n.dart';
import 'package:yande_gui/intl/intl_ja.i18n.dart';
import 'package:yande_gui/intl/intl_zh_TW.i18n.dart';

class I18n {
  I18n._();

  static Intl _current = const Intl();

  static void update(Locale locale) {
    _current = switch (locale.languageCode) {
      'en' => const Intl(),
      'ja' => const IntlJa(),
      'zh' => const IntlZhTW(),
      _ => const Intl(),
    };
  }

  static Locale getLocale(int? index) {
    return switch (index) {
      null => WidgetsBinding.instance.platformDispatcher.locale,
      0 => const Locale('en'),
      1 => const Locale('ja'),
      2 => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
      _ => const Locale('en'),
    };
  }
}

Intl get i18n => I18n._current;
