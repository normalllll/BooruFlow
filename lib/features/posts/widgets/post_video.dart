import 'dart:async';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/video_playback.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// One decoder per visible stage. Cover rendering never creates a player.
class PostVideo extends ConsumerStatefulWidget {
  const PostVideo({
    required this.post,
    required this.cover,
    required this.stage,
    this.onFullscreen,
    this.preview,
    this.initialPosition,
    this.initialMuted = false,
    super.key,
  });
  final Post post;
  final Widget Function(VoidCallback start) cover;
  final Widget Function(double ratio, Widget video) stage;
  final void Function(Duration position, bool muted)? onFullscreen;
  final Duration? initialPosition;
  final bool initialMuted;
  final ImageProvider? preview;
  @override
  ConsumerState<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends ConsumerState<PostVideo>
    with WidgetsBindingObserver {
  PostPlayback? _playback;
  PostPlaybackFailure? _failure;
  Duration _resume = Duration.zero;
  bool _muted = false;
  bool _starting = false, _routeCurrent = true, _handingOff = false;
  Future<void> _closing = Future.value();
  int _generation = 0;
  Animation<double>? _routeAnimation;
  final _focusScope = FocusScopeNode(debugLabel: 'Video playback');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _muted = widget.initialMuted;
    if (widget.initialPosition case final position?) {
      _resume = position;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _routeCurrent) unawaited(_start());
      });
    }
    ref.listenManual(booruSessionProvider.select((s) => s.revision), (_, _) {
      if (mounted) setState(() => _release());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_routeStatus);
      _routeAnimation = animation;
      animation?.addStatusListener(_routeStatus);
    }
    if (!_routeCurrent || !TickerMode.valuesOf(context).enabled) _release();
  }

  void _routeStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse && mounted) {
      setState(() => _release());
    }
  }

  @override
  void didUpdateWidget(PostVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postKey != widget.post.postKey ||
        postPlaybackMedia(oldWidget.post)?.url !=
            postPlaybackMedia(widget.post)?.url) {
      _release();
      _resume = Duration.zero;
      _failure = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => _release());
    }
  }

  void _release() {
    _generation++;
    _starting = false;
    _handingOff = false;
    final playback = _playback;
    _playback = null;
    if (playback == null) return;
    _resume = playback.state.position;
    _muted = playback.state.muted;
    playback.removeListener(_changed);
    _closing = playback.close().then(
      (_) => playback.dispose(),
      onError: (Object error, StackTrace stack) {
        playback.dispose();
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'BooruFlow video disposal',
          ),
        );
      },
    );
  }

  Future<void> _fullscreen(PostPlayback playback) async {
    if (_handingOff) return;
    final snapshot = playback.state;
    setState(() {
      _release();
      _handingOff = true;
    });
    final generation = _generation;
    // Surface/decoder disposal must finish before the destination creates one.
    // Removing the widget alone does not await the native player's release.
    await _closing;
    if (!mounted || generation != _generation || !_routeCurrent) return;
    setState(() => _handingOff = false);
    widget.onFullscreen?.call(snapshot.position, snapshot.muted);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeAnimation?.removeStatusListener(_routeStatus);
    _release();
    _focusScope.dispose();
    super.dispose();
  }

  void _changed() {
    final playback = _playback;
    if (!mounted || playback == null) return;
    setState(() {
      if (playback.failure case final failure?) {
        _failure = failure;
        _release();
      }
    });
  }

  Future<void> _start() async {
    if (_starting || _handingOff || _playback != null || !_routeCurrent) return;
    final media = postPlaybackMedia(widget.post);
    if (media == null) {
      setState(
        () => _failure = PostPlaybackFailure(
          StateError('No playable video variant'),
          unsupported: true,
        ),
      );
      return;
    }
    final generation = ++_generation;
    setState(() {
      _starting = true;
      _failure = null;
    });
    try {
      final playback = ref.read(postPlaybackFactoryProvider)();
      if (!mounted || generation != _generation) {
        await playback.close();
        playback.dispose();
        return;
      }
      setState(() => _playback = playback);
      playback.addListener(_changed);
      await playback.open(
        widget.post,
        media,
        looping: ref.read(videoLoopPreferenceProvider),
        position: _resume,
        muted: _muted,
      );
      if (mounted && generation == _generation) {
        setState(() => _starting = false);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _failure = PostPlaybackFailure(error);
          _release();
        });
      }
    }
  }

  void _action(Future<void> Function() action) {
    final generation = _generation;
    unawaited(
      action().catchError((Object error) {
        if (mounted && generation == _generation) {
          setState(() {
            _failure = PostPlaybackFailure(error);
            _release();
          });
        }
      }),
    );
  }

  Widget _error(PostPlaybackFailure failure) => FrostEmptyState(
    icon: appIcons.imageError,
    title: failure.unsupported
        ? t.mediaError.previewUnsupported
        : t.mediaError.videoFailed,
    actionLabel: failure.unsupported ? null : t.generic.retry,
    onAction: failure.unsupported ? null : _start,
    details: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FrostButton(
          label: t.frost.openInBrowser,
          icon: appIcons.externalLink,
          onPressed: () => performPostAction(context, () async {
            if (!await openPostUrl(
              widget.post.webUrl ?? widget.post.originalMedia.url,
            )) {
              throw StateError(t.generic.loadFailed);
            }
          }),
        ),
        const SizedBox(height: FrostGap.related),
        FrostErrorDetails(details: describeBooruError(failure.cause)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (_failure case final failure?) {
      return widget.stage(widget.post.aspectRatio, _error(failure));
    }
    final playback = _playback;
    if (playback == null) return widget.cover(_start);
    final state = playback.state;
    final controls = FrostVideoFrame(
      video: Stack(
        fit: StackFit.expand,
        children: [
          playback.buildVideo(context),
          if (!playback.ready && widget.preview != null)
            FrostMediaFrame(
              image: widget.preview,
              fit: BoxFit.contain,
              radius: 0,
            ),
        ],
      ),
      state: state,
      onPlayPause: () => _action(playback.playPause),
      onSeek: (value) => _action(() => playback.seek(value)),
      // Unknown/silent files leave a non-interactive slot; layout stays fixed.
      onMuteToggle: playback.hasAudio == true
          ? () => _action(playback.toggleMute)
          : null,
      onLoopToggle: () {
        final value = !state.looping;
        ref.read(videoLoopPreferenceProvider.notifier).set(value);
        _action(() => playback.setLoop(value));
      },
      onFullscreenToggle: widget.onFullscreen == null
          ? null
          : () => unawaited(_fullscreen(playback)),
    );
    return widget.stage(
      playback.aspectRatio ?? widget.post.aspectRatio,
      FocusScope(node: _focusScope, child: controls),
    );
  }
}
