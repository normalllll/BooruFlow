import 'dart:async';

import 'package:booruflow/core/async_content.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

@Riverpod(keepAlive: true)
TagSuggestionRepository tagSuggestionRepository(Ref ref) =>
    TagSuggestionRepository.instance;

class SearchSession {
  SearchSession({
    required this.locale,
    required this.followSource,
    this.sourceId,
    this.initialQuery = '',
    this.repository,
  });
  final String locale, initialQuery;
  final String? sourceId;
  final bool followSource;
  final TagSuggestionRepository? repository;
}

class SearchState {
  SearchState({
    required this.sourceId,
    required this.locale,
    this.invalidSource = false,
    this.initialization = const AsyncLoading<void>(),
    this.suggestions = const AsyncContent<List<TagSuggestion>>([]),
    this.common = const AsyncContent<List<TagSuggestion>>([]),
    Set<String> verified = const {},
    Map<String, String> labels = const {},
  }) : verified = Set.unmodifiable(verified),
       labels = Map.unmodifiable(labels);
  final String sourceId, locale;
  final bool invalidSource;
  final AsyncValue<void> initialization;
  final AsyncContent<List<TagSuggestion>> suggestions, common;
  final Set<String> verified;
  final Map<String, String> labels;
  bool get ready => initialization is AsyncData<void>;
  SearchState copyWith({
    String? sourceId,
    String? locale,
    AsyncValue<void>? initialization,
    AsyncContent<List<TagSuggestion>>? suggestions,
    AsyncContent<List<TagSuggestion>>? common,
    Set<String>? verified,
    Map<String, String>? labels,
  }) => SearchState(
    sourceId: sourceId ?? this.sourceId,
    locale: locale ?? this.locale,
    invalidSource: invalidSource,
    initialization: initialization ?? this.initialization,
    suggestions: suggestions ?? this.suggestions,
    common: common ?? this.common,
    verified: verified ?? this.verified,
    labels: labels ?? this.labels,
  );
}

@riverpod
class Search extends _$Search {
  Timer? _debounce;
  int _generation = 0, _commonGeneration = 0;
  String _query = '';
  int _caret = 0;
  ({String source, String locale, String text, bool composing, bool ready})?
  _suggestionRequest;
  bool _composing = false;
  TagSuggestionRepository get repository =>
      session.repository ?? ref.read(tagSuggestionRepositoryProvider);
  @override
  SearchState build(SearchSession session) {
    final service = ref.read(booruServiceProvider);
    final initial = session.sourceId ?? ref.read(booruSessionProvider).sourceId;
    final valid = service.sources.any((source) => source.sourceId == initial);
    _query = session.initialQuery;
    _caret = _query.length;
    _suggestionRequest = null;
    ref.onDispose(() {
      _generation++;
      _commonGeneration++;
      _debounce?.cancel();
    });
    ref.listen(booruSessionProvider, (previous, next) {
      if (session.followSource && next.sourceId != state.sourceId) {
        switchSource(next.sourceId, publish: false);
      }
      if (previous?.revision != next.revision) {
        state = state.copyWith(verified: {});
        queryChanged(
          _query,
          composing: _composing,
          caretOffset: _caret,
          refresh: true,
        );
        loadCommon();
      }
    });
    final changes = repository.changes.listen((_) {
      if (!ref.mounted || !state.ready) return;
      queryChanged(
        _query,
        composing: _composing,
        caretOffset: _caret,
        refresh: true,
      );
      loadCommon();
    });
    ref.onDispose(changes.cancel);
    Future.microtask(_initialize);
    return SearchState(
      sourceId: valid ? initial : service.selectedSourceId,
      locale: session.locale,
      invalidSource: !valid,
    );
  }

  Future<void> _initialize() async {
    try {
      await repository.initialize();
      if (!ref.mounted) return;
      state = state.copyWith(initialization: const AsyncData<void>(null));
      queryChanged(
        _query,
        composing: _composing,
        caretOffset: _caret,
        refresh: true,
      );
      loadCommon();
    } catch (error, stack) {
      if (ref.mounted) {
        state = state.copyWith(initialization: AsyncError(error, stack));
      }
    }
  }

  void setLocale(String locale) {
    if (state.locale == locale) return;
    state = state.copyWith(locale: locale);
    queryChanged(_query, composing: _composing, caretOffset: _caret);
    loadCommon();
  }

