import 'dart:async';

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/media_presentation_cache.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../discovery/browse_v2_test.dart' show PendingMediaEngine;
import '../discovery/search_interaction_test.dart' show testSource;

class _Engine extends PendingMediaEngine {
  int calls = 0;
  Completer<MediaRequest>? heldRequest;
  bool fails = false;
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) {
    calls++;
    if (heldRequest case final value?) return value.future;
    if (fails) return Future.error(StateError('prepare failed'));
    return Future.value(
      MediaRequest(
        sourceId: sourceId,
        postId: postId,
        variant: variant,
        url: url,
        headers: [],
        routeKey: 'test',
        cacheKey: '$sourceId/$postId/${variant.name}/$url',
        authRevision: 0,
        routeRevision: '0',
        allowDiskCache: allowDiskCache,
      ),
    );
  }
}

class _Service extends BooruService {
  @override
  final _Engine engine = _Engine();
}

const media = MediaVariant(
  kind: MediaVariantKind.sample,
  url: 'https://example.invalid/sample.png',
);

void main() {
  test(
    'ambient-first preparation cannot cap thumbnail decode dimensions',
    () async {
      final engine = _Engine();
      final cache = MediaPresentationCache(engine);
      addTearDown(cache.clear);
      final ambient = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 48,
        reloadRevision: 0,
      );
      final thumbnail = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 168,
        reloadRevision: 0,
      );
      expect(ambient.decodeWidth, 48);
      expect(thumbnail.decodeWidth, 168);
      expect(thumbnail.request, same(ambient.request));
      expect(engine.calls, 1);
    },
  );

  test(
    'larger decode requests reuse preparation and retain the larger identity',
    () async {
      final engine = _Engine();
      final cache = MediaPresentationCache(engine);
      addTearDown(cache.clear);
      final first = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 256,
        reloadRevision: 0,
      );
      final larger = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 1024,
        reloadRevision: 0,
      );
      expect(larger.decodeWidth, 1024);
      expect(larger.request, same(first.request));
      expect(engine.calls, 1);
      final remount = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 512,
        reloadRevision: 0,
      );
      expect(remount, same(larger));
    },
  );

  test(
    'coalesces preparation while satisfying concurrent decode dimensions',
    () async {
      final engine = _Engine()..heldRequest = Completer<MediaRequest>();
      final cache = MediaPresentationCache(engine);
      addTearDown(cache.clear);
      final first = cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 256,
        reloadRevision: 0,
      );
      final second = cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 512,
        reloadRevision: 0,
      );
      expect(second, isNot(same(first)));
      expect(engine.calls, 1);
      engine.heldRequest!.complete(
        const MediaRequest(
          sourceId: 'one',
          postId: '1',
          variant: MediaVariantKind.sample,
          url: 'https://example.invalid/sample.png',
          headers: [],
          routeKey: 'test',
          cacheKey: 'one',
          authRevision: 0,
          routeRevision: '0',
          allowDiskCache: true,
        ),
      );
      final provider = await first;
      expect(provider.decodeWidth, 256);
      final resized = await second;
      expect(resized.decodeWidth, 512);
      expect(resized.request, same(provider.request));
      expect(
        (await cache.resolve(
          sourceId: 'one',
          postId: '1',
          media: media,
          decodeWidth: 768,
          reloadRevision: 0,
        )).decodeWidth,
        768,
      );
      expect(engine.calls, 1);
    },
  );
  test(
    'failed preparation and explicit retry do not reuse stale requests',
    () async {
      final engine = _Engine()..fails = true;
      final cache = MediaPresentationCache(engine);
      addTearDown(cache.clear);
      await expectLater(
        cache.resolve(
          sourceId: 'one',
          postId: '1',
          media: media,
          decodeWidth: 256,
          reloadRevision: 0,
        ),
        throwsStateError,
      );
      engine.fails = false;
      final first = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 256,
        reloadRevision: 0,
      );
      cache.evict(sourceId: 'one', postId: '1', media: media);
      final retry = await cache.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 512,
        reloadRevision: 1,
      );
      expect(retry, isNot(same(first)));
      expect(retry.reloadRevision, 1);
      expect(engine.calls, 3);
    },
  );
  test('LRU is bounded to the existing 300-image item budget', () async {
    final engine = _Engine();
    final cache = MediaPresentationCache(engine);
    addTearDown(cache.clear);
    for (var i = 0; i <= 300; i++) {
      await cache.resolve(
        sourceId: 'one',
        postId: '$i',
        media: media,
        decodeWidth: 256,
        reloadRevision: 0,
      );
    }
    await cache.resolve(
      sourceId: 'one',
      postId: '300',
      media: media,
      decodeWidth: 512,
      reloadRevision: 0,
    );
    expect(engine.calls, 301);
    await cache.resolve(
      sourceId: 'one',
      postId: '0',
      media: media,
      decodeWidth: 256,
      reloadRevision: 0,
    );
    expect(engine.calls, 302);
  });
  test(
    'session revision replaces the cache rather than reusing old authenticated requests',
    () async {
      final service = _Service()..useSourcesForTesting([testSource('one')]);
      final container = ProviderContainer(
        overrides: [booruServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        mediaPresentationCacheProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final first = container.read(mediaPresentationCacheProvider);
      await first.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 256,
        reloadRevision: 0,
      );
      service.notifyChanged();
      await container.pump();
      final next = container.read(mediaPresentationCacheProvider);
      expect(next, isNot(same(first)));
      await next.resolve(
        sourceId: 'one',
        postId: '1',
        media: media,
        decodeWidth: 256,
        reloadRevision: 0,
      );
      expect(service.engine.calls, 2);
    },
  );
}
