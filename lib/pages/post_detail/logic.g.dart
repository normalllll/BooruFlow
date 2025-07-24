// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(getSimilar)
const getSimilarProvider = GetSimilarFamily._();

final class GetSimilarProvider extends $FunctionalProvider<AsyncValue<Similar>, Similar, FutureOr<Similar>>
    with $FutureModifier<Similar>, $FutureProvider<Similar> {
  const GetSimilarProvider._({required GetSimilarFamily super.from, required int super.argument})
    : super(retry: null, name: r'getSimilarProvider', isAutoDispose: true, dependencies: null, $allTransitiveDependencies: null);

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
  $FutureProviderElement<Similar> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

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

String _$getSimilarHash() => r'd543918c9aa9e22ff4c120299f6d2f2f0dd41037';

final class GetSimilarFamily extends $Family with $FunctionalFamilyOverride<FutureOr<Similar>, int> {
  const GetSimilarFamily._()
    : super(retry: null, name: r'getSimilarProvider', dependencies: null, $allTransitiveDependencies: null, isAutoDispose: true);

  GetSimilarProvider call({required int id}) => GetSimilarProvider._(argument: id, from: this);

  @override
  String toString() => r'getSimilarProvider';
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
