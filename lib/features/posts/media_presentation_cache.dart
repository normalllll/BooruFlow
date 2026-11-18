import 'package:booruflow/core/media/booru_media_source.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_presentation_cache.g.dart';

// Match the existing image-cache item budget; no decoded images are owned here.
const _mediaPresentationCapacity = 300;
typedef _MediaIdentity = (
  String,
  String,
  MediaVariantKind,
  String,
  bool,
  bool,
  bool,
);

/// Shares authenticated preparation and satisfies the largest requested decode.
/// Each mounted media view owns its stable layout hint; a background's smaller
/// hint must never cap a later thumbnail or stage. Session changes replace this
/// cache, and already prepared requests are reused for resolution increases.
@Riverpod(keepAlive: true)
MediaPresentationCache mediaPresentationCache(Ref ref) {
  ref.watch(booruSessionProvider.select((state) => state.revision));
  final cache = MediaPresentationCache(ref.watch(booruServiceProvider).engine);
  ref.onDispose(cache.clear);
  return cache;
}

class MediaPresentationCache {
  MediaPresentationCache(this._engine);
  final BooruEngine _engine;
  final _entries = <_MediaIdentity, Future<CachedMediaImage>>{};
  bool _disposed = false;

  Future<CachedMediaImage> resolve({
    required String sourceId,
    required String postId,
    required MediaVariant media,
    required int? decodeWidth,
    required int reloadRevision,
    bool firstFrameOnly = false,
    bool progressive = false,
    bool? retainDecoded,
  }) {
    final retained = retainDecoded ?? media.kind != MediaVariantKind.original;
    final identity = (
      sourceId,
      postId,
      media.kind,
      media.url,
      firstFrameOnly,
      progressive,
      retained,
    );
    if (_entries.remove(identity) case final cached?) {
      final resized = cached.then(
        (provider) =>
            provider.decodeWidth != null &&
                (decodeWidth == null || provider.decodeWidth! < decodeWidth)
            ? booruMediaImage(
                request: provider.request!,
                stream: provider.stream!,
                decodeWidth: decodeWidth,
                reloadRevision: provider.reloadRevision,
                firstFrameOnly: provider.firstFrameOnly,
                progressive: provider.progressive,
                retainDecoded: retained,
              )
            : provider,
      );
      _entries[identity] = resized;
      return resized;
    }
    late final Future<CachedMediaImage> pending;
    pending = _engine
        .prepareMediaUrl(
          sourceId: sourceId,
          postId: postId,
          variant: media.kind,
          url: media.url,
          allowDiskCache: true,
        )
        .then(
          (request) => booruMediaImage(
            request: request,
            stream: (request, cancel) =>
                _engine.streamMedia(request: request, cancel: cancel),
            decodeWidth: decodeWidth,
            reloadRevision: reloadRevision,
            firstFrameOnly: firstFrameOnly,
            progressive: progressive,
            retainDecoded: retained,
          ),
          onError: (Object error, StackTrace stack) {
            if (!_disposed && identical(_entries[identity], pending)) {
              _entries.remove(identity);
            }
            Error.throwWithStackTrace(error, stack);
          },
        );
    if (!_disposed) {
      _entries[identity] = pending;
      if (_entries.length > _mediaPresentationCapacity) {
        _entries.remove(_entries.keys.first);
      }
    }
    return pending;
  }

  void evict({
    required String sourceId,
    required String postId,
    required MediaVariant media,
    bool firstFrameOnly = false,
    bool progressive = false,
  }) {
    _entries.removeWhere(
      (key, _) =>
          key.$1 == sourceId &&
          key.$2 == postId &&
          key.$3 == media.kind &&
          key.$4 == media.url &&
          key.$5 == firstFrameOnly &&
          key.$6 == progressive,
    );
  }

  void clear() {
    _disposed = true;
    _entries.clear();
  }
}
