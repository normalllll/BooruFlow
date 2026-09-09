// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booru_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(booruService)
final booruServiceProvider = BooruServiceProvider._();

final class BooruServiceProvider
    extends $FunctionalProvider<BooruService, BooruService, BooruService>
    with $Provider<BooruService> {
  BooruServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'booruServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$booruServiceHash();

  @$internal
  @override
  $ProviderElement<BooruService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BooruService create(Ref ref) {
    return booruService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BooruService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BooruService>(value),
    );
  }
}

String _$booruServiceHash() => r'acd63060f5073b7c3e3da976f19026f52706af7f';

@ProviderFor(BooruSession)
final booruSessionProvider = BooruSessionProvider._();

final class BooruSessionProvider
    extends $NotifierProvider<BooruSession, BooruSessionState> {
  BooruSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'booruSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$booruSessionHash();

  @$internal
  @override
  BooruSession create() => BooruSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BooruSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BooruSessionState>(value),
    );
  }
}

String _$booruSessionHash() => r'b782bc6b01018b1108c0f65652f3ada50c7ef5eb';

abstract class _$BooruSession extends $Notifier<BooruSessionState> {
  BooruSessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BooruSessionState, BooruSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BooruSessionState, BooruSessionState>,
              BooruSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(booruSources)
final booruSourcesProvider = BooruSourcesProvider._();

final class BooruSourcesProvider
    extends
        $FunctionalProvider<
          List<BooruSource>,
          List<BooruSource>,
          List<BooruSource>
        >
    with $Provider<List<BooruSource>> {
  BooruSourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'booruSourcesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$booruSourcesHash();

  @$internal
  @override
  $ProviderElement<List<BooruSource>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<BooruSource> create(Ref ref) {
    return booruSources(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BooruSource> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BooruSource>>(value),
    );
  }
}

String _$booruSourcesHash() => r'2e58d429fb2cae488f883354b6f0eb678a79b0d7';
