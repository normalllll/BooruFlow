import 'dart:async';

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/media_presentation_cache.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

import '../displayed_media_frame.dart';
import '../stage_image_presentation.dart';
import 'post_image_frame.dart';
import 'post_media_recovery.dart';
import 'progressive_image_stream.dart';

/// Authenticated requests, cache identity and retries keep the existing Rust
/// and image-provider path. Frost owns the fade, loading shape and clipping.
class PostMedia extends ConsumerStatefulWidget {
  const PostMedia({
    required this.post,
    this.media,
    this.purpose = PostMediaPurpose.thumbnail,
    this.fit = BoxFit.cover,
    this.refreshRevision = 0,
    this.decodeWidth,
    this.onAuthenticationRequired,
    this.preview,
    this.frameBuilder,
    this.onImageReady,
    this.displayedFrame,
    this.presentation,
    this.stageBuilder,
    this.stageRadius = 0,
    this.onPlay,
    super.key,
  });
  final Post post;
  final MediaVariant? media;
  final PostMediaPurpose purpose;
  final BoxFit fit;
  final int refreshRevision;

  /// Initial decode-size hint for this media identity. Layout-only changes keep
  /// the active image/stream; they never restart preparation, decoding or fades.
  final int? decodeWidth;

  /// An already decoded source image, shown while the requested variant loads.
  final ImageProvider? preview;

  /// Wraps the decoded, uncropped frame (for example in FrostMediaHero).
  /// The wrapper is outside frame transitions. The same artwork sharpens in
  /// place without restarting a fade or replacing its Hero.
  final Widget Function(Widget image)? frameBuilder;

  /// Measures the single media boundary from its currently decoded ratio.
  /// Metadata is used until preview or requested pixels are available. The
  /// callback stays outside the image crossfade, preserving geometry and State.
  final Widget Function(BuildContext context, double aspectRatio, Widget frame)?
  stageBuilder;
  final double stageRadius;
  final VoidCallback? onPlay;
  final DisplayedMediaFrame? displayedFrame;
  final StageImagePresentation? presentation;

  /// Load-event notification. Null invalidates a previous ready snapshot.
  /// Never called in build/layout/lifecycle; stale generations are discarded.
  final ValueChanged<ImageProvider?>? onImageReady;

