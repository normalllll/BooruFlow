// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(networkProbeBackend)
final networkProbeBackendProvider = NetworkProbeBackendProvider._();

final class NetworkProbeBackendProvider
    extends
        $FunctionalProvider<
          NetworkProbeBackend,
          NetworkProbeBackend,
          NetworkProbeBackend
        >
    with $Provider<NetworkProbeBackend> {
  NetworkProbeBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkProbeBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkProbeBackendHash();

  @$internal
  @override
  $ProviderElement<NetworkProbeBackend> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkProbeBackend create(Ref ref) {
    return networkProbeBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkProbeBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkProbeBackend>(value),
    );
  }
}

String _$networkProbeBackendHash() =>
    r'bf9c7eee1c9667e0cb5721d1b6e50ce0cebbd9b0';

@ProviderFor(NetworkStatus)
final networkStatusProvider = NetworkStatusProvider._();

final class NetworkStatusProvider
    extends $NotifierProvider<NetworkStatus, NetworkStatusState> {
  NetworkStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkStatusHash();

  @$internal
  @override
  NetworkStatus create() => NetworkStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkStatusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkStatusState>(value),
    );
  }
}

String _$networkStatusHash() => r'3fb69dcbf54edb204ebfe976c1b51a919bd689e4';

abstract class _$NetworkStatus extends $Notifier<NetworkStatusState> {
  NetworkStatusState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NetworkStatusState, NetworkStatusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetworkStatusState, NetworkStatusState>,
              NetworkStatusState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NetworkConfig)
final networkConfigProvider = NetworkConfigProvider._();

final class NetworkConfigProvider
    extends $NotifierProvider<NetworkConfig, NetworkConfigState> {
  NetworkConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkConfigHash();

  @$internal
  @override
  NetworkConfig create() => NetworkConfig();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkConfigState>(value),
    );
  }
}

String _$networkConfigHash() => r'8ae01942be362eb8176c06a1352643c8a6f62668';

abstract class _$NetworkConfig extends $Notifier<NetworkConfigState> {
  NetworkConfigState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NetworkConfigState, NetworkConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetworkConfigState, NetworkConfigState>,
              NetworkConfigState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
