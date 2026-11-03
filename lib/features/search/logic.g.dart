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

String _$searchHash() => r'024c74478ba81eb7873f6a40e1cd4a3d1922c6cc';

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

@ProviderFor(PendingSearch)
final pendingSearchProvider = PendingSearchProvider._();

final class PendingSearchProvider
    extends $NotifierProvider<PendingSearch, SearchTextRequest?> {
  PendingSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSearchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSearchHash();

  @$internal
  @override
  PendingSearch create() => PendingSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchTextRequest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchTextRequest?>(value),
    );
  }
}

String _$pendingSearchHash() => r'0f80743fb19ddf2cd6c3232516c1ed2eeb030e3c';

abstract class _$PendingSearch extends $Notifier<SearchTextRequest?> {
  SearchTextRequest? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchTextRequest?, SearchTextRequest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchTextRequest?, SearchTextRequest?>,
              SearchTextRequest?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The first page of a source's common tags, shared by everything that shows
/// them so one load serves the title bar search, the Tags page and the full
/// list.

@ProviderFor(CommonTags)
final commonTagsProvider = CommonTagsFamily._();

/// The first page of a source's common tags, shared by everything that shows
/// them so one load serves the title bar search, the Tags page and the full
/// list.
final class CommonTagsProvider
    extends $AsyncNotifierProvider<CommonTags, List<TagSuggestion>> {
  /// The first page of a source's common tags, shared by everything that shows
  /// them so one load serves the title bar search, the Tags page and the full
  /// list.
  CommonTagsProvider._({
    required CommonTagsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'commonTagsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commonTagsHash();

  @override
  String toString() {
    return r'commonTagsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CommonTags create() => CommonTags();

  @override
  bool operator ==(Object other) {
    return other is CommonTagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commonTagsHash() => r'429202e2d6d36046d7ff3d2ece9f7eb0b57abf34';

/// The first page of a source's common tags, shared by everything that shows
/// them so one load serves the title bar search, the Tags page and the full
/// list.

final class CommonTagsFamily extends $Family
    with
        $ClassFamilyOverride<
          CommonTags,
          AsyncValue<List<TagSuggestion>>,
          List<TagSuggestion>,
          FutureOr<List<TagSuggestion>>,
          (String, String)
        > {
  CommonTagsFamily._()
    : super(
        retry: null,
        name: r'commonTagsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The first page of a source's common tags, shared by everything that shows
  /// them so one load serves the title bar search, the Tags page and the full
  /// list.

  CommonTagsProvider call(String source, String locale) =>
      CommonTagsProvider._(argument: (source, locale), from: this);

  @override
  String toString() => r'commonTagsProvider';
}

/// The first page of a source's common tags, shared by everything that shows
/// them so one load serves the title bar search, the Tags page and the full
/// list.

abstract class _$CommonTags extends $AsyncNotifier<List<TagSuggestion>> {
  late final _$args = ref.$arg as (String, String);
  String get source => _$args.$1;
  String get locale => _$args.$2;

  FutureOr<List<TagSuggestion>> build(String source, String locale);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TagSuggestion>>, List<TagSuggestion>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TagSuggestion>>, List<TagSuggestion>>,
              AsyncValue<List<TagSuggestion>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