  /// Load-event notification for a card that supplies its own corner badge.
  /// Never invoked by build or a widget lifecycle method.
  final ValueChanged<bool>? onAuthenticationRequired;
  @override
  ConsumerState<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends ConsumerState<PostMedia> {
  ImageProvider? _provider, _readyProvider, _listenedPreview;
  Object? _preparationError;
  ImageStream? _stream, _previewStream;
  ImageStreamListener? _previewListener;
  late PostMediaGeometry _ownedGeometry;
  PostMediaGeometry get _geometry =>
      widget.presentation?.geometry ?? _ownedGeometry;
  ImageStreamListener? _listener;
  int _generation = 0, _reloadRevision = 0, _displayedGeneration = 0;
  int? _activeDecodeWidth, _decodedWidth;
  bool _failed = false, _retrying = false, _unsupported = false;
  double? _progress;
  String? _requestedUrl;
  int _presentationRevision = 0;
  bool _routeActive = true;
  ImageProvider? get _preview => widget.presentation?.preview ?? widget.preview;
  void _presentationChanged() {
    final presentation = widget.presentation;
    if (presentation == null || !mounted || !_routeActive) return;
    if (presentation.mediaFor(widget.post)?.url != _requestedUrl ||
        presentation.revision != _presentationRevision) {
      setState(_prepare);
    }
  }

  List<MediaVariant> _candidates = const [];
  int _candidateIndex = 0;
  MediaVariant? get _media => _candidates.elementAtOrNull(_candidateIndex);
  bool get _firstFrameOnly =>
      widget.purpose == PostMediaPurpose.thumbnail &&
      _media != null &&
      {MediaType.gif, MediaType.webp}.contains(postMediaType(_media!));

  @override
  void initState() {
    super.initState();
    _ownedGeometry = PostMediaGeometry(widget.post);
    widget.presentation?.addListener(_presentationChanged);
    ref.listenManual(booruSessionProvider.select((value) => value.revision), (
      _,
      _,
    ) {
      if (mounted) setState(_prepare);
    });
    _prepare();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = ModalRoute.isCurrentOf(context) ?? true;
    final resumed = active && !_routeActive;
    _routeActive = active;
    if (resumed) _presentationChanged();
  }

  @override
  void didUpdateWidget(PostMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postKey != widget.post.postKey) {
      _ownedGeometry = PostMediaGeometry(widget.post);
    }
    if (oldWidget.presentation != widget.presentation) {
      oldWidget.presentation?.removeListener(_presentationChanged);
      widget.presentation?.addListener(_presentationChanged);
    }
    Object identity(MediaVariant? media) =>
        (media?.kind, media?.url, media == null ? null : postMediaType(media));
    if (oldWidget.displayedFrame != widget.displayedFrame ||
        oldWidget.post.postKey != widget.post.postKey ||
        oldWidget.presentation != widget.presentation ||
        identity(oldWidget.media) != identity(widget.media) ||
        oldWidget.purpose != widget.purpose ||
        !listEquals(
          oldWidget.post.data.media.map(identity).toList(),
          widget.post.data.media.map(identity).toList(),
        )) {
      _prepare();
    } else {
      if (oldWidget.preview != widget.preview) _listenPreview();
      if (oldWidget.refreshRevision != widget.refreshRevision && _failed) {
        unawaited(_retry());
      }
    }
  }

