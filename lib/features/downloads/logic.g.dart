// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logic.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(downloadPathRevealer)
final downloadPathRevealerProvider = DownloadPathRevealerProvider._();

final class DownloadPathRevealerProvider
    extends
        $FunctionalProvider<
          DownloadPathRevealer,
          DownloadPathRevealer,
          DownloadPathRevealer
        >
    with $Provider<DownloadPathRevealer> {
  DownloadPathRevealerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadPathRevealerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadPathRevealerHash();

  @$internal
  @override
  $ProviderElement<DownloadPathRevealer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DownloadPathRevealer create(Ref ref) {
    return downloadPathRevealer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadPathRevealer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadPathRevealer>(value),
    );
  }
}

String _$downloadPathRevealerHash() =>
    r'3da5365bae51b46d401cb0e960dfe7b4cb3fa00b';

@ProviderFor(booruDownloads)
final booruDownloadsProvider = BooruDownloadsProvider._();

final class BooruDownloadsProvider
    extends $FunctionalProvider<BooruDownloads, BooruDownloads, BooruDownloads>
    with $Provider<BooruDownloads> {
  BooruDownloadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'booruDownloadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$booruDownloadsHash();

  @$internal
  @override
  $ProviderElement<BooruDownloads> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BooruDownloads create(Ref ref) {
    return booruDownloads(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BooruDownloads value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BooruDownloads>(value),
    );
  }
}

String _$booruDownloadsHash() => r'faa7c5d16a106dcffa9aed8d3f2fbad3ea1595d9';

@ProviderFor(downloadManagerDependency)
final downloadManagerProvider = DownloadManagerDependencyProvider._();

final class DownloadManagerDependencyProvider
    extends
        $FunctionalProvider<DownloadManager, DownloadManager, DownloadManager>
    with $Provider<DownloadManager> {
  DownloadManagerDependencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadManagerDependencyHash();

  @$internal
  @override
  $ProviderElement<DownloadManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadManager create(Ref ref) {
    return downloadManagerDependency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadManager>(value),
    );
  }
}

String _$downloadManagerDependencyHash() =>
    r'a4a1a5b34ff564c4681c7b0fa7d8e951f22abd95';

@ProviderFor(DownloadItems)
final downloadItemsProvider = DownloadItemsProvider._();

final class DownloadItemsProvider
    extends $NotifierProvider<DownloadItems, List<BooruDownloadItem>> {
  DownloadItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadItemsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadItemsHash();

  @$internal
  @override
  DownloadItems create() => DownloadItems();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BooruDownloadItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BooruDownloadItem>>(value),
    );
  }
}

String _$downloadItemsHash() => r'bea39aec593f891430a31b9db7af2681e8d2c05e';

abstract class _$DownloadItems extends $Notifier<List<BooruDownloadItem>> {
  List<BooruDownloadItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<BooruDownloadItem>, List<BooruDownloadItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BooruDownloadItem>, List<BooruDownloadItem>>,
              List<BooruDownloadItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SessionDownloads)
final sessionDownloadsProvider = SessionDownloadsProvider._();

final class SessionDownloadsProvider
    extends $NotifierProvider<SessionDownloads, List<BooruDownloadItem>> {
  SessionDownloadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionDownloadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionDownloadsHash();

  @$internal
  @override
  SessionDownloads create() => SessionDownloads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BooruDownloadItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BooruDownloadItem>>(value),
    );
  }
}

String _$sessionDownloadsHash() => r'9872d9ef81a4b5f7b047745f0e051e4c640b8348';

abstract class _$SessionDownloads extends $Notifier<List<BooruDownloadItem>> {
  List<BooruDownloadItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<BooruDownloadItem>, List<BooruDownloadItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BooruDownloadItem>, List<BooruDownloadItem>>,
              List<BooruDownloadItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Weighted determinate progress; unknown sizes keep the count but no ring.

@ProviderFor(downloadActivity)
final downloadActivityProvider = DownloadActivityProvider._();

/// Weighted determinate progress; unknown sizes keep the count but no ring.

final class DownloadActivityProvider
    extends
        $FunctionalProvider<
          ({int count, double? progress}),
          ({int count, double? progress}),
          ({int count, double? progress})
        >
    with $Provider<({int count, double? progress})> {
  /// Weighted determinate progress; unknown sizes keep the count but no ring.
  DownloadActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadActivityHash();

  @$internal
  @override
  $ProviderElement<({int count, double? progress})> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ({int count, double? progress}) create(Ref ref) {
    return downloadActivity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int count, double? progress}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int count, double? progress})>(
        value,
      ),
    );
  }
}

String _$downloadActivityHash() => r'e14a4b73e79b4be3922ac658512b780c9d721b44';

/// Presentation rates come from consecutive engine snapshots, never an assumed
/// connection speed. No persistence or competing task state is introduced.

@ProviderFor(DownloadTransferRates)
final downloadTransferRatesProvider = DownloadTransferRatesProvider._();

/// Presentation rates come from consecutive engine snapshots, never an assumed
/// connection speed. No persistence or competing task state is introduced.
final class DownloadTransferRatesProvider
    extends $NotifierProvider<DownloadTransferRates, Map<String, double>> {
  /// Presentation rates come from consecutive engine snapshots, never an assumed
  /// connection speed. No persistence or competing task state is introduced.
  DownloadTransferRatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadTransferRatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadTransferRatesHash();

  @$internal
  @override
  DownloadTransferRates create() => DownloadTransferRates();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$downloadTransferRatesHash() =>
    r'2668dd74bac9b5721a3dc0fb7481f01b426c3018';

/// Presentation rates come from consecutive engine snapshots, never an assumed
/// connection speed. No persistence or competing task state is introduced.

abstract class _$DownloadTransferRates extends $Notifier<Map<String, double>> {
  Map<String, double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, double>, Map<String, double>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, double>, Map<String, double>>,
              Map<String, double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
