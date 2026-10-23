// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(batchSaveLocation)
final batchSaveLocationProvider = BatchSaveLocationFamily._();

final class BatchSaveLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<BatchSaveLocation>,
          BatchSaveLocation,
          FutureOr<BatchSaveLocation>
        >
    with
        $FutureModifier<BatchSaveLocation>,
        $FutureProvider<BatchSaveLocation> {
  BatchSaveLocationProvider._({
    required BatchSaveLocationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'batchSaveLocationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batchSaveLocationHash();

  @override
  String toString() {
    return r'batchSaveLocationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BatchSaveLocation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BatchSaveLocation> create(Ref ref) {
    final argument = this.argument as String;
    return batchSaveLocation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BatchSaveLocationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batchSaveLocationHash() => r'57674a2fb2252ff6cf4589831f1e9730ee8ce3c9';

final class BatchSaveLocationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<BatchSaveLocation>, String> {
  BatchSaveLocationFamily._()
    : super(
        retry: null,
        name: r'batchSaveLocationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BatchSaveLocationProvider call(String sourceId) =>
      BatchSaveLocationProvider._(argument: sourceId, from: this);

  @override
  String toString() => r'batchSaveLocationProvider';
}

@ProviderFor(BatchDownload)
final batchDownloadProvider = BatchDownloadFamily._();

final class BatchDownloadProvider
    extends $NotifierProvider<BatchDownload, BatchDownloadState> {
  BatchDownloadProvider._({
    required BatchDownloadFamily super.from,
    required BatchDownloadRequest super.argument,
  }) : super(
         retry: null,
         name: r'batchDownloadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batchDownloadHash();

  @override
  String toString() {
    return r'batchDownloadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BatchDownload create() => BatchDownload();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchDownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchDownloadState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BatchDownloadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batchDownloadHash() => r'1e28f20f7fce408945e2ec17e353605a40da3e31';

final class BatchDownloadFamily extends $Family
    with
        $ClassFamilyOverride<
          BatchDownload,
          BatchDownloadState,
          BatchDownloadState,
          BatchDownloadState,
          BatchDownloadRequest
        > {
  BatchDownloadFamily._()
    : super(
        retry: null,
        name: r'batchDownloadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BatchDownloadProvider call(BatchDownloadRequest request) =>
      BatchDownloadProvider._(argument: request, from: this);

  @override
  String toString() => r'batchDownloadProvider';
}

abstract class _$BatchDownload extends $Notifier<BatchDownloadState> {
  late final _$args = ref.$arg as BatchDownloadRequest;
  BatchDownloadRequest get request => _$args;

  BatchDownloadState build(BatchDownloadRequest request);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BatchDownloadState, BatchDownloadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BatchDownloadState, BatchDownloadState>,
              BatchDownloadState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
