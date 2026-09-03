import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yande_gui/services/yande_network_policy.dart';

class YandeImage extends StatefulWidget {
  const YandeImage(
    this.url, {
    super.key,
    this.color,
    this.colorBlendMode,
    this.width,
    this.height,
    this.fit,
    this.imageBuilder,
    this.placeholderWidget,
  });

  final String url;
  final Color? color;
  final BlendMode? colorBlendMode;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(Widget imageWidget)? imageBuilder;
  final Widget? placeholderWidget;

  @override
  State<YandeImage> createState() => _YandeImageState();
}

class _YandeImageState extends State<YandeImage> {
  YandeNetworkRoute get _route => YandeNetworkPolicy.route(
    Uri.parse(widget.url),
    // The stock ExtendedNetworkImageProvider cannot override DNS while
    // retaining the original TLS SNI. An IP URL fails before HTTP headers.
    permitBypass: false,
    headers: YandeNetworkPolicy.imageHeaders,
  );

  ExtendedNetworkImageProvider _createImageProvider(YandeNetworkRoute route) {
    return ExtendedNetworkImageProvider(
      route.requestUri.toString(),
      cache: true,
      cacheKey: keyToMd5(widget.url),
      printError: true,
      headers: route.headers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    return ExtendedImage(
      key: ValueKey('${route.requestUri}|${route.bypassed}'),
      image: _createImageProvider(route),
      handleLoadingProgress: true,
      loadStateChanged: _buildLoadState,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      clearMemoryCacheWhenDispose: false,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.fitWidth,
    );
  }

  Widget? _buildLoadState(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        final event = state.loadingProgress;
        final total = event?.expectedTotalBytes;
        final progress = total == null
            ? null
            : total == 0
            ? 1.0
            : event!.cumulativeBytesLoaded / total;
        return _buildPlaceholder(progress: progress);
      case LoadState.completed:
        return widget.imageBuilder?.call(state.completedWidget);
      case LoadState.failed:
        return Center(
          child: IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: state.reLoadImage,
          ),
        );
    }
  }

  Widget _buildPlaceholder({double? progress}) {
    final placeholder = widget.placeholderWidget;
    if (placeholder != null) {
      return Stack(
        children: [
          placeholder,
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: LinearProgressIndicator(value: progress),
          ),
        ],
      );
    }
    return _buildSkeletonPlaceholder(progress: progress);
  }

  Widget _buildSkeletonPlaceholder({double? progress}) {
    final skeleton = LayoutBuilder(
      builder: (context, constraints) {
        final skeletonWidth =
            widget.width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : 96.0);
        final skeletonHeight =
            widget.height ??
            (constraints.hasBoundedHeight
                ? constraints.maxHeight
                : skeletonWidth);
        return Skeletonizer.zone(
          child: Bone(
            width: skeletonWidth,
            height: skeletonHeight,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
    return Stack(
      children: [
        skeleton,
        Center(child: CircularProgressIndicator(value: progress)),
      ],
    );
  }
}
