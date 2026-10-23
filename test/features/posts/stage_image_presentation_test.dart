import 'dart:typed_data';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/preseeded_media.dart';
import 'media_type_presentation_test.dart' show mediaPost;

const sample = MediaVariant(
  kind: MediaVariantKind.sample,
  url: 'https://test/sample.jpg',
  mediaType: MediaType.jpeg,
  width: 512,
  height: 512,
);
const original = MediaVariant(
  kind: MediaVariantKind.original,
  url: 'https://test/original.jpg',
  mediaType: MediaType.jpeg,
  width: 4000,
  height: 4000,
);
RustExtendedNetworkImageProvider image(int width) =>
    RustExtendedNetworkImageProvider(
      mediaStream: preseededMedia,
      decodeWidth: width,
      request: const MediaRequest(
        sourceId: 'test',
        postId: '1',
        variant: MediaVariantKind.original,
        url: 'https://test/original.jpg',
        headers: [],
        routeKey: 'test',
        cacheKey: 'original',
        authRevision: 0,
        routeRevision: '0',
        allowDiskCache: true,
      ),
    );

class _RetainedCompleter extends ImageStreamCompleter {}

void main() {
  final post = mediaPost([sample, original]);
  test(
    'sample remains the choice until an explicit original request; failure can retry',
    () {
      final state = StageImagePresentation(post: post);
      addTearDown(state.dispose);
      final preview = MemoryImage(Uint8List.fromList([1]));
      state.ready(post, sample, preview, decodedWidth: 512);
      expect(state.mediaFor(post), sample);
      expect(state.canUpgrade(post), isTrue);
      state.requestOriginal(post);
      expect(state.mediaFor(post), original);
      expect(state.loadingOriginal(post), isTrue);
      state.failed();
      expect(state.preview, same(preview));
      expect(state.loadingOriginal(post), isFalse);
      state.requestOriginal(post);
      expect(state.revision, 1);
      expect(state.loadingOriginal(post), isTrue);
      final full = image(800);
      state.ready(post, original, full, decodedWidth: 800);
      expect(state.preview, same(full));
      expect(state.canUpgrade(post), isFalse);
      expect(state.loadingOriginal(post), isFalse);
    },
  );
  test(
    'zoom requests display pixels and a larger decode only after the previous one completes',
    () {
      final state = StageImagePresentation(post: post);
      addTearDown(state.dispose);
      state.requestPixels(post, 500);
      expect(state.originalRequested, isFalse);
      state.requestPixels(post, 800);
      expect(state.originalRequested, isTrue);
      expect(state.minimumDecodeWidth, 800);
      state.requestPixels(post, 1200);
      expect(state.minimumDecodeWidth, 800);
      state.ready(post, original, image(800), decodedWidth: 800);
      expect(state.minimumDecodeWidth, 1200);
      expect(state.loadingOriginal(post), isTrue);
      state.ready(post, original, image(1200), decodedWidth: 1200);
      expect(state.loadingOriginal(post), isFalse);
    },
  );
  test('missing or identical original has no upgrade action', () {
    final state = StageImagePresentation(post: post);
    addTearDown(state.dispose);
    expect(state.canUpgrade(mediaPost([sample])), isFalse);
    expect(
      state.canUpgrade(
        mediaPost([
          sample,
          const MediaVariant(
            kind: MediaVariantKind.original,
            url: 'https://test/sample.jpg',
            mediaType: MediaType.jpeg,
          ),
        ]),
      ),
      isFalse,
    );
  });
  test(
    'same URL retains the stage/cache identity while zoom increases decoded pixels',
    () {
      final shared = mediaPost([
        sample,
        const MediaVariant(
          kind: MediaVariantKind.original,
          url: 'https://test/sample.jpg',
          mediaType: MediaType.jpeg,
          width: 4000,
          height: 4000,
        ),
      ]);
      final state = StageImagePresentation(post: post);
      addTearDown(state.dispose);
      state.ready(shared, sample, image(256), decodedWidth: 256);
      expect(state.canUpgrade(shared), isFalse);
      state.requestPixels(shared, 800);
      expect(state.mediaFor(shared), sample);
      expect(state.minimumDecodeWidth, 800);
    },
  );
  test(
    'failed-original fallback is retryable and retry clears the loading gate',
    () {
      final state = StageImagePresentation(post: post);
      addTearDown(state.dispose);
      final preview = image(128);
      state.ready(post, sample, preview, decodedWidth: 128);
      state.requestOriginal(post);
      state.ready(post, sample, preview, decodedWidth: 128);
      expect(state.loadingOriginal(post), isFalse);
      expect(state.canUpgrade(post), isTrue);
      expect(state.preview, same(preview));
      state.retryStarted();
      expect(state.loadingOriginal(post), isTrue);
      state.failed();
      expect(state.loadingOriginal(post), isFalse);
    },
  );
  test(
    'visited page frames remain reusable without any listeners until the page closes',
    () {
      final state = StageImagePresentation(post: post);
      final owner = Object();
      final provider = image(512);
      final completer = _RetainedCompleter();
      final stream = ImageStream()..setCompleter(completer);
      final listener = ImageStreamListener((_, _) {});
      stream.addListener(listener);
      state.retainFrame(provider, stream, preparationOwner: owner);
      stream.removeListener(listener);
      expect(state.streamFor(provider, owner), same(stream));
      expect(state.preparedBy(Object()), isFalse);
      expect(state.streamFor(provider, Object()), isNull);
      expect(() => stream.addListener(listener), returnsNormally);
      stream.removeListener(listener);
      state.dispose();
      expect(() => stream.addListener(listener), throwsStateError);
    },
  );
  test(
    'replacing a retained frame releases the previous stream and matches only its provider',
    () {
      final state = StageImagePresentation(post: post);
      final previous = image(256), replacement = image(512);
      final owner = Object();
      final a = ImageStream()..setCompleter(_RetainedCompleter());
      final b = ImageStream()..setCompleter(_RetainedCompleter());
      final listener = ImageStreamListener((_, _) {});
      a.addListener(listener);
      state.retainFrame(previous, a, preparationOwner: owner);
      a.removeListener(listener);
      b.addListener(listener);
      state.retainFrame(replacement, b, preparationOwner: owner);
      b.removeListener(listener);
      expect(state.streamFor(previous, owner), isNull);
      expect(state.streamFor(replacement, owner), same(b));
      expect(() => a.addListener(listener), throwsStateError);
      state.dispose();
      expect(() => b.addListener(listener), throwsStateError);
    },
  );
}
