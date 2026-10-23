// Minimal media_kit diagnostic, intentionally without App/Frost/transport code.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'preview/media.dart';

Future<void> main() async {
  if (!Platform.isAndroid) throw StateError('Android diagnostic only');
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final player = Player(
    configuration: const PlayerConfiguration(logLevel: MPVLogLevel.debug),
  );
  final logs = <String>[];
  player.stream.log.listen((value) {
    logs.add(value.toString());
    if (logs.length > 160) logs.removeAt(0);
  });
  final video = VideoController(
    player,
    configuration: const VideoControllerConfiguration(
      vo: 'mediacodec_embed',
      hwdec: 'mediacodec',
    ),
  );
  Object? error;
  PreviewVideoSource? lease;
  player.stream.error.listen((value) => error = value);
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Video(
          controller: video,
          controls: NoVideoControls,
          wakelock: false,
          pauseUponEnteringBackgroundMode: false,
          resumeUponEnteringForegroundMode: false,
        ),
      ),
    ),
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9415);
  await for (final request in server) {
    try {
      final data =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      if (data['command'] == 'play') unawaited(player.play());
      if (data['command'] == 'pause') unawaited(player.pause());
      if (data['command'] == 'openFile') {
        unawaited(
          player
              .open(
                Media(
                  File(
                    '$mediaFixtureRoot/${data['webm'] == true ? 'test_video.webm' : 'test_video.mp4'}',
                  ).uri.toString(),
                ),
              )
              .catchError((Object value) {
                error = value;
              }),
        );
      }
      if (['openHttp', 'openHttpStartZero'].contains(data['command'])) {
        lease = await PreviewVideoSource.open(
          const MediaRequest(
            sourceId: 'diagnostic',
            postId: '0',
            variant: MediaVariantKind.original,
            url: 'https://preview.invalid/0.mp4',
            headers: [],
            routeKey: 'diagnostic',
            cacheKey: 'diagnostic',
            authRevision: 0,
            routeRevision: 'diagnostic',
            allowDiskCache: false,
          ),
        );
        unawaited(
          player
              .open(
                Media(
                  lease.url,
                  start: data['command'] == 'openHttpStartZero'
                      ? Duration.zero
                      : null,
                ),
              )
              .catchError((Object value) {
                error = value;
              }),
        );
      }
      final state = player.state;
      request.response.write(
        jsonEncode({
          'playing': state.playing,
          'positionMs': state.position.inMilliseconds,
          'durationMs': state.duration.inMilliseconds,
          'width': state.width,
          'height': state.height,
          'error': error?.toString(),
          'textureId': video.id.value,
          'textureRect': video.rect.value?.toString(),
          'logs': logs,
        }),
      );
    } catch (error) {
      request.response.statusCode = 500;
      request.response.write('$error');
    } finally {
      await request.response.close();
    }
  }
}
