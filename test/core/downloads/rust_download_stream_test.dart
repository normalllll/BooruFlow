import 'dart:io';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:booruflow/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'FRB download failure produces a typed event and no Unhandled BooruError',
    () async {
      await RustLib.init();
      final directory = await Directory.systemTemp.createTemp(
        'booru-frb-stream-',
      );
      final engine = await BooruEngine.newInstance(
        config: BooruEngineConfig(
          appSupportDirectory: directory.path,
          fallbackMode: NetworkFallbackMode.off,
          dnsProvider: RouteProvider.uncensoredDns,
          userAgent: 'test',
        ),
      );
      try {
        await expectLater(
          engine.downloadToFileStream(
            request: DownloadRequest(
              sourceId: 'missing-source',
              postId: '1',
              variant: MediaVariantKind.original,
              downloadRoot: directory.path,
            ),
          ),
          emitsInOrder([
            isA<DownloadEvent_Progress>().having(
              (event) => event.receivedBytesDecimal,
              'registered',
              '0',
            ),
            isA<DownloadEvent_Failed>().having(
              (event) => event.error.code,
              'code',
              BooruErrorCode.invalidRequest,
            ),
            emitsDone,
          ]),
        );
        // The only other FRB streaming API follows the same event-only rule.
        await expectLater(
          engine.streamMedia(
            request: const MediaRequest(
              sourceId: 'missing-source',
              postId: '1',
              variant: MediaVariantKind.original,
              url: 'https://example.invalid/image.png',
              headers: [],
              routeKey: 'test',
              cacheKey: 'test',
              authRevision: 0,
              routeRevision: 'test',
              allowDiskCache: false,
            ),
          ),
          emitsInOrder([
            isA<MediaFetchEvent_Failed>().having(
              (event) => event.error.code,
              'code',
              BooruErrorCode.invalidRequest,
            ),
            emitsDone,
          ]),
        );
      } finally {
        engine.dispose();
        await directory.delete(recursive: true);
      }
    },
  );
}