  void _unlisten() {
    if (_stream case final stream? when _listener != null) {
      stream.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  void _prepare() {
    final generation = ++_generation;
    final minimum = widget.presentation?.minimumDecodeWidth;
    _activeDecodeWidth = minimum != null && (widget.decodeWidth ?? 0) < minimum
        ? minimum
        : widget.decodeWidth;
    final available = postImageVariants(widget.post, purpose: widget.purpose);
    final explicit = widget.media ?? widget.presentation?.mediaFor(widget.post);
    _requestedUrl = explicit?.url ?? available.firstOrNull?.url;
    _presentationRevision = widget.presentation?.revision ?? 0;
    _progress = null;
    _candidates = postImageVariants(
      widget.post,
      purpose: widget.purpose,
      preferred: explicit,
    );
    _candidateIndex = 0;
    _unsupported = _candidates.isEmpty;
    final retained = _preview == _readyProvider
        ? _stream
        : _preview == _listenedPreview
        ? _previewStream
        : null;
    _displayedGeneration = widget.displayedFrame?.begin() ?? 0;
    _provider = null;
    _readyProvider = null;
    _listenPreview(retained: retained);
    _unlisten();
    _preparationError = null;
    _failed = false;
    _retrying = false;
    unawaited(_resolve(generation));
  }

  void _listenPreview({ImageStream? retained}) {
    final previous = _previewStream, previousListener = _previewListener;
    _previewStream = null;
    _previewListener = null;
    _listenedPreview = _preview;
    if (_preview case final preview?) {
      final generation = _generation;
      final displayedGeneration = _displayedGeneration;
      final listener = ImageStreamListener((info, synchronousCall) {
        if (!mounted || generation != _generation) {
          info.dispose();
          return;
        }
        final ratio = info.image.width / info.image.height;
        final captured = info.image.clone();
        void publish() {
          if (mounted && generation == _generation && _readyProvider == null) {
            widget.displayedFrame?.show(
              widget.post.postKey,
              preview,
              captured,
              displayedGeneration,
            );
          }
          captured.dispose();
        }

        // Cached geometry must be used by this first layout. Only publishing
        // outside this widget crosses the lifecycle boundary on a synchronous
        // cache hit; no next-frame callback or extra frame is needed.
        if (synchronousCall) {
          scheduleMicrotask(publish);
        } else {
          publish();
        }
        info.dispose();
        if (mounted && _geometry.decoded(widget.post.postKey, ratio)) {
          setState(() {});
        }
      }, onError: (Object _, StackTrace? _) {});
      _previewStream =
          retained ??
          widget.presentation?.streamFor(
            preview,
            ref.read(mediaPresentationCacheProvider),
          ) ??
          preview.resolve(ImageConfiguration.empty);
      _previewStream!.addListener(listener);
      _previewListener = listener;
    }
    if (previousListener != null) previous?.removeListener(previousListener);
  }

  Future<void> _resolve(int generation) async {
    // A retained provider skips asynchronous preparation; cached listeners are
    // synchronous. Leave lifecycle before publishing their ready/failure events.
    await Future<void>.value();
    if (!mounted || generation != _generation) return;
    _notifyReady(null, generation);
    final media = _media;
    if (media == null) return;
    try {
      final cache = ref.read(mediaPresentationCacheProvider);
      final retained = widget.presentation?.preparedBy(cache) == true
          ? widget.presentation?.preview
          : null;
      final provider =
          retained is RustExtendedNetworkImageProvider &&
              retained.request.url == media.url &&
              (_reloadRevision == 0 ||
                  retained.reloadRevision == _reloadRevision) &&
              (widget.presentation?.minimumDecodeWidth == null ||
                  (retained.decodeWidth ?? 0) >=
                      widget.presentation!.minimumDecodeWidth!)
          ? retained
          : await cache.resolve(
              sourceId: widget.post.sourceId,
              postId: widget.post.id,
              media: media,
              decodeWidth: _activeDecodeWidth,
              retention:
                  widget.presentation?.minimumDecodeWidth != null &&
                      widget.presentation!.originalRequested
                  ? DecodedImageRetention.liveOnly
                  : null,
              reloadRevision: _reloadRevision,
              firstFrameOnly: _firstFrameOnly,
              progressive:
                  widget.purpose != PostMediaPurpose.thumbnail &&
                  {
                    MediaType.jpeg,
                    MediaType.png,
                  }.contains(postMediaType(media)),
            );
      if (!mounted || generation != _generation) return;
      _activeDecodeWidth = provider.decodeWidth;
      final listener = ImageStreamListener(
        (image, _) {
          if (mounted && generation == _generation) {
            _failed = false;
            final complete =
                _stream?.completer is! ProgressiveImageStreamCompleter ||
                (_stream!.completer! as ProgressiveImageStreamCompleter)
                    .complete;
            widget.displayedFrame?.show(
              widget.post.postKey,
              complete ? provider : image.image,
              image.image,
              _displayedGeneration,
              cachedPng: complete ? provider.cachedOriginalPng : null,
            );
            _decodedWidth = image.image.width;
            final ratio = image.image.width / image.image.height;
            final geometryChanged = _geometry.decoded(
              widget.post.postKey,
              ratio,
            );
            if (_readyProvider != provider || geometryChanged) {
              setState(() => _readyProvider = provider);
            }
            if (complete) _notifyReady(provider, generation, owner: cache);
            widget.onAuthenticationRequired?.call(false);
          }
          image.dispose();
        },
        onChunk: (event) {
          if (!mounted || generation != _generation) return;
          setState(
            () => _progress = event.expectedTotalBytes == null
                ? null
                : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          );
        },
        onError: (Object error, StackTrace? stack) =>
            _handleFailure(error, generation),
      );
      _stream =
          widget.presentation?.streamFor(provider, cache) ??
          provider.resolve(ImageConfiguration.empty);
      _stream!.addListener(listener);
      _listener = listener;
      if (mounted && generation == _generation) {
        setState(() => _provider = provider);
      }
    } catch (error) {
      _handleFailure(error, generation);
    }
  }

  void _handleFailure(Object error, int generation) {
    if (!mounted || generation != _generation) return;
    final underlying = mediaImageCause(error);
    final avifDecode =
        postMediaType(_media!) == MediaType.avif &&
        isMediaImageDecodeFailure(error);
    final fallback = postImageFallback(
      _candidates,
      _media!,
      decodeFailed: isMediaImageDecodeFailure(error),
    );
    if (fallback != null) {
      _unlisten();
      final next = ++_generation;
      setState(() {
        if (widget.presentation?.originalRequested == true) {
          _preparationError = error;
        }
        _candidateIndex = _candidates.indexOf(fallback);
        _provider = null;
        _readyProvider = null;
      });
      _notifyReady(null, next);
      unawaited(_resolve(next));
      return;
    }
    widget.onAuthenticationRequired?.call(
      postMediaRequiresAuthentication(error),
    );
    setState(() {
      _preparationError = error;
      _failed = true;
      _readyProvider = null;
      _unsupported =
          avifDecode ||
          underlying is BooruError &&
              underlying.userMessageKey == 'booru.error.previewUnsupported';
    });
    if (_preview == null) {
      widget.displayedFrame?.invalidate(_displayedGeneration);
    } else {
      _listenPreview();
    }
    _notifyReady(null, generation);
  }

  void _notifyReady(
    ImageProvider? provider,
    int generation, {
    MediaPresentationCache? owner,
  }) {
    if (!mounted || generation != _generation) return;
    if (provider != null && _media != null) {
      widget.presentation?.retainFrame(
        provider,
        _stream!,
        preparationOwner: owner!,
      );
      widget.presentation?.ready(
        widget.post,
        _media!,
        provider,
        decodedWidth: _decodedWidth,
      );
    } else if (_failed) {
      widget.presentation?.failed();
    }
    widget.onImageReady?.call(provider);
  }

  Future<void> _retry() async {
    final media = _media;
    if (_retrying || media == null) return;
    final generation = _generation;
    setState(() => _retrying = true);
    widget.presentation?.retryStarted();
    try {
      final provider = _provider;
      if (provider is RustExtendedNetworkImageProvider) {
        await provider.clearCache();
      }
      if (!mounted || generation != _generation) return;
      ref
          .read(mediaPresentationCacheProvider)
          .evict(
            sourceId: widget.post.sourceId,
            postId: widget.post.id,
            media: media,
            firstFrameOnly: _firstFrameOnly,
            progressive:
                widget.purpose != PostMediaPurpose.thumbnail &&
                {MediaType.jpeg, MediaType.png}.contains(postMediaType(media)),
          );
      setState(() {
        _reloadRevision++;
        _prepare();
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _preparationError = error;
        _failed = true;
        _retrying = false;
      });
      _notifyReady(null, generation);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('requestedVariant', _media?.kind));
    properties.add(
      FlagProperty(
        'imageReady',
        value: _readyProvider != null,
        ifTrue: 'decoded',
        ifFalse: 'pending',
      ),
    );
    properties.add(
      FlagProperty(
        'hasProvider',
        value: _provider != null,
        ifTrue: 'prepared',
        ifFalse: 'preparing',
      ),
    );
    properties.add(
      IntProperty('decodeWidth', _activeDecodeWidth, defaultValue: null),
    );
    properties.add(IntProperty('generation', _generation));
    properties.add(
      DiagnosticsProperty<Type>(
        'errorType',
        _preparationError?.runtimeType,
        defaultValue: null,
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    widget.presentation?.removeListener(_presentationChanged);
    _unlisten();
    if (_previewStream case final stream? when _previewListener != null) {
      stream.removeListener(_previewListener!);
    }
    super.dispose();
  }

  Widget _placeholder(BuildContext context, double? progress) => Stack(
    fit: StackFit.expand,
    children: [
      FrostMediaFrame.skeleton(
        aspectRatio: null,
        radius: widget.stageBuilder == null
            ? FrostRadius.lg
            : widget.stageRadius,
      ),
      if (progress != null)
        Align(
          alignment: Alignment.topCenter,
          child: FrostProgressBar(
            value: progress,
            semanticLabel: t.frost.loading,
          ),
        ),
    ],
  );
  Widget _recovery(Object? error, PostMediaRecoveryStyle style) =>
      PostMediaRecovery(
        post: widget.post,
        purpose: widget.purpose,
        error: error,
        style: style,
        retrying: _retrying,
        onRetry: _retry,
        onPlay: widget.onPlay,
        showsAuthenticationBadge: widget.onAuthenticationRequired == null,
      );

  Widget _decodedFrame(ImageProvider provider) {
    final image = PostImageFrame(
      provider: provider,
      stream: provider == _provider || provider == _readyProvider
          ? _stream
          : provider == _listenedPreview
          ? _previewStream
          : null,
      fit: widget.fit,
      placeholderBuilder: (context) => _placeholder(context, _progress),
      errorBuilder: (error) => _recovery(error, PostMediaRecoveryStyle.failure),
    );
    return widget.stageBuilder == null
        ? FrostMediaFrame(radius: 0, child: image)
        : image;
  }

  @override
  Widget build(BuildContext context) {
    final error = _preparationError;
    final ready = _readyProvider;
    final visible = ready ?? _preview;
    Widget content;
    if (_unsupported) {
      content = _recovery(error, PostMediaRecoveryStyle.unsupported);
    } else if (visible != null) {
      content = _decodedFrame(visible);
      if (widget.purpose != PostMediaPurpose.thumbnail &&
          postMediaFormat(widget.post) == PostMediaFormat.video) {
        content = Stack(
          fit: StackFit.expand,
          children: [
            content,
            Center(
              child: FrostButton.icon(
                icon: FrostIconSet.of(context).play,
                label: t.frost.play,
                style: FrostIconButtonStyle.onMedia,
                size: FrostControlSize.large,
                onPressed:
                    widget.onPlay ??
                    () => openPostMediaInBrowser(context, widget.post),
              ),
            ),
          ],
        );
      }
      if (error != null) {
        content = Stack(
          fit: StackFit.expand,
          children: [
            content,
            _recovery(
              error,
              widget.presentation == null
                  ? PostMediaRecoveryStyle.overlay
                  : PostMediaRecoveryStyle.banner,
            ),
          ],
        );
      }
    } else if (error != null) {
      content = _recovery(error, PostMediaRecoveryStyle.failure);
    } else if (_provider case final provider?) {
      content = _decodedFrame(provider);
    } else {
      content = _placeholder(context, null);
    }
    if (visible != null &&
        widget.presentation?.loadingOriginal(widget.post) == true) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Align(
            alignment: Alignment.topCenter,
            child: _progress == null
                ? FrostActivityIndicator(semanticLabel: t.frost.loading)
                : FrostProgressBar(
                    value: _progress!,
                    semanticLabel: t.frost.loading,
                  ),
          ),
        ],
      );
    }
    // A new work or recovery from loading/error may fade. More pixels of the
    // same work replace immediately, including progressive scans and originals.
    Widget frame = FrostLayoutCrossfade(
      layoutIdentity: (
        widget.post.postKey,
        _unsupported
            ? _MediaFrameState.unsupported
            : visible != null
            ? _MediaFrameState.image
            : error != null
            ? _MediaFrameState.failed
            : _MediaFrameState.loading,
      ),
      duration: FrostMotion.imageFade,
      settleDuration: Duration.zero,
      child: content,
    );
    if (widget.frameBuilder case final wrap?) frame = wrap(frame);
    final stage = widget.stageBuilder;
    if (stage == null) return frame;
    final ratio = _geometry.aspectRatio;
    return stage(
      context,
      ratio,
      FrostMediaFrame(radius: widget.stageRadius, child: frame),
    );
  }
}

enum _MediaFrameState { loading, image, failed, unsupported }
