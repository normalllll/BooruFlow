// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_presentation_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shares authenticated preparation and satisfies the largest requested decode.
/// Each mounted media view owns its stable layout hint; a background's smaller
/// hint must never cap a later thumbnail or stage. Session changes replace this
/// cache, and already prepared requests are reused for resolution increases.

@ProviderFor(mediaPresentationCache)
final mediaPresentationCacheProvider = MediaPresentationCacheProvider._();

/// Shares authenticated preparation and satisfies the largest requested decode.
/// Each mounted media view owns its stable layout hint; a background's smaller
/// hint must never cap a later thumbnail or stage. Session changes replace this
/// cache, and already prepared requests are reused for resolution increases.

final class MediaPresentationCacheProvider
    extends
        $FunctionalProvider<
          MediaPresentationCache,
          MediaPresentationCache,
          MediaPresentationCache
        >
    with $Provider<MediaPresentationCache> {
  /// Shares authenticated preparation and satisfies the largest requested decode.
  /// Each mounted media view owns its stable layout hint; a background's smaller
  /// hint must never cap a later thumbnail or stage. Session changes replace this
  /// cache, and already prepared requests are reused for resolution increases.
  MediaPresentationCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaPresentationCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaPresentationCacheHash();

  @$internal
  @override
  $ProviderElement<MediaPresentationCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MediaPresentationCache create(Ref ref) {
    return mediaPresentationCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaPresentationCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaPresentationCache>(value),
    );
  }
}

String _$mediaPresentationCacheHash() =>
    r'c32026f23a033f8e44f4cc973e3d240ca5c0fe21';
