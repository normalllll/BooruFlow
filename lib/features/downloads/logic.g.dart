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

/// What keeps each post file from being downloaded again. Cards and detail
/// actions read their own entry, so they rebuild only when it changes.

@ProviderFor(downloadBlocks)
final downloadBlocksProvider = DownloadBlocksProvider._();

/// What keeps each post file from being downloaded again. Cards and detail
/// actions read their own entry, so they rebuild only when it changes.

final class DownloadBlocksProvider
    extends
        $FunctionalProvider<
          Map<DownloadIdentity, DownloadBlock>,
          Map<DownloadIdentity, DownloadBlock>,
          Map<DownloadIdentity, DownloadBlock>
        >
    with $Provider<Map<DownloadIdentity, DownloadBlock>> {
  /// What keeps each post file from being downloaded again. Cards and detail
  /// actions read their own entry, so they rebuild only when it changes.
  DownloadBlocksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadBlocksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadBlocksHash();

  @$internal
  @override
  $ProviderElement<Map<DownloadIdentity, DownloadBlock>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<DownloadIdentity, DownloadBlock> create(Ref ref) {
    return downloadBlocks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<DownloadIdentity, DownloadBlock> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<DownloadIdentity, DownloadBlock>>(value),
    );
  }
}

String _$downloadBlocksHash() => r'eb9cab817617622e10fdf65e4e2ccfb1f7e65781';

/// The downloads in the activity count. A flight in the air is left out of
/// the count only while the download it carries is in it.

@ProviderFor(countedDownloads)
final countedDownloadsProvider = CountedDownloadsProvider._();

/// The downloads in the activity count. A flight in the air is left out of
/// the count only while the download it carries is in it.

final class CountedDownloadsProvider
    extends
        $FunctionalProvider<
          Set<DownloadIdentity>,
          Set<DownloadIdentity>,
          Set<DownloadIdentity>
        >
    with $Provider<Set<DownloadIdentity>> {
  /// The downloads in the activity count. A flight in the air is left out of
  /// the count only while the download it carries is in it.
  CountedDownloadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countedDownloadsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countedDownloadsHash();

  @$internal
  @override
  $ProviderElement<Set<DownloadIdentity>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Set<DownloadIdentity> create(Ref ref) {
    return countedDownloads(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<DownloadIdentity> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<DownloadIdentity>>(value),
    );
  }
}

String _$countedDownloadsHash() => r'891c3f23320f4b879ecbbc55c76eeaaf0fa17c11';

/// Weighted determinate progress; unknown sizes keep the count but no ring.
/// A tap whose task is not listed yet already counts.

@ProviderFor(downloadActivity)
final downloadActivityProvider = DownloadActivityProvider._();

/// Weighted determinate progress; unknown sizes keep the count but no ring.
/// A tap whose task is not listed yet already counts.

final class DownloadActivityProvider
    extends
        $FunctionalProvider<
          ({int count, double? progress}),
          ({int count, double? progress}),
          ({int count, double? progress})
        >
    with $Provider<({int count, double? progress})> {
  /// Weighted determinate progress; unknown sizes keep the count but no ring.
  /// A tap whose task is not listed yet already counts.
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

String _$downloadActivityHash() => r'892f33566d3806b0eea52676d0aff21977234948';

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
