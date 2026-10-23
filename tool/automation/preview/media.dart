// R5 metadata/codec fixtures. Production code never imports this file.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:booruflow/src/rust/api/booru_models.dart';

String? get mediaFixtureRoot => Platform.isAndroid
    ? '/data/user/0/io.github.normalllll.booruflow/files/r5-fixtures'
    : Platform.environment['BOORUFLOW_AUTOMATION_FIXTURES'];

BooruPost mediaPreviewPost(String board, int index) {
  final video =
      {'M02', 'M05', 'M06', 'M09'}.contains(board) ||
      board == 'M01' && index % 3 == 0;
  final animated =
      {'M03', 'M07'}.contains(board) || board == 'M01' && index % 3 == 2;
  final unsupported = board == 'M04';
  final extension = switch ((video, animated, unsupported)) {
    (true, _, _) => board == 'M05' ? 'webm' : 'mp4',
    (_, true, _) => board == 'M07' ? 'webp' : 'gif',
    _ when board == 'M08' => 'avif',
    (_, _, true) => 'swf',
    _ => 'png',
  };
  final type = switch (extension) {
    'mp4' => MediaType.mp4,
    'webm' => MediaType.webm,
    'gif' => MediaType.gif,
    'webp' => MediaType.webp,
    'avif' => MediaType.avif,
    'png' => MediaType.png,
    _ => null,
  };
  final id = 12408475 + index;
  return BooruPost(
    sourceId: 'danbooru',
    postId: '$id',
    postKey: 'danbooru:$id',
    rating: ContentRating.general,
    tags: const [],
    webUrl: 'https://danbooru.donmai.us/posts/$id',
    media: [
      MediaVariant(
        kind: MediaVariantKind.thumbnail,
        url: 'https://preview.invalid/$index.jpg',
        mediaType: MediaType.jpeg,
        extension_: 'jpg',
        width: 320,
        height: 520,
      ),
      MediaVariant(
        kind: MediaVariantKind.sample,
        url: 'https://preview.invalid/$index.$extension',
        mediaType: type,
        extension_: extension,
        width: animated ? 32 : 1200,
        height: animated ? 32 : 1214,
      ),
      MediaVariant(
        kind: MediaVariantKind.original,
        url: 'https://preview.invalid/$index.$extension',
        mediaType: type,
        extension_: extension,
        width: animated ? 32 : 1200,
        height: animated ? 32 : 1214,
        byteLengthDecimal: '7038339',
      ),
    ],
    flags: const PostFlags(
      hasChildren: false,
      isPending: false,
      isDeleted: false,
      isAiGenerated: false,
    ),
  );
}

Future<Uint8List?> mediaPreviewBytes(MediaRequest request) async {
  if (request.url.endsWith('.mp4') || request.url.endsWith('.swf')) {
    throw StateError(
      'The image path requested non-image media: ${request.url}',
    );
  }
  if (['.gif', '.webp', '.avif'].any(request.url.endsWith)) {
    final root = mediaFixtureRoot;
    if (root == null) {
      throw StateError('Missing isolated media fixture directory');
    }
    return File.fromUri(
      Directory(root).uri.resolve(
        request.url.endsWith('.avif')
            ? 'white.avif'
            : request.url.endsWith('.webp')
            ? 'two_frames.webp'
            : 'two_frames.gif',
      ),
    ).readAsBytes();
  }
  return null;
}

/// Test-owned HTTP origin for decoder fixtures, not a forwarding service.
class PreviewVideoSource {
  PreviewVideoSource(this._server, this.url);
  final HttpServer _server;
  final String url;
  bool _closed = false;
  void close() {
    if (!_closed) {
      _closed = true;
      unawaited(_server.close(force: true));
    }
  }

  static Future<PreviewVideoSource> open(
    MediaRequest request, {
    bool corrupt = false,
    Duration initialDelay = Duration.zero,
  }) async {
    final root = mediaFixtureRoot;
    if (root == null) throw StateError('Missing isolated codec fixture');
    final webm = request.url.endsWith('.webm');
    final file = File.fromUri(
      Directory(root).uri.resolve(webm ? 'test_video.webm' : 'test_video.mp4'),
    );
    final length = corrupt ? 16 : await file.length();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((incoming) async {
      if (initialDelay > Duration.zero) {
        await Future<void>.delayed(initialDelay);
      }
      final response = incoming.response;
      final range = incoming.headers.value(HttpHeaders.rangeHeader);
      final parts = range?.replaceFirst('bytes=', '').split('-');
      final start = parts == null ? 0 : int.tryParse(parts.first) ?? 0;
      final end = math.min(
        length - 1,
        parts == null ? length - 1 : int.tryParse(parts.last) ?? length - 1,
      );
      if (start < 0 || start >= length || end < start) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        await response.close();
        return;
      }
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        webm ? 'video/webm' : 'video/mp4',
      );
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      response.contentLength = end - start + 1;
      if (range != null) {
        response.statusCode = HttpStatus.partialContent;
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$length',
        );
      }
      if (incoming.method != 'HEAD') {
        try {
          if (corrupt) {
            response.add(List.filled(end - start + 1, 0));
          } else {
            await response.addStream(file.openRead(start, end + 1));
          }
        } catch (_) {
          /* A seek replaces and closes the old response. */
        }
      }
      try {
        await response.close();
      } catch (_) {
        /* Decoder already cancelled. */
      }
    });
    return PreviewVideoSource(server, 'http://127.0.0.1:${server.port}/video');
  }
}
