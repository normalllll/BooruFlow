// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getSimilarHash() => r'd543918c9aa9e22ff4c120299f6d2f2f0dd41037';

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

/// See also [getSimilar].
@ProviderFor(getSimilar)
const getSimilarProvider = GetSimilarFamily();

/// See also [getSimilar].
class GetSimilarFamily extends Family<AsyncValue<Similar>> {
  /// See also [getSimilar].
  const GetSimilarFamily();

  /// See also [getSimilar].
  GetSimilarProvider call({required int id}) {
    return GetSimilarProvider(id: id);
  }

  @override
  GetSimilarProvider getProviderOverride(
    covariant GetSimilarProvider provider,
  ) {
    return call(id: provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getSimilarProvider';
}

/// See also [getSimilar].
class GetSimilarProvider extends AutoDisposeFutureProvider<Similar> {
  /// See also [getSimilar].
  GetSimilarProvider({required int id})
    : this._internal(
        (ref) => getSimilar(ref as GetSimilarRef, id: id),
        from: getSimilarProvider,
        name: r'getSimilarProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$getSimilarHash,
        dependencies: GetSimilarFamily._dependencies,
        allTransitiveDependencies: GetSimilarFamily._allTransitiveDependencies,
        id: id,
      );

  GetSimilarProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<Similar> Function(GetSimilarRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetSimilarProvider._internal(
        (ref) => create(ref as GetSimilarRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Similar> createElement() {
    return _GetSimilarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetSimilarProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetSimilarRef on AutoDisposeFutureProviderRef<Similar> {
  /// The parameter `id` of this provider.
  int get id;
}

class _GetSimilarProviderElement
    extends AutoDisposeFutureProviderElement<Similar>
    with GetSimilarRef {
  _GetSimilarProviderElement(super.provider);

  @override
  int get id => (origin as GetSimilarProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
