// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$getSimilarHash() => r'39eea96e2fa355ee516265aedd3dcd025090989a';

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
