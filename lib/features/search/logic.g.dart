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

String _$searchHash() => r'9512a4896747941e61f75ebac1aec72f876fcc4d';

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

@ProviderFor(CommonTags)
final commonTagsProvider = CommonTagsFamily._();

final class CommonTagsProvider
    extends $NotifierProvider<CommonTags, CommonTagsState> {
  CommonTagsProvider._({
    required CommonTagsFamily super.from,
    required CommonTagsRequest super.argument,
  }) : super(
         retry: null,
         name: r'commonTagsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commonTagsHash();

  @override
  String toString() {
    return r'commonTagsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommonTags create() => CommonTags();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommonTagsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommonTagsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommonTagsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commonTagsHash() => r'62dc2261605a3caa6a6e90a8eccc12493389d2d1';

final class CommonTagsFamily extends $Family
    with
        $ClassFamilyOverride<
          CommonTags,
          CommonTagsState,
          CommonTagsState,
          CommonTagsState,
          CommonTagsRequest
        > {
  CommonTagsFamily._()
    : super(
        retry: null,
        name: r'commonTagsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommonTagsProvider call(CommonTagsRequest request) =>
      CommonTagsProvider._(argument: request, from: this);

  @override
  String toString() => r'commonTagsProvider';
}

abstract class _$CommonTags extends $Notifier<CommonTagsState> {
  late final _$args = ref.$arg as CommonTagsRequest;
  CommonTagsRequest get request => _$args;

  CommonTagsState build(CommonTagsRequest request);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CommonTagsState, CommonTagsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommonTagsState, CommonTagsState>,
              CommonTagsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
