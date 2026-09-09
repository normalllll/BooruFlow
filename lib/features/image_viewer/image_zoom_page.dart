import 'package:booruflow/features/image_viewer/widgets/zoom.dart';
import 'package:booruflow/features/posts/widgets/booru_image.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';

export 'package:booruflow/features/image_viewer/widgets/zoom.dart'
    show Zoom, ZoomState, ZoomWidgetBuilder, TransformationController;

class ImageZoomPage extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final String sourceId;
  final String postId;

  const ImageZoomPage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.sourceId,
    required this.postId,
  });

  @override
  State<ImageZoomPage> createState() => _ImageZoomPageState();
}

class _ImageZoomPageState extends State<ImageZoomPage> {
  final zoomStateKey = GlobalKey<ZoomState>();
  Matrix4? initialMatrix;

  @override
  Widget build(BuildContext context) {
    final useDesktopShell = shouldUseDesktopShell(context);

    return Scaffold(
      appBar: useDesktopShell
          ? null
          : AppBar(
              title: Text(t.imageZoom.title),
              actions: [
                AppIconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetZoom,
                ),
              ],
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return BooruImage(
                    widget.url,
                    sourceId: widget.sourceId,
                    postId: widget.postId,
                    variant: MediaVariantKind.original,
                    allowDiskCache: false,
                    width: widget.width,
                    height: widget.height,
                    imageBuilder: (Widget imageWidget) {
                      return Zoom(
                        key: zoomStateKey,
                        onMinZoom: (v) {
                          if (v) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              initialMatrix ??=
                                  zoomStateKey.currentState?.transformation;
                            });
                          }
                        },
                        maxScale: 10,
                        initTotalZoomOut: true,
                        canvasColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        colorScrollBars: Theme.of(context).primaryColor,
                        opacityScrollBars: 0.7,
                        scrollWeight: 10.0,
                        enableScroll: true,
                        doubleTapZoom: true,
                        zoomSensibility: 0.05,
                        child: imageWidget,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (useDesktopShell)
            PositionedDirectional(
              top: 12,
              end: 12,
              child: SafeArea(
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppIconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetZoom,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _resetZoom() {
    setState(() {
      if (initialMatrix != null) {
        zoomStateKey.currentState?.restoreTransformation(initialMatrix!);
      }
    });
  }
}
