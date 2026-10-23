// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(proxyConnectivityProbe)
final proxyConnectivityProbeProvider = ProxyConnectivityProbeProvider._();

final class ProxyConnectivityProbeProvider
    extends
        $FunctionalProvider<
          ProxyConnectivityProbe,
          ProxyConnectivityProbe,
          ProxyConnectivityProbe
        >
    with $Provider<ProxyConnectivityProbe> {
  ProxyConnectivityProbeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proxyConnectivityProbeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proxyConnectivityProbeHash();

  @$internal
  @override
  $ProviderElement<ProxyConnectivityProbe> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProxyConnectivityProbe create(Ref ref) {
    return proxyConnectivityProbe(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProxyConnectivityProbe value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProxyConnectivityProbe>(value),
    );
  }
}

String _$proxyConnectivityProbeHash() =>
    r'00f0e93cddb11b9ff2f85f95fcfb69a9a9bcf921';

@ProviderFor(ProxySettings)
final proxySettingsProvider = ProxySettingsProvider._();

final class ProxySettingsProvider
    extends $NotifierProvider<ProxySettings, ProxySettingsState> {
  ProxySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proxySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proxySettingsHash();

  @$internal
  @override
  ProxySettings create() => ProxySettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProxySettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProxySettingsState>(value),
    );
  }
}

String _$proxySettingsHash() => r'a74d78ea2820e49c2e2e37238e07727e6befb48e';

abstract class _$ProxySettings extends $Notifier<ProxySettingsState> {
  ProxySettingsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProxySettingsState, ProxySettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProxySettingsState, ProxySettingsState>,
              ProxySettingsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
