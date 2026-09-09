// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedSelection)
final feedSelectionProvider = FeedSelectionProvider._();

final class FeedSelectionProvider
    extends
        $NotifierProvider<FeedSelection, Map<String, FeedCollectionRequest>> {
  FeedSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedSelectionHash();

  @$internal
  @override
  FeedSelection create() => FeedSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, FeedCollectionRequest> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, FeedCollectionRequest>>(
        value,
      ),
    );
  }
}

String _$feedSelectionHash() => r'baac9458241ed4a177b66c61ec343f464d0e8c02';

abstract class _$FeedSelection
    extends $Notifier<Map<String, FeedCollectionRequest>> {
  Map<String, FeedCollectionRequest> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, FeedCollectionRequest>,
              Map<String, FeedCollectionRequest>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, FeedCollectionRequest>,
                Map<String, FeedCollectionRequest>
              >,
              Map<String, FeedCollectionRequest>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(discoveryAvailability)
final discoveryAvailabilityProvider = DiscoveryAvailabilityProvider._();

final class DiscoveryAvailabilityProvider
    extends
        $FunctionalProvider<
          DiscoveryAvailability,
          DiscoveryAvailability,
          DiscoveryAvailability
        >
    with $Provider<DiscoveryAvailability> {
  DiscoveryAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryAvailabilityHash();

  @$internal
  @override
  $ProviderElement<DiscoveryAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiscoveryAvailability create(Ref ref) {
    return discoveryAvailability(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiscoveryAvailability value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiscoveryAvailability>(value),
    );
  }
}

String _$discoveryAvailabilityHash() =>
    r'bf4c592c9e173f5934f10278d553eb31e63e2813';

@ProviderFor(PopularProbe)
final popularProbeProvider = PopularProbeFamily._();

final class PopularProbeProvider
    extends $AsyncNotifierProvider<PopularProbe, PopularProbeResult> {
  PopularProbeProvider._({
    required PopularProbeFamily super.from,
    required PopularProbeKey super.argument,
  }) : super(
         retry: null,
         name: r'popularProbeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$popularProbeHash();

  @override
  String toString() {
    return r'popularProbeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PopularProbe create() => PopularProbe();

  @override
  bool operator ==(Object other) {
    return other is PopularProbeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$popularProbeHash() => r'862b0d0cd3ff9503f7c80758a9eac9b4cf204289';

final class PopularProbeFamily extends $Family
    with
        $ClassFamilyOverride<
          PopularProbe,
          AsyncValue<PopularProbeResult>,
          PopularProbeResult,
          FutureOr<PopularProbeResult>,
          PopularProbeKey
        > {
  PopularProbeFamily._()
    : super(
        retry: null,
        name: r'popularProbeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PopularProbeProvider call(PopularProbeKey key) =>
      PopularProbeProvider._(argument: key, from: this);

  @override
  String toString() => r'popularProbeProvider';
}

abstract class _$PopularProbe extends $AsyncNotifier<PopularProbeResult> {
  late final _$args = ref.$arg as PopularProbeKey;
  PopularProbeKey get key => _$args;

  FutureOr<PopularProbeResult> build(PopularProbeKey key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PopularProbeResult>, PopularProbeResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PopularProbeResult>, PopularProbeResult>,
              AsyncValue<PopularProbeResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
