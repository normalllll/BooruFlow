import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:yande_gui/src/rust/api/booru_download.dart';
import 'package:yande_gui/src/rust/api/booru_engine.dart';
import 'package:yande_gui/src/rust/api/booru_models.dart';
import 'package:yande_gui/src/rust/frb_generated.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Anime-Pictures post 928938 decodes with the Flutter image codec',
    () async {
      await RustLib.init();
      final support = await Directory.systemTemp.createTemp(
        'anybooru-anime-pictures-codec-',
      );
      addTearDown(() async {
        if (support.existsSync()) await support.delete(recursive: true);
      });

      final engine = await BooruEngine.newInstance(
        config: BooruEngineConfigDto(
          appSupportDirectory: support.path,
          fallbackMode: NetworkFallbackMode.persistedIpOverride,
          fallbackToSystemDns: true,
          userAgent: 'anybooru/flutter-codec-test',
        ),
      );
      await engine.initializeRouteCache();
      final request = await engine.prepareMedia(
        sourceId: 'anime_pictures',
        postId: '928938',
        variant: MediaVariantKind.sample,
      );
      final bytes = BytesBuilder(copy: false);
      await for (final event in engine.streamMedia(request: request)) {
        switch (event) {
          case MediaFetchEventDto_Chunk(bytes: final chunk):
            bytes.add(chunk);
        }
      }

      final encoded = bytes.takeBytes();
      expect(encoded, isNotEmpty);
      expect(encoded.take(8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(encoded);
      addTearDown(codec.dispose);
      final frame = await codec.getNextFrame();
      addTearDown(frame.image.dispose);
      expect(frame.image.width, greaterThan(0));
      expect(frame.image.height, greaterThan(0));
    },
    skip: Platform.environment['ANYBOORU_LIVE_TEST'] != '1',
  );
}
