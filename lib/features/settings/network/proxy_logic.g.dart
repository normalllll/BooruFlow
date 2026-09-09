// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$proxySettingsHash() => r'99faef4c06a48911ed74e4789cfa35503b9816c6';

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
