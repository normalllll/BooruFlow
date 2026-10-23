// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ambient_artwork.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Selects window artwork independently of the detail's display resolution.
/// The host retains decoded pixels until this provider's replacement is ready.

@ProviderFor(AmbientArtwork)
final ambientArtworkProvider = AmbientArtworkProvider._();

/// Selects window artwork independently of the detail's display resolution.
/// The host retains decoded pixels until this provider's replacement is ready.
final class AmbientArtworkProvider
    extends $NotifierProvider<AmbientArtwork, ImageProvider<Object>?> {
  /// Selects window artwork independently of the detail's display resolution.
  /// The host retains decoded pixels until this provider's replacement is ready.
  AmbientArtworkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ambientArtworkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ambientArtworkHash();

  @$internal
  @override
  AmbientArtwork create() => AmbientArtwork();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageProvider<Object>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageProvider<Object>?>(value),
    );
  }
}

String _$ambientArtworkHash() => r'5f8d752993ee63a4e7f9ad0355b56b04641c9c3a';

/// Selects window artwork independently of the detail's display resolution.
/// The host retains decoded pixels until this provider's replacement is ready.

abstract class _$AmbientArtwork extends $Notifier<ImageProvider<Object>?> {
  ImageProvider<Object>? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<ImageProvider<Object>?, ImageProvider<Object>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImageProvider<Object>?, ImageProvider<Object>?>,
              ImageProvider<Object>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
