// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_playback.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoLoopPreference)
final videoLoopPreferenceProvider = VideoLoopPreferenceProvider._();

final class VideoLoopPreferenceProvider
    extends $NotifierProvider<VideoLoopPreference, bool> {
  VideoLoopPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoLoopPreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoLoopPreferenceHash();

  @$internal
  @override
  VideoLoopPreference create() => VideoLoopPreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$videoLoopPreferenceHash() =>
    r'38f551d2dfc91683db221664a7af4034dc2eb483';

abstract class _$VideoLoopPreference extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(postPlaybackFactory)
final postPlaybackFactoryProvider = PostPlaybackFactoryProvider._();

final class PostPlaybackFactoryProvider
    extends
        $FunctionalProvider<
          PostPlayback Function(),
          PostPlayback Function(),
          PostPlayback Function()
        >
    with $Provider<PostPlayback Function()> {
  PostPlaybackFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postPlaybackFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postPlaybackFactoryHash();

  @$internal
  @override
  $ProviderElement<PostPlayback Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostPlayback Function() create(Ref ref) {
    return postPlaybackFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostPlayback Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostPlayback Function()>(value),
    );
  }
}

String _$postPlaybackFactoryHash() =>
    r'e36bc202704f8ff43be160c5f69cb13ce4eace39';
