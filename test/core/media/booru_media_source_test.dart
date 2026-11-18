import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:booruflow/core/media/booru_media_source.dart';
import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart'
    show CachedMediaImage, MediaChunk, MediaDiskCache;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_cancel.dart';
import '../../support/media_cache.dart';

const request = MediaRequest(
  sourceId: 'danbooru',
  postId: '7',
  variant: MediaVariantKind.sample,
  url: 'https://user:secret@cdn.example/7.jpg?token=private',
  headers: [],
  routeKey: 'route',
  cacheKey: 'danbooru:7:sample:0:0',
  authRevision: 0,
  routeRevision: '0',
  allowDiskCache: true,
);

BooruError error(BooruErrorCode code) => BooruError(
  code: code,
  sourceId: 'danbooru',
  userMessageKey: 'upstream',
  diagnosticId: 'media-source-test',
);

BooruMediaSource sourceOf(BooruMediaStream stream) =>
    BooruMediaSource(request, stream);

Stream<MediaFetchEvent> never(MediaRequest request, MediaCancel cancel) =>
    const Stream.empty();

/// A folder whose proofs fail to write with an error of no file system kind.
class _ProofFails extends MediaDiskCache {
  _ProofFails(Directory folder) : super(directory: () async => folder);

  @override
  Future<void> write(String key, Uint8List bytes) => key.endsWith('.verified')
      ? Future.error(StateError('proof write failed'))
      : super.write(key, bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  group('the engine stream', () {
    test('chunks and failures become chunks and stream errors', () async {
      final source = sourceOf(
        (_, _) => Stream.fromIterable([
          MediaFetchEvent.chunk(
            bytes: Uint8List.fromList([1, 2]),
            receivedBytesDecimal: '2',
            totalBytesDecimal: '5',
          ),
          MediaFetchEvent.failed(error: error(BooruErrorCode.network)),
        ]),
      );
      final chunks = <MediaChunk>[];
      Object? failure;
      await source.open().forEach(chunks.add).catchError((Object error) {
        failure = error;
      });
      expect(chunks, hasLength(1));
      expect(chunks.single.bytes, [1, 2]);
      expect(chunks.single.received, 2);
      expect(chunks.single.total, 5);
      expect(failure, isA<BooruReadableException>());
    });

    test('cancelling the subscription stops the download', () async {
      MediaCancel? made;
      var cancelled = false;
      final controller = StreamController<MediaFetchEvent>(
        onCancel: () => cancelled = true,
      );
      final subscription = sourceOf((_, cancel) {
        made = cancel;
        return controller.stream;
      }).open().listen((_) {});
      await subscription.cancel();
      expect(cancelled, isTrue);
      expect((made! as FakeMediaCancel).cancelled, isTrue);
      expect((made! as FakeMediaCancel).disposed, isTrue);
    });
  });

  group('stopOnCancel', () {
    test('stops and releases a stream cancelled before it ends', () async {
      final calls = <String>[];
      final controller = StreamController<int>();
      final subscription = stopOnCancel(
        controller.stream,
        stop: () => calls.add('stop'),
        release: () => calls.add('release'),
      ).listen((_) {});
      controller.add(1);
      await subscription.cancel();
      expect(calls, ['stop', 'release']);
    });

    test('only releases a stream that ended', () async {
      final calls = <String>[];
      final done = stopOnCancel(
        Stream.fromIterable([1, 2]),
        stop: () => calls.add('stop'),
        release: () => calls.add('release'),
      ).toList();
      expect(await done, [1, 2]);
      expect(calls, ['release']);
    });

    test('releases a stream that failed', () async {
      final calls = <String>[];
      final stream = stopOnCancel(
        Stream<int>.error(StateError('failed')),
        stop: () => calls.add('stop'),
        release: () => calls.add('release'),
      );
      await expectLater(stream, emitsError(isA<StateError>()));
      expect(calls, ['release']);
    });
  });

  group('shouldRetry', () {
    final source = sourceOf(never);
    for (final code in BooruErrorCode.values) {
      final retried = const {
        BooruErrorCode.network,
        BooruErrorCode.timeout,
        BooruErrorCode.sourceUnavailable,
      }.contains(code);
      test('$code ${retried ? 'is' : 'is not'} retried', () {
        expect(source.shouldRetry(error(code)), retried);
        expect(
          source.shouldRetry(makeBooruErrorReadable(error(code))),
          retried,
        );
      });
    }
    test('an error that is not the engine\'s is retried', () {
      expect(source.shouldRetry(StateError('other')), isTrue);
    });
  });

  group('identity and diagnostics', () {
    test('the cache key and disk permission come from the request', () {
      final source = sourceOf(never);
      expect(source.cacheKey, request.cacheKey);
      expect(source.cacheOnDisk, isTrue);
      expect(
        BooruMediaSource(
          MediaRequest(
            sourceId: request.sourceId,
            postId: request.postId,
            variant: request.variant,
            url: request.url,
            headers: const [],
            routeKey: request.routeKey,
            cacheKey: request.cacheKey,
            authRevision: 0,
            routeRevision: '0',
            allowDiskCache: false,
          ),
          never,
        ).cacheOnDisk,
        isFalse,
      );
    });

    test('the description and cause leave out credentials and queries', () {
      final source = sourceOf(never);
      expect(source.description, 'danbooru/7/sample');
      final text = source.describe(
        BooruError(
          code: BooruErrorCode.network,
          userMessageKey: 'booru.error.network',
          diagnosticId: 'with-url',
          details: 'GET ${request.url} failed',
        ),
      );
      expect(text, contains('https://cdn.example/7.jpg'));
      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('token=private')));
    });
  });

  group('cachedOriginalPng', () {
    late Directory temp;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('booru-media-png-');
    });
    tearDown(() => temp.delete(recursive: true));

    CachedMediaImage imageOf(MediaVariantKind variant) => CachedMediaImage(
      BooruMediaSource(
        MediaRequest(
          sourceId: request.sourceId,
          postId: request.postId,
          variant: variant,
          url: request.url,
          headers: const [],
          routeKey: request.routeKey,
          cacheKey: request.cacheKey,
          authRevision: 0,
          routeRevision: '0',
          allowDiskCache: true,
        ),
        never,
      ),
      store: folderMediaCache(temp).imageStore,
    );

    test('reads the original through the store of the image', () async {
      final image = imageOf(MediaVariantKind.original);
      expect(await image.cachedOriginalPng(), isNull);
      await image.store!.write(request.cacheKey, Uint8List.fromList(png));
      expect(await image.cachedOriginalPng(), png);
    });

    test('is null for a variant that is not the original', () async {
      final image = imageOf(MediaVariantKind.sample);
      await image.store!.write(request.cacheKey, Uint8List.fromList(png));
      expect(await image.cachedOriginalPng(), isNull);
    });
  });

  group('the store of pictures', () {
    late Directory temp;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('booru-media-store-');
    });
    tearDown(() => temp.delete(recursive: true));

    Future<List<String>> names() async => [
      for (final entry in await temp.list().toList())
        entry.uri.pathSegments.where((s) => s.isNotEmpty).last,
    ]..sort();

    test('writing keeps the bytes and then their proof', () async {
      final store = folderMediaCache(temp).imageStore;
      await store.write(request.cacheKey, Uint8List.fromList(png));
      expect(await store.read(request.cacheKey), png);
      expect(await names(), hasLength(2));
      expect(await folderMediaCache(temp).readPng(request), png);
    });

    test('removing removes the bytes and the proof', () async {
      final store = folderMediaCache(temp).imageStore;
      await store.write(request.cacheKey, Uint8List.fromList(png));
      await store.remove(request.cacheKey);
      expect(await store.read(request.cacheKey), isNull);
      expect(await names(), isEmpty);
    });

    test('a proof that cannot be written raises nothing', () async {
      final store = ProvenMediaStore(_ProofFails(temp));
      await store.write(request.cacheKey, Uint8List.fromList(png));
      expect(await store.read(request.cacheKey), png);
      expect(await folderMediaCache(temp).readPng(request), isNull);
    });
    test('a rewrite replaces the proof with that of the new bytes', () async {
      final store = folderMediaCache(temp).imageStore;
      await store.write(request.cacheKey, Uint8List.fromList(png));
      final other = Uint8List.fromList([...png]..[35] ^= 1);
      await store.write(request.cacheKey, other);
      expect(await folderMediaCache(temp).readPng(request), other);
    });
  });
}
