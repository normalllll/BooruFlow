// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_clipboard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(imageClipboard)
final imageClipboardProvider = ImageClipboardProvider._();

final class ImageClipboardProvider
    extends $FunctionalProvider<ImageClipboard, ImageClipboard, ImageClipboard>
    with $Provider<ImageClipboard> {
  ImageClipboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageClipboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageClipboardHash();

  @$internal
  @override
  $ProviderElement<ImageClipboard> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImageClipboard create(Ref ref) {
    return imageClipboard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageClipboard value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageClipboard>(value),
    );
  }
}

String _$imageClipboardHash() => r'9934cdb6c82fa3a00d80be851ece5da891717ed8';
