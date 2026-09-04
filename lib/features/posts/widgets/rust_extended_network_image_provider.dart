import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:extended_image/extended_image.dart'
    show cacheImageFolderName, keyToMd5;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

@immutable
final class RustExtendedNetworkImageProvider
    extends ImageProvider<RustExtendedNetworkImageProvider> {
  const RustExtendedNetworkImageProvider({
    required this.request,
    this.scale = 1,
    this.retries = 2,
  });

  final MediaRequestDto request;
  final double scale;
  final int retries;

  @override
  Future<RustExtendedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    RustExtendedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunks = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _load(key, chunks, decode),
      scale: scale,
      chunkEvents: chunks.stream,
      debugLabel: request.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<String>('Source', request.sourceId),
        DiagnosticsProperty<String>('Post', request.postId),
      ],
    );
  }

  Future<ui.Codec> _load(
    RustExtendedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      final cached = await _readCache();
      if (cached != null) {
        try {
          return await decode(await ui.ImmutableBuffer.fromUint8List(cached));
        } catch (_) {
          try {
            await (await _cacheFile()).delete();
          } catch (_) {
            // A stale cache entry should not prevent a network retry.
          }
        }
      }
      final bytes = await _loadRust(chunkEvents);
      if (bytes.isEmpty) throw StateError('Empty image: ${request.url}');
      if (request.allowDiskCache) {
        await _writeCache(bytes);
      }
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    } finally {
      unawaited(chunkEvents.close());
    }
  }

  Future<Uint8List> _loadRust(
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 0; attempt <= retries; attempt++) {
      final builder = BytesBuilder(copy: false);
      try {
        await for (final event in BooruService.instance.engine.streamMedia(
          request: request,
        )) {
          switch (event) {
            case MediaFetchEventDto_Chunk(
              :final bytes,
              :final receivedBytesDecimal,
              :final totalBytesDecimal,
            ):
              builder.add(bytes);
              chunkEvents.add(
                ImageChunkEvent(
                  cumulativeBytesLoaded:
                      int.tryParse(receivedBytesDecimal) ?? builder.length,
                  expectedTotalBytes: int.tryParse(totalBytesDecimal ?? ''),
                ),
              );
          }
        }
        return builder.takeBytes();
      } catch (error, stack) {
        lastError = error;
        lastStack = stack;
        if (attempt < retries) {
          await Future<void>.delayed(Duration(milliseconds: 120 << attempt));
        }
      }
    }
    Error.throwWithStackTrace(makeBooruErrorReadable(lastError!), lastStack!);
  }

  Future<File> _cacheFile() async {
    final temp = await getTemporaryDirectory();
    final directory = Directory(path.join(temp.path, cacheImageFolderName));
    await directory.create(recursive: true);
    return File(path.join(directory.path, keyToMd5(request.cacheKey)));
  }

  Future<Uint8List?> _readCache() async {
    if (!request.allowDiskCache) return null;
    final file = await _cacheFile();
    return file.existsSync() ? file.readAsBytes() : null;
  }

  Future<void> _writeCache(Uint8List bytes) async {
    final file = await _cacheFile();
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  bool operator ==(Object other) =>
      other is RustExtendedNetworkImageProvider &&
      other.request.cacheKey == request.cacheKey &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(request.cacheKey, scale);
}
