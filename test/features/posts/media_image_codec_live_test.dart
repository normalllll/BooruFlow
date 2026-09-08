import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/frb_generated.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'diagnose each image size through the real Rust media stream and Flutter decoder',
    () async {
      await RustLib.init();
      final support = await Directory.systemTemp.createTemp('booruflow-codec-');
      addTearDown(() => support.delete(recursive: true));
      final engine = await BooruEngine.newInstance(
        config: BooruEngineConfig(
          appSupportDirectory: support.path,
          fallbackMode: NetworkFallbackMode.off,
          dnsProvider: RouteProvider.uncensoredDns,
          userAgent: 'BooruFlow/codec-regression',
        ),
      );
      final source = Platform.environment['BOORUFLOW_LIVE_SOURCE'] ?? 'yande';
      final id = Platform.environment['BOORUFLOW_LIVE_POST_ID'] ?? '1268303';
      final post = await engine.getPost(sourceId: source, postId: id);
      for (final media in post.media) {
        debugPrint(
          '${media.kind.name}: ${media.width}x${media.height} bytes=${media.byteLengthDecimal} type=${media.mediaType}',
        );
      }
      if (Platform.environment['BOORUFLOW_CODEC_METADATA_ONLY'] == '1') return;
      final display = Post(post).displayMedia;
      final seen = <String>{};
      for (final media in post.media) {
        if (!seen.add(media.url)) continue;
        if (media != display &&
            Platform.environment['BOORUFLOW_CODEC_ALL_VARIANTS'] != '1') {
          continue;
        }
        final request = await engine.prepareMediaUrl(
          sourceId: source,
          postId: id,
          variant: media.kind,
          url: media.url,
          allowDiskCache: false,
        );
        final buffer = BytesBuilder(copy: false);
        int? expected;
        try {
          await for (final event
              in engine
                  .streamMedia(request: request)
                  .timeout(const Duration(seconds: 30))) {
            if (event case MediaFetchEvent_Chunk(
              :final bytes,
              :final totalBytesDecimal,
            )) {
              buffer.add(bytes);
              expected = int.tryParse(totalBytesDecimal ?? '') ?? expected;
            } else if (event case MediaFetchEvent_Failed(:final error)) {
              throw makeBooruErrorReadable(error);
            }
          }
          final bytes = buffer.takeBytes();
          if (expected != null) expect(bytes.length, expected);
          // Print only public file identity and byte/codec diagnostics, no credentials.
          debugPrint(
            '$source/$id/${media.kind.name}: bytes=${bytes.length} magic=${bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
          );
          final codec = await ui.instantiateImageCodec(bytes);
          try {
            final frame = await codec.getNextFrame();
            debugPrint(
              'DECODE OK ${frame.image.width}x${frame.image.height} frames=${codec.frameCount}',
            );
            frame.image.dispose();
          } finally {
            codec.dispose();
          }
        } catch (error) {
          debugPrint('DECODE FAILED ${media.kind.name}: $error');
          if (media == display) rethrow;
        }
      }
    },
    skip: Platform.environment['BOORUFLOW_MEDIA_CODEC_LIVE'] != '1',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
