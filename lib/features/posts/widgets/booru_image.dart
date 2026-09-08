import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/booru/web_challenge_button.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';

class BooruImage extends StatefulWidget {
  const BooruImage(
    this.url, {
    super.key,
    this.sourceId,
    this.postId,
    this.variant = MediaVariantKind.preview,
    this.allowDiskCache = true,
    this.color,
    this.colorBlendMode,
    this.width,
    this.height,
    this.fit,
    this.imageBuilder,
    this.placeholderWidget,
    this.decodeWidth,
    this.refreshRevision = 0,
  });

  final String url;
  final String? sourceId;
  final String? postId;
  final MediaVariantKind variant;
  final bool allowDiskCache;
  final Color? color;
  final BlendMode? colorBlendMode;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(Widget imageWidget)? imageBuilder;
  final Widget? placeholderWidget;
  final int? decodeWidth;
  final int refreshRevision;

  @override
  State<BooruImage> createState() => _BooruImageState();
}

class _BooruImageState extends State<BooruImage> {
  Future<MediaRequest>? _request;
  bool _failed = false;
  bool _retrying = false;
  int _reloadRevision = 0;
  ImageProvider? _provider;

  bool get _usesRust => widget.sourceId != null && widget.postId != null;

  @override
  void initState() {
    super.initState();
    BooruService.instance.revision.addListener(_handleEngineRevision);
    _prepare();
  }

  @override
  void dispose() {
    BooruService.instance.revision.removeListener(_handleEngineRevision);
    super.dispose();
  }

  void _handleEngineRevision() {
    if (mounted && _usesRust) setState(_prepare);
  }

  @override
  void didUpdateWidget(covariant BooruImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceId != widget.sourceId ||
        oldWidget.postId != widget.postId ||
        oldWidget.variant != widget.variant ||
        oldWidget.allowDiskCache != widget.allowDiskCache ||
        oldWidget.url != widget.url) {
      _prepare();
    } else if (oldWidget.refreshRevision != widget.refreshRevision && _failed) {
      _retry();
    }
  }

  void _prepare() {
    _failed = false;
    _provider = null;
    _request = _usesRust
        ? BooruService.instance.engine.prepareMediaUrl(
            sourceId: widget.sourceId!,
            postId: widget.postId!,
            variant: widget.variant,
            url: widget.url,
            allowDiskCache: widget.allowDiskCache,
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_usesRust) {
      return _image(
        ExtendedNetworkImageProvider(
          widget.url,
          cache: widget.allowDiskCache,
          cacheKey: keyToMd5('BooruFlow:${widget.url}'),
          retries: 1,
        ),
      );
    }
    return FutureBuilder<MediaRequest>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder();
        }
        if (snapshot.hasError) {
          _failed = true;
          return _error(_retry, error: snapshot.error);
        }
        final request = snapshot.data;
        if (request == null) return _placeholder();
        return _image(
          RustExtendedNetworkImageProvider(
            request: request,
            decodeWidth: widget.decodeWidth,
            reloadRevision: _reloadRevision,
          ),
        );
      },
    );
  }

  Widget _image(ImageProvider provider) {
    _provider = provider;
    return ExtendedImage(
      key: ValueKey(_reloadRevision),
      image: provider,
      handleLoadingProgress: true,
      loadStateChanged: (state) {
        _failed = state.extendedImageLoadState == LoadState.failed;
        return switch (state.extendedImageLoadState) {
          LoadState.loading => _placeholder(progress: _progress(state)),
          LoadState.completed => widget.imageBuilder?.call(
            state.completedWidget,
          ),
          LoadState.failed => _error(_retry, error: state.lastException),
        };
      },
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.fitWidth,
    );
  }

  Future<void> _retry() async {
    if (_retrying) return;
    _retrying = true;
    final provider = _provider;
    final url = widget.url;
    try {
      if (provider is RustExtendedNetworkImageProvider) {
        await provider.clearCache();
      } else {
        await provider?.evict();
        if (!_usesRust) {
          await clearDiskCachedImage(url, cacheKey: keyToMd5('BooruFlow:$url'));
        }
      }
    } finally {
      _retrying = false;
      if (mounted && widget.url == url) {
        setState(() {
          _reloadRevision++;
          _prepare();
        });
      }
    }
  }

  Widget _error(VoidCallback retry, {Object? error}) => Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (challengeError(
              error is MediaImageException ? error.cause : error,
            )?.sourceId
            case final source?)
          WebChallengeButton(sourceId: source, compact: true),
        AppIconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: t.generic.retry,
          onPressed: retry,
        ),
        AppIconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: t.mediaError.details,
          onPressed: () => _showError(error, retry),
        ),
      ],
    ),
  );

  Future<void> _showError(Object? error, VoidCallback retry) async {
    final details = error is MediaImageException
        ? error.toString()
        : 'source=${widget.sourceId ?? "unknown"} · post=${widget.postId ?? "unknown"} · variant=${widget.variant.name}\n${describeBooruError(error)}';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.mediaError.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error is MediaImageException && error.stage == 'decode'
                      ? t.mediaError.decodeFailed
                      : t.generic.loadFailed,
                ),
                const SizedBox(height: 12),
                SelectableText(details),
              ],
            ),
          ),
        ),
        actions: [
          if (challengeError(
                error is MediaImageException ? error.cause : error,
              )?.sourceId
              case final source?)
            WebChallengeButton(
              sourceId: source,
              onResolved: () => Navigator.pop(context),
            ),
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: details)),
            child: Text(t.mediaError.copyDetails),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.generic.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              retry();
            },
            child: Text(t.generic.retry),
          ),
        ],
      ),
    );
  }

  double? _progress(ExtendedImageState state) {
    final event = state.loadingProgress;
    final total = event?.expectedTotalBytes;
    if (event == null || total == null || total <= 0) return null;
    return event.cumulativeBytesLoaded / total;
  }

  Widget _placeholder({double? progress}) {
    final base =
        widget.placeholderWidget ??
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                widget.width ??
                (constraints.hasBoundedWidth ? constraints.maxWidth : 96.0);
            final height =
                widget.height ??
                (constraints.hasBoundedHeight ? constraints.maxHeight : width);
            return Skeletonizer.zone(
              child: Bone(
                width: width,
                height: height,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          },
        );
    return Stack(
      children: [
        base,
        if (progress != null)
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: LinearProgressIndicator(value: progress),
          ),
      ],
    );
  }
}
