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
