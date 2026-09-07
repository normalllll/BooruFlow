import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';

enum SuggestionOrigin { sourceApi, sourceCache, lexicon, userAlias, history }

class TagSuggestion {
  const TagSuggestion({
    required this.value,
    this.displayName,
    this.count,
    this.category = TagCategory.general,
    required this.origin,
    this.verified = false,
  });
  final String value;
  final String? displayName;
  final String? count;
  final TagCategory category;
  final SuggestionOrigin origin;
  final bool verified;
  Map<String, Object?> toJson() => {
    'value': value,
    'count': count,
    'category': category.index,
  };
  factory TagSuggestion.fromJson(Map value) => TagSuggestion(
    value: value['value'] as String,
    count: value['count'] as String?,
    category: TagCategory.values[value['category'] as int],
    origin: SuggestionOrigin.sourceCache,
    verified: true,
  );
}

class UserTagAlias {
  static const allSources = '*';

  bool appliesTo(String source) => sourceId == allSources || sourceId == source;

  const UserTagAlias({
    required this.id,
    required this.value,
    required this.sourceId,
    required this.locale,
    this.displayName,
  });
  final String id;
  final String value;
  final String sourceId;
  final String locale;
  final String? displayName;
  Map<String, Object?> toJson() => {
    'id': id,
    'value': value,
    'source': sourceId,
    'locale': locale,
    'display': displayName,
  };
  factory UserTagAlias.fromJson(Map json) => UserTagAlias(
    id: json['id'] as String,
    value: json['value'] as String,
    sourceId: json['source'] as String,
    locale: json['locale'] as String,
    displayName: json['display'] as String?,
  );
}

