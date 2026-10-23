import 'dart:convert';

import 'package:flutter/services.dart';

class TagTranslationsService {
  TagTranslationsService._();

  static late Map<String, String> _en;

  static late Map<String, String> _ja;

  static late Map<String, String> _zhTW;

  static late Map<String, String> _zhCN;

  static int? _index;

  static Map<String, String>? get _translations => switch (_index) {
    0 => _en,
    1 => _ja,
    2 => _zhTW,
    3 => _zhCN,
    _ => _en,
  };

  static List<String> get knowTags => _en.entries.map((e) => e.key).toList();

  static Future<void> loadAll() async {
    String enJsonString = await rootBundle.loadString(
      'assets/tag_translations/en.json',
    );
    String jaJsonString = await rootBundle.loadString(
      'assets/tag_translations/ja.json',
    );
    String zhTWJsonString = await rootBundle.loadString(
      'assets/tag_translations/zh_TW.json',
    );
    String zhCNJsonString = await rootBundle.loadString(
      'assets/tag_translations/zh_CN.json',
    );
    final Map<String, dynamic> enMap = json.decode(enJsonString);
    final Map<String, dynamic> jaMap = json.decode(jaJsonString);
    final Map<String, dynamic> zhTWMap = json.decode(zhTWJsonString);
    final Map<String, dynamic> zhCNMap = json.decode(zhCNJsonString);
    _en = _validTranslations(enMap);
    _ja = _validTranslations(jaMap);
    _zhTW = _validTranslations(zhTWMap);
    _zhCN = _validTranslations(zhCNMap);
  }

  static void update(int? index) {
    _index = index;
  }

  static String? translate(String tag) {
    return _translations?[tag];
  }

  static bool matchesAnyLanguage(String tag, String query) =>
      [_en, _ja, _zhTW, _zhCN].any(
        (map) => map[tag]?.toLowerCase().contains(query.toLowerCase()) ?? false,
      );
}

// Reject damaged entries before they reach translated-query matching as well
// as display. Unicode letters/numbers preserve CJK and other real translations.
final _translationContent = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _translationPlaceholders = {
  'null',
  'undefined',
  'unknown',
  'n/a',
  'todo',
  'tbd',
  'placeholder',
};
String? validTagTranslation(String? value) {
  final text = value?.trim();
  if (text == null ||
      text.isEmpty ||
      !_translationContent.hasMatch(text) ||
      _translationPlaceholders.contains(text.toLowerCase())) {
    return null;
  }
  return text;
}

Map<String, String> _validTranslations(Map<String, dynamic> values) => {
  for (final entry in values.entries)
    if (entry.value is String)
      entry.key: ?validTagTranslation(entry.value as String),
};

/// Formatting-only differences do not add a second piece of tag information.
String? distinctTagTranslation(String original, String? translation) {
  String normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[_\s]+'), ' ').trim();
  final valid = validTagTranslation(translation);
  return valid == null || normalized(original) == normalized(valid)
      ? null
      : valid;
}