  void switchSource(String source, {bool publish = true}) {
    if (!ref
        .read(booruServiceProvider)
        .sources
        .any((item) => item.sourceId == source)) {
      return;
    }
    if (state.sourceId == source) return;
    state = state.copyWith(
      sourceId: source,
      verified: {},
      suggestions: const AsyncContent([]),
      common: const AsyncContent([]),
    );
    if (publish && session.followSource) {
      ref.read(booruSessionProvider.notifier).selectSource(source);
    }
    queryChanged(_query, composing: _composing, caretOffset: _caret);
    loadCommon();
  }

  void queryChanged(
    String query, {
    required bool composing,
    int? caretOffset,
    bool refresh = false,
  }) {
    _query = query;
    _caret = (caretOffset ?? query.length).clamp(0, query.length);
    _composing = composing;
    final span = querySpanAt(query, _caret);
    final text = span == null
        ? ''
        : QueryTerm.parse(query.substring(span.start, _caret)).value;
    final source = state.sourceId, locale = state.locale;
    final request = (
      source: source,
      locale: locale,
      text: text,
      composing: composing,
      ready: state.ready,
    );
    if (!refresh && _suggestionRequest == request) return;
    _suggestionRequest = request;
    _debounce?.cancel();
    final generation = ++_generation;
    final local = state.ready && !composing && text.isNotEmpty
        ? repository.local(source, locale, text)
        : <TagSuggestion>[];
    final eligible = state.ready && !composing && text.isNotEmpty;
    state = state.copyWith(
      suggestions: AsyncContent(
        local,
        operation: eligible
            ? const AsyncLoading<void>()
            : const AsyncData<void>(null),
      ),
    );
    if (!eligible) return;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(suggestions: state.suggestions.loading());
      try {
        final remote = await repository.remote(source, locale, text);
        if (!ref.mounted || generation != _generation) return;
        state = state.copyWith(
          suggestions: AsyncContent(
            repository.merge(source, locale, text, [...remote, ...local]),
          ),
        );
      } catch (error, stack) {
        if (ref.mounted && generation == _generation) {
          state = state.copyWith(
            suggestions: AsyncContent(local).failed(error, stack),
          );
        }
      }
    });
  }

  Future<void> loadCommon({bool refresh = false}) async {
    if (!state.ready) return;
    final generation = ++_commonGeneration;
    final previous = state.common;
    final source = state.sourceId, locale = state.locale;
    state = state.copyWith(common: previous.loading());
    try {
      final values = await repository.common(source, locale, refresh: refresh);
      if (ref.mounted && generation == _commonGeneration) {
        state = state.copyWith(common: AsyncContent(values));
      }
    } catch (error, stack) {
      if (ref.mounted && generation == _commonGeneration) {
        state = state.copyWith(common: previous.failed(error, stack));
      }
    }
  }

  String displayName(String raw, [String? fallback]) {
    final value = QueryTerm.parse(raw).value;
    final candidate =
        repository.displayName(state.sourceId, state.locale, value) ??
        state.labels['${state.sourceId}:$raw'] ??
        fallback;
    return distinctTagTranslation(value, candidate) ?? raw;
  }

  void recordTag(TagSuggestion tag) => state = state.copyWith(
    verified: {...state.verified, if (tag.verified) tag.value},
    labels: {
      ...state.labels,
      '${state.sourceId}:${tag.value}': ?tag.displayName,
    },
  );

  Future<void> remember(List<String> tags) =>
      repository.remember(state.sourceId, tags);
}

@Riverpod(keepAlive: true)
class UserTags extends _$UserTags {
  @override
  Future<List<UserTagAlias>> build() async {
    final repository = ref.watch(tagSuggestionRepositoryProvider);
    final subscription = repository.changes.listen((_) => ref.invalidateSelf());
    ref.onDispose(subscription.cancel);
    await repository.initialize();
    return List.unmodifiable(repository.aliases);
  }

  Future<void> save(UserTagAlias alias) =>
      ref.read(tagSuggestionRepositoryProvider).saveAlias(alias);
  Future<void> delete(String id) =>
      ref.read(tagSuggestionRepositoryProvider).deleteAlias(id);
}

@riverpod
class SearchHistory extends _$SearchHistory {
  @override
  Future<List<String>> build(
    TagSuggestionRepository repository,
    String source,
  ) => repository.recentSearches(source);
  Future<void> removeQuery(String query) async {
    try {
      await repository.removeSearch(source, query);
      if (ref.mounted) ref.invalidateSelf();
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }

  Future<void> clearQueries() async {
    try {
      await repository.clearSearches(source);
      if (ref.mounted) ref.invalidateSelf();
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }
}
