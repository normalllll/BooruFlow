import 'dart:async';
import 'dart:io';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'video_request.dart';

part 'video_playback.g.dart';

// This runtime-only preference never writes the user's persistent settings.
@Riverpod(keepAlive: true)
class VideoLoopPreference extends _$VideoLoopPreference {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

@Riverpod(keepAlive: true)
PostPlayback Function() postPlaybackFactory(Ref ref) =>
    () => MediaKitPostPlayback(
      ref.read(booruServiceProvider).engine,
      proxy: ref.read(networkConfigProvider).proxy,
    );

class PostPlaybackFailure {
  const PostPlaybackFailure(this.cause, {this.unsupported = false});
  final Object cause;
  final bool unsupported;
}

/// Decoder/transport boundary: the UI owns one session, and tests replace only
/// this boundary without loading libmpv or starting any OS playback windows.
abstract class PostPlayback extends ChangeNotifier {
  FrostVideoState get state;
  double? get aspectRatio;
  bool get ready;
  PostPlaybackFailure? get failure;

  /// Whether the opened file has an audio track: null until its tracks are
  /// known. Read from the file itself, not from booru tags, so a silent clip
  /// (ugoira samples, GIF conversions) shows no mute control.
  bool? get hasAudio => null;
  Widget buildVideo(BuildContext context);
  Future<void> open(
    Post post,
    MediaVariant media, {
    required bool looping,
    required Duration position,
    bool muted = false,
  });
  Future<void> playPause();
  Future<void> seek(Duration position);
  Future<void> toggleMute();
  Future<void> setLoop(bool value);
  Future<void> close();
}

class MediaKitPostPlayback extends PostPlayback {
  MediaKitPostPlayback(this._engine, {String? proxy})
    : _proxy = VideoProxy.fromUrl(proxy) {
    // Loading the decoder is deliberately deferred until a user requests play.
    MediaKit.ensureInitialized();
    _player = Player();
    _video = VideoController(
      _player,
      // Android's direct Surface output avoids the extra mpv EGL context that
      // failed in the minimal GLES baseline. Native MediaCodec renders into the
      // registered Flutter texture; other platforms keep their existing path.
      configuration: Platform.isAndroid
          ? const VideoControllerConfiguration(
              vo: 'mediacodec_embed',
              hwdec: 'mediacodec',
            )
          : const VideoControllerConfiguration(),
    );
    for (final stream in <Stream<Object?>>[
      _player.stream.playing,
      _player.stream.position,
      _player.stream.duration,
      _player.stream.buffer,
      _player.stream.buffering,
      _player.stream.volume,
      _player.stream.width,
      _player.stream.height,
      _player.stream.tracks,
    ]) {
      _subscriptions.add(
        stream.listen((_) {
          if (!_closed) notifyListeners();
        }),
      );
    }
    _subscriptions.add(_player.stream.error.listen(_fail));
    // media_kit's error stream omits vo/* errors and cplayer fatal messages.
    // A failed native surface must become an error, never a white playing view.
    _subscriptions.add(
      _player.stream.log.listen((log) {
        if (fatalVideoOutputLog(log.prefix, log.level, log.text)) {
          _fail(log.text);
        }
      }),
    );
  }

  void _fail(String message) {
    if (_closed || _failure != null) return;
    _failure = PostPlaybackFailure(
      StateError(_describeFailure(message)),
      unsupported: unsupportedDecoderMessage(message),
    );
    notifyListeners();
  }

  String _describeFailure(String message) {
    final safe = redactVideoFailure(message, _requestSecrets);
    return _proxy.bypassesSocks
        ? '$safe\n${t.mediaError.videoProxyBypassed}'
        : safe;
  }

