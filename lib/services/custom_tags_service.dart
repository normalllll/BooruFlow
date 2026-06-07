import 'package:hive_ce_flutter/hive_flutter.dart';

class CustomTagsService {
  CustomTagsService._();

  static const _boxName = 'custom_tags';
  static const _tagsKey = 'postSearchTags';
  static const _translationsKey = 'postSearchTagTranslations';

  static final RegExp _whitespacePattern = RegExp(r'\s');
  static final List<String> _tags = [];
  static final Map<String, String> _translations = {};
  static Box<dynamic>? _box;
  static Future<void>? _initializing;
  static bool _initialized = false;

  static List<String> get tags => List.unmodifiable(_tags);

  static bool contains(String tag) {
    final normalizedTag = _normalize(tag);
    return normalizedTag != null && _tags.contains(normalizedTag);
  }

  static String? translate(String tag) {
    final normalizedTag = _normalize(tag);
    return normalizedTag == null ? null : _translations[normalizedTag];
  }

  static Future<void> initialize() {
    if (_initialized) {
      return Future.value();
    }

    return _initializing ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<dynamic>(_boxName);
      _replaceInMemory(_readTags(_activeBox.get(_tagsKey)));
      _replaceTranslations(_readTranslations(_activeBox.get(_translationsKey)));
      _initialized = true;
    } finally {
      if (!_initialized) {
        _initializing = null;
      }
    }
  }

  static List<String> parseInput(String input) {
    return input
        .split(RegExp(r'\s+'))
        .map(_normalize)
        .whereType<String>()
        .toList(growable: false);
  }

  static Future<bool> add(String tag, {String? translation}) async {
    await initialize();

    final normalizedTag = _normalize(tag);
    if (normalizedTag == null ||
        _whitespacePattern.hasMatch(normalizedTag) ||
        _tags.contains(normalizedTag)) {
      return false;
    }

    _tags.add(normalizedTag);
    final normalizedTranslation = _normalizeTranslation(translation);
    if (normalizedTranslation != null) {
      _translations[normalizedTag] = normalizedTranslation;
    }

    await save();
    return true;
  }

  static Future<bool> addAll(Iterable<String> tags) async {
    await initialize();

    var changed = false;
    for (final tag in tags) {
      final normalizedTag = _normalize(tag);
      if (normalizedTag == null ||
          _whitespacePattern.hasMatch(normalizedTag) ||
          _tags.contains(normalizedTag)) {
        continue;
      }
      _tags.add(normalizedTag);
      changed = true;
    }

    if (changed) {
      await save();
    }
    return changed;
  }

  static Future<bool> addFromInput(String input) {
    return addAll(parseInput(input));
  }

  static Future<bool> remove(String tag) async {
    await initialize();

    final normalizedTag = _normalize(tag);
    if (normalizedTag == null || !_tags.remove(normalizedTag)) {
      return false;
    }

    _translations.remove(normalizedTag);
    await save();
    return true;
  }

  static Future<bool> clear() async {
    await initialize();

    if (_tags.isEmpty && _translations.isEmpty) {
      return false;
    }

    _tags.clear();
    _translations.clear();
    await save();
    return true;
  }

  static Future<void> save() async {
    await initialize();
    await _activeBox.put(_tagsKey, List<String>.of(_tags));
    if (_translations.isEmpty) {
      await _activeBox.delete(_translationsKey);
    } else {
      await _activeBox.put(
        _translationsKey,
        Map<String, String>.of(_translations),
      );
    }
  }

  static List<String> _readTags(dynamic value) {
    if (value is! Iterable) {
      return const [];
    }

    return value.whereType<String>().toList(growable: false);
  }

  static Map<String, String> _readTranslations(dynamic value) {
    if (value is! Map) {
      return const {};
    }

    final translations = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final translation = entry.value;
      if (key is String && translation is String) {
        translations[key] = translation;
      }
    }
    return translations;
  }

  static void _replaceInMemory(Iterable<String> tags) {
    _tags
      ..clear()
      ..addAll({...tags.map(_normalize).whereType<String>()});
  }

  static void _replaceTranslations(Map<String, String> translations) {
    _translations.clear();
    for (final entry in translations.entries) {
      final normalizedTag = _normalize(entry.key);
      final normalizedTranslation = _normalizeTranslation(entry.value);
      if (normalizedTag != null &&
          normalizedTranslation != null &&
          _tags.contains(normalizedTag)) {
        _translations[normalizedTag] = normalizedTranslation;
      }
    }
  }

  static String? _normalize(String tag) {
    final normalizedTag = tag.trim();
    return normalizedTag.isEmpty ? null : normalizedTag;
  }

  static String? _normalizeTranslation(String? translation) {
    final normalizedTranslation = translation?.trim();
    return normalizedTranslation == null || normalizedTranslation.isEmpty
        ? null
        : normalizedTranslation;
  }

  static Box<dynamic> get _activeBox {
    final box = _box;
    if (box == null) {
      throw StateError(
        'CustomTagsService.initialize() must be called before reading custom tags.',
      );
    }
    return box;
  }
}
