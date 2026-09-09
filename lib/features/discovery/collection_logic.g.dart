// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(collectionLoader)
final collectionLoaderProvider = CollectionLoaderProvider._();

final class CollectionLoaderProvider
    extends
        $FunctionalProvider<
          CollectionLoader,
          CollectionLoader,
          CollectionLoader
        >
    with $Provider<CollectionLoader> {
  CollectionLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionLoaderHash();

  @$internal
  @override
  $ProviderElement<CollectionLoader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CollectionLoader create(Ref ref) {
    return collectionLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollectionLoader>(value),
    );
  }
}

String _$collectionLoaderHash() => r'43a014fa93e475e1cf7177c69b1de2452c964884';

@ProviderFor(collectionRetention)
final collectionRetentionProvider = CollectionRetentionProvider._();

final class CollectionRetentionProvider
    extends
        $FunctionalProvider<
          CollectionRetention,
          CollectionRetention,
          CollectionRetention
        >
    with $Provider<CollectionRetention> {
  CollectionRetentionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionRetentionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionRetentionHash();

  @$internal
  @override
  $ProviderElement<CollectionRetention> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CollectionRetention create(Ref ref) {
    return collectionRetention(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionRetention value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollectionRetention>(value),
    );
  }
}

String _$collectionRetentionHash() =>
    r'24b4f487e1d7e801e89e6911be932021ff0349d6';

/// One state machine for feeds and searches. No page-number arithmetic in Dart.

@ProviderFor(PostCollection)
final postCollectionProvider = PostCollectionFamily._();

/// One state machine for feeds and searches. No page-number arithmetic in Dart.
final class PostCollectionProvider
    extends $NotifierProvider<PostCollection, PostCollectionState> {
  /// One state machine for feeds and searches. No page-number arithmetic in Dart.
  PostCollectionProvider._({
    required PostCollectionFamily super.from,
    required CollectionIdentity super.argument,
  }) : super(
         retry: null,
         name: r'postCollectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postCollectionHash();

  @override
  String toString() {
    return r'postCollectionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PostCollection create() => PostCollection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostCollectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostCollectionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostCollectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postCollectionHash() => r'af705a76a30ec6fa15496b45623823bc4e383683';

/// One state machine for feeds and searches. No page-number arithmetic in Dart.

final class PostCollectionFamily extends $Family
    with
        $ClassFamilyOverride<
          PostCollection,
          PostCollectionState,
          PostCollectionState,
          PostCollectionState,
          CollectionIdentity
        > {
  PostCollectionFamily._()
    : super(
        retry: null,
        name: r'postCollectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One state machine for feeds and searches. No page-number arithmetic in Dart.

  PostCollectionProvider call(CollectionIdentity identity) =>
      PostCollectionProvider._(argument: identity, from: this);

  @override
  String toString() => r'postCollectionProvider';
}

/// One state machine for feeds and searches. No page-number arithmetic in Dart.

abstract class _$PostCollection extends $Notifier<PostCollectionState> {
  late final _$args = ref.$arg as CollectionIdentity;
  CollectionIdentity get identity => _$args;

  PostCollectionState build(CollectionIdentity identity);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PostCollectionState, PostCollectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostCollectionState, PostCollectionState>,
              PostCollectionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
