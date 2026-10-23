import 'dart:convert';
import 'dart:io';
import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';

MediaRequest request({
  int account = 0,
  String route = '0',
  bool enabled = true,
}) => MediaRequest(
  sourceId: 'source',
  postId: '1',
  variant: MediaVariantKind.original,
  url: 'https://cdn.example/1.png?secret=never-persist',
  headers: [],
  cacheKey: 'source:url:$account:$route',
  routeKey: route,
  authRevision: account,
  routeRevision: route,
  allowDiskCache: enabled,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  late Directory temp;
  late EncodedMediaCache cache;
  late File destination;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('encoded-cache-');
    cache = EncodedMediaCache(temporaryDirectory: () async => temp);
    destination = File('${temp.path}/saved.png');
  });
  tearDown(() => temp.delete(recursive: true));
  test(
    'original bytes are copied exactly and the display cache remains reusable',
    () async {
      await cache.write(request(), png);
      expect(
        await cache.copyOriginal(
          request(),
          destination,
          mimeType: 'image/png',
          expectedBytes: png.length,
          md5: crypto.md5.convert(png).toString(),
        ),
        true,
      );
      expect(await destination.readAsBytes(), png);
      expect(await cache.read(request()), png);
      expect(await cache.readPng(request()), png);
      final manifests = await temp
          .list(recursive: true)
          .where((f) => f.path.endsWith('.verified'))
          .toList();
      expect(manifests, hasLength(1));
      expect(
        await File(manifests.single.path).readAsString(),
        isNot(contains('secret')),
      );
    },
  );
  test(
    'account, route and disabled-disk-cache identities cannot reuse bytes',
    () async {
      await cache.write(request(), png);
      for (final other in [
        request(account: 1),
        request(route: '1'),
        request(enabled: false),
      ]) {
        expect(
          await cache.copyOriginal(other, destination, mimeType: 'image/png'),
          false,
        );
        expect(await cache.readPng(other), isNull);
        expect(await destination.exists(), false);
      }
    },
  );
  test(
    'length, digest and a transcode format mismatch fall back without publishing',
    () async {
      await cache.write(request(), png);
      expect(
        await cache.copyOriginal(
          request(),
          destination,
          mimeType: 'image/avif',
        ),
        false,
      );
      expect(
        await cache.copyOriginal(
          request(),
          destination,
          mimeType: 'image/png',
          expectedBytes: png.length + 1,
        ),
        false,
      );
      expect(
        await cache.copyOriginal(
          request(),
          destination,
          mimeType: 'image/png',
          sha256: 'wrong',
        ),
        false,
      );
      expect(
        await cache.copyOriginal(
          request(),
          destination,
          mimeType: 'image/png',
          md5: 'wrong',
        ),
        false,
      );
      expect(await destination.exists(), false);
    },
  );
  test(
    'same-length file corruption is rejected by the worker fingerprint',
    () async {
      final source = File('${temp.path}/entry');
      cache = EncodedMediaCache(file: source);
      await cache.write(request(), png);
      final changed = [...png]..[35] ^= 1;
      await source.writeAsBytes(changed);
      expect(
        await cache.copyOriginal(request(), destination, mimeType: 'image/png'),
        false,
      );
      expect(await cache.readPng(request()), isNull);
      expect(await destination.exists(), false);
    },
  );
  test(
    'unvalidated legacy entries and malformed or incomplete metadata are cache misses',
    () async {
      final source = File('${temp.path}/entry');
      cache = EncodedMediaCache(file: source);
      await source.writeAsBytes(png);
      expect(await cache.read(request()), isNull);
      expect(
        await cache.copyOriginal(request(), destination, mimeType: 'image/png'),
        false,
      );
      await File('${source.path}.verified').writeAsString('bad json');
      expect(await cache.readPng(request()), isNull);
      await cache.write(request(), png.sublist(0, png.length - 12));
      expect(
        await cache.copyOriginal(request(), destination, mimeType: 'image/png'),
        false,
      );
      expect(await cache.readPng(request()), isNull);
      await cache.remove(request());
      expect(await source.exists(), false);
      expect(await File('${source.path}.verified').exists(), false);
    },
  );
}
