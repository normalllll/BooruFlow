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
    required (Type, {String sourceId, List<String> tags}) super.argument,
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

String _$postListHash() => r'e0ba17645baac5ce91043fc6243d12f5018f907c';

final class PostListFamily extends $Family
    with
        $ClassFamilyOverride<
          PostList,
          PostListState,
          PostListState,
          PostListState,
          (Type, {String sourceId, List<String> tags})
        > {
  PostListFamily._()
    : super(
        retry: null,
        name: r'postListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PostListProvider call(
    Type type, {
    required String sourceId,
    required List<String> tags,
  }) => PostListProvider._(
    argument: (type, sourceId: sourceId, tags: tags),
    from: this,
  );

  @override
  String toString() => r'postListProvider';
}

abstract class _$PostList extends $Notifier<PostListState> {
  late final _$args = ref.$arg as (Type, {String sourceId, List<String> tags});
  Type get type => _$args.$1;
  String get sourceId => _$args.sourceId;
  List<String> get tags => _$args.tags;

  PostListState build(
    Type type, {
    required String sourceId,
    required List<String> tags,
  });
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
    return element.handleCreate(
      ref,
      () => build(_$args.$1, sourceId: _$args.sourceId, tags: _$args.tags),
    );
  }
}

@ProviderFor(getSimilar)
final getSimilarProvider = GetSimilarFamily._();

final class GetSimilarProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>
        >
    with $FutureModifier<List<Post>>, $FutureProvider<List<Post>> {
  GetSimilarProvider._({
    required GetSimilarFamily super.from,
    required ({String sourceId, String id}) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Post>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Post>> create(Ref ref) {
    final argument = this.argument as ({String sourceId, String id});
    return getSimilar(ref, sourceId: argument.sourceId, id: argument.id);
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

String _$getSimilarHash() => r'6abad4976f31405cef28c905affc6a807f32917c';

final class GetSimilarFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Post>>,
          ({String sourceId, String id})
        > {
  GetSimilarFamily._()
    : super(
        retry: null,
        name: r'getSimilarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetSimilarProvider call({required String sourceId, required String id}) =>
      GetSimilarProvider._(argument: (sourceId: sourceId, id: id), from: this);

  @override
  String toString() => r'getSimilarProvider';
}
