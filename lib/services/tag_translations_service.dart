import 'dart:convert';

import 'package:flutter/services.dart';

class TagTranslationsService {
  TagTranslationsService._();

  static late Map<String, String> _en;

  static late Map<String, String> _ja;

  static late Map<String, String> _zhTW;

  static int? _index;

  static Map<String, String>? get _translations => switch (_index) {
        0 => _en,
        1 => _ja,
        2 => _zhTW,
        _ => _en,
      };

  static List<String> get knowTags  => _en.entries.map((e)=>e.key).toList();

  static Future<void> loadAll() async {
    String enJsonString = await rootBundle.loadString('assets/tag_translations/en.json');
    String jaJsonString = await rootBundle.loadString('assets/tag_translations/ja.json');
    String zhTWJsonString = await rootBundle.loadString('assets/tag_translations/zh_TW.json');
    final Map<String, dynamic> enMap = json.decode(enJsonString);
    final Map<String, dynamic> jaMap = json.decode(jaJsonString);
    final Map<String, dynamic> zhTWMap = json.decode(zhTWJsonString);
    _en = enMap.cast();
    _ja = jaMap.cast();
    _zhTW = zhTWMap.cast();
  }

  static void update(int? index) {
    _index = index;
  }

  static String? translate(String tag) {
    return _translations?[tag];
  }
}
