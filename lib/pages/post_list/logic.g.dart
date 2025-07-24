// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(PostList)
const postListProvider = PostListFamily._();

final class PostListProvider extends $NotifierProvider<PostList, PostListState> {
  const PostListProvider._({required PostListFamily super.from, required (Type, {List<String> tags}) super.argument})
    : super(retry: null, name: r'postListProvider', isAutoDispose: false, dependencies: null, $allTransitiveDependencies: null);

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
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<PostListState>(value));
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
    with $ClassFamilyOverride<PostList, PostListState, PostListState, PostListState, (Type, {List<String> tags})> {
  const PostListFamily._()
    : super(retry: null, name: r'postListProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: false);

  PostListProvider call(Type type, {required List<String> tags}) => PostListProvider._(argument: (type, tags: tags), from: this);

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
  void runBuild() {
    final created = build(_$args.$1, tags: _$args.tags);
    final ref = this.ref as $Ref<PostListState, PostListState>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<PostListState, PostListState>, PostListState, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
