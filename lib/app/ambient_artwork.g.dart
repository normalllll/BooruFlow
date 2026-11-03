// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ambient_artwork.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Window artwork chosen by the pages that show a work, independently of the
/// detail's display resolution. Each page claims it with itself as owner and
/// releases the claim when it goes away; the newest remaining claim wins, and
/// with none left the window has no artwork. The host retains decoded pixels
/// until a replacement is ready.

@ProviderFor(AmbientArtwork)
final ambientArtworkProvider = AmbientArtworkProvider._();

/// Window artwork chosen by the pages that show a work, independently of the
/// detail's display resolution. Each page claims it with itself as owner and
/// releases the claim when it goes away; the newest remaining claim wins, and
/// with none left the window has no artwork. The host retains decoded pixels
/// until a replacement is ready.
final class AmbientArtworkProvider
    extends $NotifierProvider<AmbientArtwork, ImageProvider<Object>?> {
  /// Window artwork chosen by the pages that show a work, independently of the
  /// detail's display resolution. Each page claims it with itself as owner and
  /// releases the claim when it goes away; the newest remaining claim wins, and
  /// with none left the window has no artwork. The host retains decoded pixels
  /// until a replacement is ready.
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

String _$ambientArtworkHash() => r'8b77b5ef12a77de452427e20f6b4589fec9fd6fb';

/// Window artwork chosen by the pages that show a work, independently of the
/// detail's display resolution. Each page claims it with itself as owner and
/// releases the claim when it goes away; the newest remaining claim wins, and
/// with none left the window has no artwork. The host retains decoded pixels
/// until a replacement is ready.

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
