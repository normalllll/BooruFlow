import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/src/rust/api/yande_client.dart';

class YandeImage extends StatefulWidget {
  final String url;
  final Color? color;

  final BlendMode? colorBlendMode;

  final double? width;

  final double? height;

  final BoxFit? fit;

  final Widget Function(Widget imageWidget)? imageBuilder;

  final Widget? placeholderWidget;

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

  @override
  State<YandeImage> createState() => _YandeImageState();
}

class _YandeImageState extends State<YandeImage> {
  late _YandeImageDownloadScope _downloadScope;
  late ExtendedNetworkImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _downloadScope = _YandeImageDownloadScope.fallback;
    _imageProvider = _createImageProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _YandeImageDownloadScope.of(context);
    if (!identical(_downloadScope, scope)) {
      _downloadScope = scope;
      _imageProvider = _createImageProvider();
    }
  }

  @override
  void didUpdateWidget(covariant YandeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageProvider = _createImageProvider();
    }
  }

  ExtendedNetworkImageProvider _createImageProvider() {
    final url = widget.url;
    final downloadScope = _downloadScope;

    return ExtendedNetworkImageProvider(
      url,
      cache: true,
      printError: false,
      bytesLoader: (void Function(ImageChunkEvent event) chunkEvent) async {
        final cancelToken = downloadScope.createToken();

        try {
          return await yandeClient.downloadToMemoryWithCancel(
            url: url,
            progressCallback: (BigInt received, BigInt total) {
              chunkEvent(
                ImageChunkEvent(
                  cumulativeBytesLoaded: received.toInt(),
                  expectedTotalBytes: total.toInt(),
                ),
              );
            },
            cancelToken: cancelToken,
          );
        } finally {
          downloadScope.remove(cancelToken);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage(
      image: _imageProvider,
      handleLoadingProgress: true,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            if (state.loadingProgress case ImageChunkEvent event?) {
              if (event.expectedTotalBytes case int total?) {
                double progress = switch (total == 0) {
                  true => 1.0,
                  false => event.cumulativeBytesLoaded / total,
                };
                if (widget.placeholderWidget case Widget placeholder?) {
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
                } else {
                  return _buildSkeletonPlaceholder(progress: progress);
                }
              }
            } else {
              if (widget.placeholderWidget case Widget placeholder?) {
                return Stack(
                  children: [
                    placeholder,
                    const Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      child: LinearProgressIndicator(),
                    ),
                  ],
                );
              } else {
                return _buildSkeletonPlaceholder();
              }
            }
            return _buildSkeletonPlaceholder();
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
      },
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      clearMemoryCacheWhenDispose: false,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.fitWidth,
    );
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

    if (progress == null) {
      return skeleton;
    }

    return Stack(
      children: [
        skeleton,
        Center(child: CircularProgressIndicator(value: progress)),
      ],
    );
  }
}

class _YandeImageDownloadScope {
  static final Map<Route<dynamic>, _YandeImageDownloadScope> _routeScopes = {};
  static final _YandeImageDownloadScope fallback = _YandeImageDownloadScope();

  final Set<DownloadCancelToken> _tokens = {};
  bool _isCancelled = false;

  static _YandeImageDownloadScope of(BuildContext context) {
    final route = ModalRoute.of(context);

    if (route == null) {
      return fallback;
    }

    return _routeScopes.putIfAbsent(route, () {
      final scope = _YandeImageDownloadScope();

      route.completed.whenComplete(() {
        scope.cancelAll();
        _routeScopes.remove(route);
      });

      return scope;
    });
  }

  DownloadCancelToken createToken() {
    final token = DownloadCancelToken();
    _tokens.add(token);

    if (_isCancelled) {
      token.cancel();
    }

    return token;
  }

  void remove(DownloadCancelToken token) {
    _tokens.remove(token);
  }

  void cancelAll() {
    if (_isCancelled) {
      return;
    }

    _isCancelled = true;

    for (final token in _tokens.toList(growable: false)) {
      token.cancel();
    }

    _tokens.clear();
  }
}