  final BooruEngine _engine;
  late final Player _player;
  late final VideoController _video;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final VideoProxy _proxy;
  List<String> _requestSecrets = const [];
  bool _closed = false, _ready = false, _looping = true;
  PostPlaybackFailure? _failure;
  Future<void>? _closing;
  final _closedSignal = Completer<void>();
  @override
  PostPlaybackFailure? get failure => _failure;
  @override
  bool get ready => _ready;
  @override
  double? get aspectRatio {
    final width = _player.state.width, height = _player.state.height;
    return width != null && height != null && width > 0 && height > 0
        ? width / height
        : null;
  }

  bool? _hasAudio;
  @override
  bool? get hasAudio => _hasAudio;

  @override
  FrostVideoState get state => FrostVideoState(
    playing: _player.state.playing,
    position: _player.state.position,
    duration: _player.state.duration,
    buffered: _player.state.buffer,
    buffering: !_ready || _player.state.buffering,
    muted: _player.state.volume == 0,
    looping: _looping,
  );
  @override
  Widget buildVideo(BuildContext context) => Video(
    controller: _video,
    controls: NoVideoControls,
    fit: BoxFit.contain,
    // Geometry is already the media rectangle, without a second matte.
    fill: FrostThemeTokens.of(context).onMediaScrim.withValues(alpha: 0),
    wakelock: false,
    pauseUponEnteringBackgroundMode: false,
    resumeUponEnteringForegroundMode: false,
  );
  @override
  Future<void> open(
    Post post,
    MediaVariant media, {
    required bool looping,
    required Duration position,
    bool muted = false,
  }) async {
    try {
      await _open(
        post,
        media,
        looping: looping,
        position: position,
        muted: muted,
      ).timeout(const Duration(seconds: 20));
    } on BooruError {
      rethrow;
    } catch (error, stack) {
      Error.throwWithStackTrace(
        StateError(_describeFailure(error.toString())),
        stack,
      );
    }
  }

  Future<void> _open(
    Post post,
    MediaVariant media, {
    required bool looping,
    required Duration position,
    bool muted = false,
  }) async {
    final request = await _engine.prepareMediaUrl(
      sourceId: post.sourceId,
      postId: post.id,
      variant: media.kind,
      url: media.url,
      allowDiskCache: false,
    );
    if (_closed) return;
    final video = await _engine.prepareVideoRequest(request: request);
    if (_closed) return;
    _requestSecrets = video.headers.map((header) => header.value).toList();
    if (_player.platform case final NativePlayer native) {
      // Empty explicitly disables a process/system proxy. SOCKS is not supported
      // by mpv's HTTP input; API and image traffic keep the Rust route unchanged.
      await native.setProperty('http-proxy', _proxy.httpProxy ?? '');
    }
    if (_closed) return;
    await setLoop(looping);
    if (_closed) return;
    await _player.setVolume(muted ? 0 : 100);
    if (_closed) return;
    await _player.open(
      Media(
        video.url,
        start: position,
        httpHeaders: {
          for (final header in video.headers) header.name: header.value,
        },
      ),
    );
    if (_closed) return;
    String? pausedFrameSurface;
    unawaited(
      waitForVideoFrame(
        surfaceReady: _video.waitUntilFirstFrameRendered,
        hasCurrentFrame: () async {
          if (_closed) return false;
          if (_player.platform case final NativePlayer native) {
            // Android completes surfaceReady before its asynchronous Surface
            // resize reinitializes the VO. An old VO frame is not readiness for
            // the new texture: wait for the decoded size and live Surface first.
            String? surface;
            if (Platform.isAndroid) {
              final rect = _video.rect.value;
              if (rect == null || rect.width <= 1 || rect.height <= 1) {
                return false;
              }
              if (await native.getProperty('android-surface-size') !=
                  '${rect.width.toInt()}x${rect.height.toInt()}') {
                return false;
              }
              surface = await native.getProperty('wid');
              if (surface == '0' ||
                  await native.getProperty('vo') != 'mediacodec_embed') {
                return false;
              }
            }
            // mpv reads this from vo_get_current_frame, including paused and
            // nonzero starts. It is not the playback clock.
            final value = await native.getProperty(
              'video-frame-info/interlaced',
            );
            final hasFrame = value == 'yes' || value == 'no';
            if (!hasFrame &&
                surface != null &&
                !_player.state.playing &&
                pausedFrameSurface != surface) {
              // The Android plugin recreates the VO then performs a keyframe
              // seek. At a paused start that can discard the sole decoded frame.
              // Seek to the requested position before obtaining one paused preview
              // frame; do this only once for each live Surface.
              pausedFrameSurface = surface;
              await native.command([
                'seek',
                (_player.state.position.inMicroseconds /
                        Duration.microsecondsPerSecond)
                    .toString(),
                'absolute+exact',
              ]);
              // Surface recreation can leave MediaCodec without its initial
              // paused output buffer. Request one preview frame, then mpv
              // remains paused; no continuous playback or clock threshold.
              await native.command(['frame-step']);
              return false;
            }
            return hasFrame &&
                (surface == null || await native.getProperty('wid') == surface);
          }
          return false;
        },
        closed: _closedSignal.future,
      ).then(
        (available) {
          if (!_closed && available) {
            _ready = true;
            // Tracks belong to this decoder session; no second authenticated
            // network probe or Rust route is needed for video metadata.
            _hasAudio = _player.state.tracks.audio.any(
              (track) => track.id != 'auto' && track.id != 'no',
            );
            notifyListeners();
          }
        },
        onError: (Object error) {
          if (!_closed && _failure == null) {
            _failure = PostPlaybackFailure(error);
            notifyListeners();
          }
        },
      ),
    );
  }

