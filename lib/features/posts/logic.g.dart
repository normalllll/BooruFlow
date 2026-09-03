// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostList)
final postListProvider = PostListFamily._();

final class PostListProvider
    extends $NotifierProvider<PostList, PostListState> {
  PostListProvider._({
    required PostListFamily super.from,
    required (Type, {List<String> tags}) super.argument,
  }) : super(
         retry: null,
         name: r'postListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postListHash();

  @override
  String toString() {
    return r'postListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PostList create() => PostList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postListHash() => r'1543c96dd3d9034bbcc6bcd4a005247775f21533';

final class PostListFamily extends $Family
    with
        $ClassFamilyOverride<
          PostList,
          PostListState,
          PostListState,
          PostListState,
          (Type, {List<String> tags})
        > {
  PostListFamily._()
    : super(
        retry: null,
        name: r'postListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PostListProvider call(Type type, {required List<String> tags}) =>
      PostListProvider._(argument: (type, tags: tags), from: this);

  @override
  String toString() => r'postListProvider';
}

abstract class _$PostList extends $Notifier<PostListState> {
  late final _$args = ref.$arg as (Type, {List<String> tags});
  Type get type => _$args.$1;
  List<String> get tags => _$args.tags;

  PostListState build(Type type, {required List<String> tags});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PostListState, PostListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostListState, PostListState>,
              PostListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, tags: _$args.tags));
  }
}

@ProviderFor(getSimilar)
final getSimilarProvider = GetSimilarFamily._();

final class GetSimilarProvider
    extends $FunctionalProvider<AsyncValue<Similar>, Similar, FutureOr<Similar>>
    with $FutureModifier<Similar>, $FutureProvider<Similar> {
  GetSimilarProvider._({
    required GetSimilarFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'getSimilarProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getSimilarHash();

  @override
  String toString() {
    return r'getSimilarProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Similar> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Similar> create(Ref ref) {
    final argument = this.argument as int;
    return getSimilar(ref, id: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetSimilarProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getSimilarHash() => r'63b96471253688b5a424bfe819602ba4d5ab7f4a';

final class GetSimilarFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Similar>, int> {
  GetSimilarFamily._()
    : super(
        retry: null,
        name: r'getSimilarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetSimilarProvider call({required int id}) =>
      GetSimilarProvider._(argument: id, from: this);

  @override
  String toString() => r'getSimilarProvider';
}
