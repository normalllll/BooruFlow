// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postAttributionDetail)
final postAttributionDetailProvider = PostAttributionDetailFamily._();

final class PostAttributionDetailProvider
    extends $FunctionalProvider<AsyncValue<Post>, Post, FutureOr<Post>>
    with $FutureModifier<Post>, $FutureProvider<Post> {
  PostAttributionDetailProvider._({
    required PostAttributionDetailFamily super.from,
    required ({String postId, String sourceId}) super.argument,
  }) : super(
         retry: null,
         name: r'postAttributionDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postAttributionDetailHash();

  @override
  String toString() {
    return r'postAttributionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Post> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Post> create(Ref ref) {
    final argument = this.argument as ({String postId, String sourceId});
    return postAttributionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PostAttributionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postAttributionDetailHash() =>
    r'486aaf51bac793ae5a4e972cabc3eea7418cf029';

final class PostAttributionDetailFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Post>,
          ({String postId, String sourceId})
        > {
  PostAttributionDetailFamily._()
    : super(
        retry: null,
        name: r'postAttributionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostAttributionDetailProvider call(({String postId, String sourceId}) key) =>
      PostAttributionDetailProvider._(argument: key, from: this);

  @override
  String toString() => r'postAttributionDetailProvider';
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

String _$getSimilarHash() => r'50038a9775bde188d6c5e6f7f5c2a54841a103b4';

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
