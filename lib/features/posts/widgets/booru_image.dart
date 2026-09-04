import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_service.dart';
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

  @override
  State<BooruImage> createState() => _BooruImageState();
}

class _BooruImageState extends State<BooruImage> {
  Future<MediaRequestDto>? _request;

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
        oldWidget.url != widget.url) {
      _prepare();
    }
  }

  void _prepare() {
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
          cache: true,
          cacheKey: keyToMd5('BooruFlow:${widget.url}'),
          retries: 1,
        ),
      );
    }
    return FutureBuilder<MediaRequestDto>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _error(() => setState(_prepare), error: snapshot.error);
        }
        final request = snapshot.data;
        if (request == null) return _placeholder();
        return _image(RustExtendedNetworkImageProvider(request: request));
      },
    );
  }

  Widget _image(ImageProvider provider) {
    return ExtendedImage(
      image: provider,
      handleLoadingProgress: true,
      loadStateChanged: (state) {
        return switch (state.extendedImageLoadState) {
          LoadState.loading => _placeholder(progress: _progress(state)),
          LoadState.completed => widget.imageBuilder?.call(
            state.completedWidget,
          ),
          LoadState.failed => _error(
            state.reLoadImage,
            error: state.lastException,
          ),
        };
      },
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.fitWidth,
    );
  }

  Widget _error(VoidCallback retry, {Object? error}) => Center(
    child: AppIconButton(
      icon: const Icon(Icons.refresh_outlined),
      tooltip: error == null ? null : describeBooruError(error),
      onPressed: retry,
    ),
  );

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
