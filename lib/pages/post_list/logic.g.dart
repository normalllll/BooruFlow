// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postListHash() => r'1543c96dd3d9034bbcc6bcd4a005247775f21533';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PostList extends BuildlessNotifier<PostListState> {
  late final Type type;
  late final List<String> tags;

  PostListState build(Type type, {required List<String> tags});
}

/// See also [PostList].
@ProviderFor(PostList)
const postListProvider = PostListFamily();

/// See also [PostList].
class PostListFamily extends Family<PostListState> {
  /// See also [PostList].
  const PostListFamily();

  /// See also [PostList].
  PostListProvider call(Type type, {required List<String> tags}) {
    return PostListProvider(type, tags: tags);
  }

  @override
  PostListProvider getProviderOverride(covariant PostListProvider provider) {
    return call(provider.type, tags: provider.tags);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postListProvider';
}

/// See also [PostList].
class PostListProvider extends NotifierProviderImpl<PostList, PostListState> {
  /// See also [PostList].
  PostListProvider(Type type, {required List<String> tags})
    : this._internal(
        () =>
            PostList()
              ..type = type
              ..tags = tags,
        from: postListProvider,
        name: r'postListProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$postListHash,
        dependencies: PostListFamily._dependencies,
        allTransitiveDependencies: PostListFamily._allTransitiveDependencies,
        type: type,
        tags: tags,
      );

  PostListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
    required this.tags,
  }) : super.internal();

  final Type type;
  final List<String> tags;

  @override
  PostListState runNotifierBuild(covariant PostList notifier) {
    return notifier.build(type, tags: tags);
  }

  @override
  Override overrideWith(PostList Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostListProvider._internal(
        () =>
            create()
              ..type = type
              ..tags = tags,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
        tags: tags,
      ),
    );
  }

  @override
  NotifierProviderElement<PostList, PostListState> createElement() {
    return _PostListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostListProvider &&
        other.type == type &&
        other.tags == tags;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, tags.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostListRef on NotifierProviderRef<PostListState> {
  /// The parameter `type` of this provider.
  Type get type;

  /// The parameter `tags` of this provider.
  List<String> get tags;
}

class _PostListProviderElement
    extends NotifierProviderElement<PostList, PostListState>
    with PostListRef {
  _PostListProviderElement(super.provider);

  @override
  Type get type => (origin as PostListProvider).type;
  @override
  List<String> get tags => (origin as PostListProvider).tags;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
