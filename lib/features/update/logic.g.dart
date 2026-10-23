// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateLookup)
final updateLookupProvider = UpdateLookupProvider._();

final class UpdateLookupProvider
    extends $FunctionalProvider<UpdateLookup, UpdateLookup, UpdateLookup>
    with $Provider<UpdateLookup> {
  UpdateLookupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateLookupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateLookupHash();

  @$internal
  @override
  $ProviderElement<UpdateLookup> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateLookup create(Ref ref) {
    return updateLookup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateLookup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateLookup>(value),
    );
  }
}

String _$updateLookupHash() => r'efa99e49ab2d5df259dba8bdc8b74d747b01da71';

@ProviderFor(UpdateCheck)
final updateCheckProvider = UpdateCheckProvider._();

final class UpdateCheckProvider
    extends $NotifierProvider<UpdateCheck, UpdateCheckState> {
  UpdateCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateCheckHash();

  @$internal
  @override
  UpdateCheck create() => UpdateCheck();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateCheckState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateCheckState>(value),
    );
  }
}

String _$updateCheckHash() => r'44f9c06b9022a56b48e48251caab53d9eb8ab02e';

abstract class _$UpdateCheck extends $Notifier<UpdateCheckState> {
  UpdateCheckState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateCheckState, UpdateCheckState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateCheckState, UpdateCheckState>,
              UpdateCheckState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
