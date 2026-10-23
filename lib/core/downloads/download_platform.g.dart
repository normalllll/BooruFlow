// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_platform.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(downloadPlatform)
final downloadPlatformProvider = DownloadPlatformProvider._();

final class DownloadPlatformProvider
    extends
        $FunctionalProvider<
          DownloadPlatform,
          DownloadPlatform,
          DownloadPlatform
        >
    with $Provider<DownloadPlatform> {
  DownloadPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadPlatformProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadPlatformHash();

  @$internal
  @override
  $ProviderElement<DownloadPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadPlatform create(Ref ref) {
    return downloadPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadPlatform>(value),
    );
  }
}

String _$downloadPlatformHash() => r'dd5aa5b42901adb1a256e18f635064c1f37f0960';