  @override
  Future<void> playPause() async {
    if (!_closed) await _player.playOrPause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_closed) await _player.seek(position);
  }

  @override
  Future<void> toggleMute() async {
    if (!_closed) await _player.setVolume(_player.state.volume == 0 ? 100 : 0);
  }

  @override
  Future<void> setLoop(bool value) async {
    if (_closed) return;
    _looping = value;
    await _player.setPlaylistMode(
      value ? PlaylistMode.single : PlaylistMode.none,
    );
    if (!_closed) notifyListeners();
  }

  @override
  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    _closed = true;
    if (!_closedSignal.isCompleted) _closedSignal.complete();
    _requestSecrets = const [];
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.pause();
    await _player.dispose();
  }
}

bool unsupportedDecoderMessage(String message) {
  final lower = message.toLowerCase();
  return [
    'unrecognized file format',
    'failed to recognize file format',
    'unsupported codec',
    'no video or audio streams',
    'no video streams',
    'decoder not found',
    'failed to initialize a decoder',
  ].any(lower.contains);
}

// Restrict this to terminal output failures observed in mpv, not warnings that
// are expected while a surface is being created or replaced.
bool fatalVideoOutputLog(String prefix, String level, String text) =>
    (level == 'fatal' && prefix.startsWith('vo/')) ||
    (level == 'fatal' &&
        prefix == 'cplayer' &&
        (text.contains('video_out') || text.contains('VO window')));

/// Decoder readiness is separate from system presentation. The native capture
/// verifies the latter. This does not depend on time advancing, so paused
/// starts, nonzero starts and loops through zero share the same bounded path.
Future<bool> waitForVideoFrame({
  required Future<void> surfaceReady,
  required Future<bool> Function() hasCurrentFrame,
  required Future<void> closed,
  Duration timeout = const Duration(seconds: 15),
}) async {
  var stopped = false;
  Future<bool> wait() async {
    await surfaceReady;
    while (!stopped) {
      try {
        if (await hasCurrentFrame()) return true;
      } catch (_) {
        // A current frame is legitimately unavailable while opening/buffering.
      }
      if (!stopped) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    return false;
  }

  try {
    return await Future.any([
      wait(),
      closed.then((_) => false),
    ]).timeout(timeout);
  } finally {
    stopped = true;
  }
}
