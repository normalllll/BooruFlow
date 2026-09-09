import 'dart:async';

import 'package:booruflow/core/async_content.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
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
    this.initialTags = const [],
    this.initialQuery = '',
    this.repository,
  });
  final String locale, initialQuery;
  final String? sourceId;
  final bool followSource;
  final List<String> initialTags;
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
    List<String> selected = const [],
    Set<String> verified = const {},
    Map<String, String> labels = const {},
  }) : selected = List.unmodifiable(selected),
       verified = Set.unmodifiable(verified),
       labels = Map.unmodifiable(labels);
  final String sourceId, locale;
  final bool invalidSource;
  final AsyncValue<void> initialization;
  final AsyncContent<List<TagSuggestion>> suggestions, common;
  final List<String> selected;
  final Set<String> verified;
  final Map<String, String> labels;
  bool get ready => initialization is AsyncData<void>;
  SearchState copyWith({
    String? sourceId,
    String? locale,
    AsyncValue<void>? initialization,
    AsyncContent<List<TagSuggestion>>? suggestions,
    AsyncContent<List<TagSuggestion>>? common,
    List<String>? selected,
    Set<String>? verified,
    Map<String, String>? labels,
  }) => SearchState(
    sourceId: sourceId ?? this.sourceId,
    locale: locale ?? this.locale,
    invalidSource: invalidSource,
    initialization: initialization ?? this.initialization,
    suggestions: suggestions ?? this.suggestions,
    common: common ?? this.common,
    selected: selected ?? this.selected,
    verified: verified ?? this.verified,
    labels: labels ?? this.labels,
  );
}

@riverpod
class Search extends _$Search {
  Timer? _debounce;
  int _generation = 0, _commonGeneration = 0;
  String _query = '';
  bool _composing = false;
  TagSuggestionRepository get repository =>
      session.repository ?? ref.read(tagSuggestionRepositoryProvider);
  @override
  SearchState build(SearchSession session) {
    final service = ref.read(booruServiceProvider);
    final initial = session.sourceId ?? ref.read(booruSessionProvider).sourceId;
    final valid = service.sources.any((source) => source.sourceId == initial);
    _query = session.initialQuery;
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
        queryChanged(_query, composing: _composing);
        loadCommon();
      }
    });
    final changes = repository.changes.listen((_) {
      if (!ref.mounted || !state.ready) return;
      queryChanged(_query, composing: _composing);
      loadCommon();
    });
    ref.onDispose(changes.cancel);
    Future.microtask(_initialize);
    return SearchState(
      sourceId: valid ? initial : service.selectedSourceId,
      locale: session.locale,
      invalidSource: !valid,
      selected: session.initialTags,
    );
  }

  Future<void> _initialize() async {
    try {
      await repository.initialize();
      if (!ref.mounted) return;
      state = state.copyWith(initialization: const AsyncData<void>(null));
      queryChanged(_query, composing: _composing);
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
    queryChanged(_query, composing: _composing);
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
    queryChanged(_query, composing: _composing);
    loadCommon();
  }

  void queryChanged(String query, {required bool composing}) {
    _query = query;
    _composing = composing;
    _debounce?.cancel();
    final generation = ++_generation;
    final text = QueryTerm.parse(parseQueryInput(query).lastOrNull ?? '').value;
    final source = state.sourceId, locale = state.locale;
    final local = state.ready && !composing && text.isNotEmpty
        ? repository.local(source, locale, text)
        : <TagSuggestion>[];
    state = state.copyWith(suggestions: AsyncContent(local));
    if (!state.ready || composing || text.isEmpty) return;
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

  String displayName(String raw, [String? fallback]) =>
      repository.displayName(
        state.sourceId,
        state.locale,
        QueryTerm.parse(raw).value,
      ) ??
      state.labels['${state.sourceId}:$raw'] ??
      fallback ??
      raw;
  void add(TagSuggestion tag, String input, {bool replaceTerm = false}) {
    final terms = parseQueryInput(input);
    final operator = replaceTerm && terms.isNotEmpty
        ? QueryTerm.parse(terms.removeLast()).operator
        : QueryOperator.include;
    final value = QueryTerm(tag.value, switch (operator) {
      QueryOperator.metatag => QueryOperator.include,
      _ => operator,
    }).raw;
    state = state.copyWith(
      selected: {...state.selected, ...terms, value}.toList(),
      verified: {...state.verified, if (tag.verified) value},
      labels: {...state.labels, '${state.sourceId}:$value': ?tag.displayName},
    );
  }

  void remove(String tag) => state = state.copyWith(
    selected: state.selected.where((value) => value != tag).toList(),
  );
  List<String> submittedTags(String input) =>
      {...state.selected, ...parseQueryInput(input)}.toList();
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

class CommonTagsRequest {
  CommonTagsRequest({
    required this.source,
    required this.locale,
    required this.repository,
    required this.initialTags,
  });
  final String source, locale;
  final TagSuggestionRepository repository;
  final List<TagSuggestion> initialTags;
}

class CommonTagsState {
  CommonTagsState({
    required List<TagSuggestion> tags,
    required this.page,
    required this.hasMore,
    this.loading = const AsyncData<void>(null),
  }) : tags = List.unmodifiable(tags);
  final List<TagSuggestion> tags;
  final int page;
  final bool hasMore;
  final AsyncValue<void> loading;
}

@riverpod
class CommonTags extends _$CommonTags {
  @override
  CommonTagsState build(CommonTagsRequest request) => CommonTagsState(
    tags: request.initialTags,
    page: 1,
    hasMore: request.initialTags.length == 50,
  );
  Future<void> loadMore() async {
    if (state.loading.isLoading || !state.hasMore) return;
    final previous = state;
    state = CommonTagsState(
      tags: previous.tags,
      page: previous.page,
      hasMore: previous.hasMore,
      loading: const AsyncLoading(),
    );
    try {
      final next = await request.repository.common(
        request.source,
        request.locale,
        page: previous.page + 1,
      );
      if (!ref.mounted) return;
      final seen = previous.tags.map((value) => value.value).toSet();
      state = CommonTagsState(
        tags: [
          ...previous.tags,
          ...next.where((value) => seen.add(value.value)),
        ],
        page: previous.page + 1,
        hasMore: next.length == 50,
      );
    } catch (error, stack) {
      if (ref.mounted) {
        state = CommonTagsState(
          tags: previous.tags,
          page: previous.page,
          hasMore: previous.hasMore,
          loading: AsyncError(error, stack),
        );
      }
    }
  }
}
