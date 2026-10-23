// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tagSuggestionRepository)
final tagSuggestionRepositoryProvider = TagSuggestionRepositoryProvider._();

final class TagSuggestionRepositoryProvider
    extends
        $FunctionalProvider<
          TagSuggestionRepository,
          TagSuggestionRepository,
          TagSuggestionRepository
        >
    with $Provider<TagSuggestionRepository> {
  TagSuggestionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagSuggestionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagSuggestionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TagSuggestionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TagSuggestionRepository create(Ref ref) {
    return tagSuggestionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagSuggestionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagSuggestionRepository>(value),
    );
  }
}

String _$tagSuggestionRepositoryHash() =>
    r'746c0e9db493809d632e75f16e1d4641b0215a38';

@ProviderFor(Search)
final searchProvider = SearchFamily._();

final class SearchProvider extends $NotifierProvider<Search, SearchState> {
  SearchProvider._({
    required SearchFamily super.from,
    required SearchSession super.argument,
  }) : super(
         retry: null,
         name: r'searchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchHash();

  @override
  String toString() {
    return r'searchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Search create() => Search();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchHash() => r'd372e6b9aacfefdc80ddda92df8ba66c3ddca4e4';

final class SearchFamily extends $Family
    with
        $ClassFamilyOverride<
          Search,
          SearchState,
          SearchState,
          SearchState,
          SearchSession
        > {
  SearchFamily._()
    : super(
        retry: null,
        name: r'searchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchProvider call(SearchSession session) =>
      SearchProvider._(argument: session, from: this);

  @override
  String toString() => r'searchProvider';
}

abstract class _$Search extends $Notifier<SearchState> {
  late final _$args = ref.$arg as SearchSession;
  SearchSession get session => _$args;

  SearchState build(SearchSession session);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(UserTags)
final userTagsProvider = UserTagsProvider._();

final class UserTagsProvider
    extends $AsyncNotifierProvider<UserTags, List<UserTagAlias>> {
  UserTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userTagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userTagsHash();

  @$internal
  @override
  UserTags create() => UserTags();
}

String _$userTagsHash() => r'd9b6971a36606142beb308c5b7ee8da85e98995a';

abstract class _$UserTags extends $AsyncNotifier<List<UserTagAlias>> {
  FutureOr<List<UserTagAlias>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<UserTagAlias>>, List<UserTagAlias>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserTagAlias>>, List<UserTagAlias>>,
              AsyncValue<List<UserTagAlias>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchHistory)
final searchHistoryProvider = SearchHistoryFamily._();

final class SearchHistoryProvider
    extends $AsyncNotifierProvider<SearchHistory, List<String>> {
  SearchHistoryProvider._({
    required SearchHistoryFamily super.from,
    required (TagSuggestionRepository, String) super.argument,
  }) : super(
         retry: null,
         name: r'searchHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryHash();

  @override
  String toString() {
    return r'searchHistoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SearchHistory create() => SearchHistory();

  @override
  bool operator ==(Object other) {
    return other is SearchHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchHistoryHash() => r'6440c7b7e1b3042364923f3fc2aa7f0a13f46c32';

final class SearchHistoryFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchHistory,
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>,
          (TagSuggestionRepository, String)
        > {
  SearchHistoryFamily._()
    : super(
        retry: null,
        name: r'searchHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchHistoryProvider call(
    TagSuggestionRepository repository,
    String source,
  ) => SearchHistoryProvider._(argument: (repository, source), from: this);

  @override
  String toString() => r'searchHistoryProvider';
}

abstract class _$SearchHistory extends $AsyncNotifier<List<String>> {
  late final _$args = ref.$arg as (TagSuggestionRepository, String);
  TagSuggestionRepository get repository => _$args.$1;
  String get source => _$args.$2;

  FutureOr<List<String>> build(
    TagSuggestionRepository repository,
    String source,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
