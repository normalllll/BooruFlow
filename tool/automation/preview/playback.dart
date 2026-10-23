import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/video_playback.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

// Test-owned read-only observation. Production main never imports this file.
final previewPlayers = <ObservedPlayback>[];
PostPlayback createPreviewPlayback(BooruEngine engine) {
  final observed = ObservedPlayback(MediaKitPostPlayback(engine));
  previewPlayers.add(observed);
  return observed;
}

List<Map<String, Object?>> videoDiagnostics() => [
  for (final player in previewPlayers)
    {
      'closed': player.closed,
      'closing': player.closing,
      'ready': player.ready,
      'hasAudio': player.hasAudio,
      'playing': player.state.playing,
      'positionMs': player.state.position.inMilliseconds,
      'durationMs': player.state.duration.inMilliseconds,
      'muted': player.state.muted,
      'looping': player.state.looping,
      'aspectRatio': player.aspectRatio,
      'error': player.failure?.cause.toString(),
    },
];

class ObservedPlayback extends PostPlayback {
  ObservedPlayback(this.delegate) {
    delegate.addListener(notifyListeners);
  }
  final PostPlayback delegate;
  bool closed = false, closing = false;
  @override
  FrostVideoState get state => delegate.state;
  @override
  bool? get hasAudio => delegate.hasAudio;
  @override
  bool get ready => delegate.ready;
  @override
  double? get aspectRatio => delegate.aspectRatio;
  @override
  PostPlaybackFailure? get failure => delegate.failure;
  @override
  Widget buildVideo(BuildContext context) => delegate.buildVideo(context);
  @override
  Future<void> open(
    Post post,
    MediaVariant media, {
    required bool looping,
    required Duration position,
    bool muted = false,
  }) => delegate.open(
    post,
    media,
    looping: looping,
    position: position,
    muted: muted,
  );
  @override
  Future<void> playPause() => delegate.playPause();
  @override
  Future<void> seek(Duration position) => delegate.seek(position);
  @override
  Future<void> toggleMute() => delegate.toggleMute();
  @override
  Future<void> setLoop(bool value) => delegate.setLoop(value);
  @override
  Future<void> close() async {
    closing = true;
    await delegate.close();
    closed = true;
    closing = false;
  }

  @override
  void dispose() {
    delegate.removeListener(notifyListeners);
    delegate.dispose();
    super.dispose();
  }
}
