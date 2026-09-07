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