class TagSuggestionRepository {
  static final instance = TagSuggestionRepository();
  static const ttl = Duration(hours: 24);
  final changes = ValueNotifier<int>(0);
  Box<dynamic>? _box;
  Future<void>? _initializing;
  final _cooldown = <String, DateTime>{};
  final _inFlight = <String, Future<List<TagSuggestion>>>{};
  final _index = <String, Map<String, TagSuggestion>>{};
  List<UserTagAlias> get aliases => (_box?.get('aliases') as List? ?? [])
      .whereType<Map>()
      .map(UserTagAlias.fromJson)
      .toList();
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    _box = await Hive.openBox<dynamic>('discovery_tags');
    final invalid = <dynamic>[];
    for (final key in _box!.keys) {
      final value = _box!.get(key);
      final valid = switch (key) {
        'aliases' => value is List && value.every(_validAlias),
        String key when key.startsWith('cache:') =>
          value is Map &&
              value['time'] is int &&
              value['items'] is List &&
              (value['items'] as List).every(_validTag),
        String key when key.startsWith('index:') =>
          value is List && value.every(_validTag),
        String key when key.startsWith('history:') =>
          value is List && value.every((item) => item is String),
        _ => false,
      };
      if (!valid) invalid.add(key);
    }
    await _box!.deleteAll(invalid);
  }

  static bool _validTag(dynamic value) =>
      value is Map &&
      value['value'] is String &&
      value['category'] is int &&
      (value['category'] as int) >= 0 &&
      (value['category'] as int) < TagCategory.values.length &&
      (value['count'] == null || value['count'] is String);

  static bool _validAlias(dynamic value) =>
      value is Map &&
      ['id', 'value', 'source', 'locale'].every(
        (key) => value[key] is String && (value[key] as String).isNotEmpty,
      ) &&
      (value['display'] == null || value['display'] is String);

  Future<void> saveAlias(UserTagAlias alias) async {
    await initialize();
    final list = aliases.where((a) => a.id != alias.id).toList()..add(alias);
    await _box!.put('aliases', list.map((a) => a.toJson()).toList());
    changes.value++;
  }

  Future<void> deleteAlias(String id) async {
    await initialize();
    await _box!.put(
      'aliases',
      aliases.where((a) => a.id != id).map((a) => a.toJson()).toList(),
    );
    changes.value++;
  }

  String? displayName(String source, String locale, String value) {
    final matches = aliases.where(
      (a) => a.value == value && a.appliesTo(source) && a.locale == locale,
    );
    return matches.where((a) => a.sourceId == source).lastOrNull?.displayName ??
        matches
            .where((a) => a.sourceId == UserTagAlias.allSources)
            .lastOrNull
            ?.displayName ??
        TagTranslationsService.translate(value);
  }

  String _scope(String source) =>
      '$source:${BooruService.instance.cacheRevision(source)}';
  String _key(String source, String locale, String prefix) =>
      jsonEncode([_scope(source), locale, prefix.toLowerCase()]);
  List<TagSuggestion> local(String source, String locale, String text) {
    final needle = text.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final suggestions = <TagSuggestion>[];
    bool matches(String value, String? display) =>
        value.toLowerCase().contains(needle) ||
        (display?.toLowerCase().contains(needle) ?? false);
    final scope = _scope(source);
    final cachedTags = _index.putIfAbsent(
      scope,
      () => {
        for (final value
            in (_box?.get('index:$scope') as List? ?? []).whereType<Map>())
          (value['value'] as String): TagSuggestion.fromJson(value),
      },
    );
    for (final item in cachedTags.values) {
      if (matches(item.value, displayName(source, locale, item.value))) {
        suggestions.add(item);
      }
    }
    for (final alias in aliases.where(
      (a) => a.appliesTo(source) && a.locale == locale,
    )) {
      if (matches(alias.value, alias.displayName)) {
        suggestions.add(
          TagSuggestion(
            value: alias.value,
            displayName: alias.displayName,
            origin: SuggestionOrigin.userAlias,
          ),
        );
      }
    }
    for (final value
        in (_box?.get('history:$source') as List? ?? []).whereType<String>()) {
      final display = displayName(source, locale, value);
      if (matches(value, display)) {
        suggestions.add(
          TagSuggestion(
            value: value,
            displayName: display,
            origin: SuggestionOrigin.history,
          ),
        );
      }
    }
    for (final tag in TagTranslationsService.knowTags) {
      final display = displayName(source, locale, tag);
      if (matches(tag, display) ||
          TagTranslationsService.matchesAnyLanguage(tag, needle)) {
        suggestions.add(
          TagSuggestion(
            value: tag,
            displayName: display,
            origin: SuggestionOrigin.lexicon,
          ),
        );
      }
    }
    final cached = _read(_key(source, locale, needle), allowStale: true);
    suggestions.addAll(cached ?? []);
    return merge(source, locale, needle, suggestions);
  }

  List<TagSuggestion> merge(
    String source,
    String locale,
    String text,
    Iterable<TagSuggestion> suggestions,
  ) {
    final unique = <String, TagSuggestion>{};
    for (final item in suggestions) {
      final old = unique[item.value];
      if (old == null || item.verified && !old.verified) {
        unique[item.value] = item;
      }
    }
    final needle = text.toLowerCase();
    int rank(TagSuggestion item) {
      final value = item.value.toLowerCase();
      final display = displayName(source, locale, item.value)?.toLowerCase();
      if (value == needle) return 0;
      if (display == needle) return 1;
      if (value.startsWith(needle)) return 2;
      if (display?.startsWith(needle) ?? false) return 3;
      return 4;
    }

    final indexed = unique.values.toList().asMap().entries.toList()
      ..sort((a, b) {
        final comparison = rank(a.value).compareTo(rank(b.value));
        return comparison == 0 ? a.key.compareTo(b.key) : comparison;
      });
    return indexed.take(40).map((e) {
      final item = e.value;
      return TagSuggestion(
        value: item.value,
        displayName:
            displayName(source, locale, item.value) ?? item.displayName,
        count: item.count,
        category: item.category,
        origin: item.origin,
        verified: item.verified,
      );
    }).toList();
  }

  Future<List<TagSuggestion>> remote(
    String source,
    String locale,
    String text,
  ) async {
    await initialize();
    final prefix = text.trim();
    final caps = BooruService.instance.sourceById(source).capabilities;
    if (prefix.isEmpty ||
        prefix.runes.length < caps.discovery.autocompleteMinChars ||
        !caps.supportsAutocomplete ||
        prefix.contains(':')) {
      return [];
    }
    final key = _key(source, locale, prefix);
    final cached = _read(key);
    if (cached != null) return cached;
    if (_cooldown[source]?.isAfter(DateTime.now()) ?? false) {
      return _read(key, allowStale: true) ?? [];
    }
    return _inFlight.putIfAbsent(key, () async {
      try {
        final values = await BooruService.instance.engine.autocomplete(
          sourceId: source,
          text: prefix,
        );
        final result = values
            .map(
              (v) => TagSuggestion(
                value: v.value,
                displayName: v.label,
                count: v.postCountDecimal,
                category: v.category,
                origin: SuggestionOrigin.sourceApi,
                verified: true,
              ),
            )
            .toList();
        await _write(key, result);
        return result;
      } on BooruErrorDto catch (e) {
        if (e.code == BooruErrorCode.rateLimited) {
          _cooldown[source] = DateTime.now().add(
            Duration(seconds: e.retryAfterSeconds ?? 60),
          );
        }
        rethrow;
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  Future<List<TagSuggestion>> common(
    String source,
    String locale, {
    bool refresh = false,
    int page = 1,
  }) async {
    await initialize();
    final key = _key(source, locale, '#common:$page');
    if (!refresh) {
      final cached = _read(key);
      if (cached != null) return cached;
    }
    if (BooruService.instance
            .sourceById(source)
            .capabilities
            .discovery
            .commonTags ==
        CapabilityAvailability.unsupported) {
      return [];
    }
    try {
      final result = await BooruService.instance.engine.commonTags(
        request: CommonTagsRequestDto(
          sourceId: source,
          page: page,
          pageSize: 50,
        ),
      );
      final tags = result.items
          .map(
            (v) => TagSuggestion(
              value: v.value,
              count: v.postCountDecimal,
              category: v.category,
              origin: SuggestionOrigin.sourceApi,
              verified: true,
            ),
          )
          .toList();
      await _write(key, tags);
      return tags;
    } catch (_) {
      final cached = _read(key, allowStale: true);
      if (cached != null) return cached;
      rethrow;
    }
  }

  List<TagSuggestion>? _read(String key, {bool allowStale = false}) {
    final data = _box?.get('cache:$key');
    if (data is! Map) return null;
    if (!allowStale &&
        DateTime.now().millisecondsSinceEpoch - (data['time'] as int) >
            ttl.inMilliseconds) {
      return null;
    }
    return (data['items'] as List)
        .whereType<Map>()
        .map(TagSuggestion.fromJson)
        .toList();
  }

  Future<void> _write(String key, List<TagSuggestion> values) async {
    final scope = (jsonDecode(key) as List).first as String;
    final index = _index.putIfAbsent(
      scope,
      () => {
        for (final value
            in (_box?.get('index:$scope') as List? ?? []).whereType<Map>())
          (value['value'] as String): TagSuggestion.fromJson(value),
      },
    );
    for (final value in values) {
      index.remove(value.value);
      index[value.value] = value;
    }
    while (index.length > 20000) {
      index.remove(index.keys.first);
    }
    await _box!.put(
      'index:$scope',
      index.values.map((value) => value.toJson()).toList(),
    );
    await _box!.put('cache:$key', {
      'time': DateTime.now().millisecondsSinceEpoch,
      'items': values.map((v) => v.toJson()).toList(),
    });
    // 700 prefix responses × at most 20 suggestions normally; bound disk and memory.
    final keys = _box!.keys
        .whereType<String>()
        .where((k) => k.startsWith('cache:'))
        .toList();
    if (keys.length > 700) {
      keys.sort(
        (a, b) => ((_box!.get(a) as Map)['time'] as int).compareTo(
          (_box!.get(b) as Map)['time'] as int,
        ),
      );
      await _box!.deleteAll(keys.take(keys.length - 700));
    }
    // Old authentication namespaces must not accumulate indefinitely.
    final indices = _box!.keys
        .whereType<String>()
        .where((key) => key.startsWith('index:'))
        .toList();
    if (indices.length > 14) {
      for (final old
          in indices
              .where((old) => old != 'index:$scope')
              .take(indices.length - 14)) {
        await _box!.delete(old);
        _index.remove(old.substring(6));
      }
    }
  }

  Future<void> remember(String source, List<String> tags) async {
    await initialize();
    final old = (_box!.get('history:$source') as List? ?? [])
        .whereType<String>();
    await _box!.put('history:$source', {...tags, ...old}.take(200).toList());
  }
}
