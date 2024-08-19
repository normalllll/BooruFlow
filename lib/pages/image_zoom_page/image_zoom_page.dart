import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:vector_math/vector_math_64.dart' show Quad, Vector3, Matrix4;
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/i18n.dart';

class ImageZoomPage extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const ImageZoomPage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<ImageZoomPage> createState() => _ImageZoomPageState();
}

class _ImageZoomPageState extends State<ImageZoomPage> {
  final zoomStateKey = GlobalKey<_ZoomState>();
  Matrix4? initialMatrix;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.imageZoom.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                if (initialMatrix != null) {
                  zoomStateKey.currentState?._transformationController?.value = initialMatrix!;
                  zoomStateKey.currentState?._updateScroll(initialMatrix!);
                }
              });
            },
          ),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return YandeImage(
              widget.url,
              width: widget.width,
              height: widget.height,
              imageBuilder: (Widget imageWidget) {
                return Zoom(
                  key: zoomStateKey,
                  onMinZoom: (v) {
                    if (v) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        initialMatrix ??= zoomStateKey.currentState?._transformationController?.value;
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
    );
  }
}

// From https://github.com/semakers/zoom-widget
// This project does not provide controller such as maximize, minimize, and reset. It can only be copied into the project for use.

typedef ZoomWidgetBuilder = Widget Function(BuildContext context, Quad viewport);

@immutable
class Zoom extends StatefulWidget {
  Zoom({
    this.backgroundColor = Colors.grey,
    this.canvasColor = Colors.white,
    this.centerOnScale = true,
    required this.child,
    this.colorScrollBars = Colors.black12,
    this.doubleTapAnimDuration = const Duration(milliseconds: 300),
    this.doubleTapScaleChange = 1.1,
    this.doubleTapZoom = true,
    this.enableScroll = true,
    this.initPosition,
    this.initScale,
    this.initTotalZoomOut = false,
    super.key,
    this.maxScale = 2.5,
    this.maxZoomHeight,
    this.maxZoomWidth,
    this.onPositionUpdate,
    this.onScaleUpdate,
    this.onPanUpPosition,
    this.onMinZoom,
    this.onTap,
    this.opacityScrollBars = 0.5,
    this.radiusScrollBars = 4,
    this.scrollWeight = 10,
    this.transformationController,
    this.zoomSensibility = 1.0,
  })  : assert(maxScale > 0),
        assert(!maxScale.isNaN);

  final Color backgroundColor;
  final Color canvasColor;
  final bool centerOnScale;
  final Widget child;
  final Color colorScrollBars;
  final Duration doubleTapAnimDuration;
  final double doubleTapScaleChange;
  final bool doubleTapZoom;
  final bool enableScroll;
  final Offset? initPosition;
  final double? initScale;
  final bool initTotalZoomOut;
  final double maxScale;
  final double? maxZoomHeight;
  final double? maxZoomWidth;
  final Function(Offset)? onPositionUpdate;
  final Function(double, double)? onScaleUpdate;
  final Function(Offset)? onPanUpPosition;
  final Function(bool)? onMinZoom;
  final Function()? onTap;
  final double opacityScrollBars;
  final double radiusScrollBars;
  final double scrollWeight;
  final TransformationController? transformationController;
  final double zoomSensibility;

  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
    final double lengthSquared = math.pow(l2.x - l1.x, 2.0).toDouble() + math.pow(l2.y - l1.y, 2.0).toDouble();

    if (lengthSquared == 0) {
      return l1;
    }

    final Vector3 l1P = point - l1;
    final Vector3 l1L2 = l2 - l1;
    final double fraction = (l1P.dot(l1L2) / lengthSquared).clamp(0.0, 1.0);
    return l1 + l1L2 * fraction;
  }

  static Quad getAxisAlignedBoundingBox(Quad quad) {
    final double minX = math.min(
      quad.point0.x,
      math.min(
        quad.point1.x,
        math.min(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double minY = math.min(
      quad.point0.y,
      math.min(
        quad.point1.y,
        math.min(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    final double maxX = math.max(
      quad.point0.x,
      math.max(
        quad.point1.x,
        math.max(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double maxY = math.max(
      quad.point0.y,
      math.max(
        quad.point1.y,
        math.max(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    return Quad.points(
      Vector3(minX, minY, 0),
      Vector3(maxX, minY, 0),
      Vector3(maxX, maxY, 0),
      Vector3(minX, maxY, 0),
    );
  }

  static bool pointIsInside(Vector3 point, Quad quad) {
    final Vector3 aM = point - quad.point0;
    final Vector3 aB = quad.point1 - quad.point0;
    final Vector3 aD = quad.point3 - quad.point0;

    final double aMAB = aM.dot(aB);
    final double aBAB = aB.dot(aB);
    final double aMAD = aM.dot(aD);
    final double aDAD = aD.dot(aD);

    return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
  }

  static Vector3 getNearestPointInside(Vector3 point, Quad quad) {
    if (pointIsInside(point, quad)) {
      return point;
    }

    final List<Vector3> closestPoints = <Vector3>[
      Zoom.getNearestPointOnLine(point, quad.point0, quad.point1),
      Zoom.getNearestPointOnLine(point, quad.point1, quad.point2),
      Zoom.getNearestPointOnLine(point, quad.point2, quad.point3),
      Zoom.getNearestPointOnLine(point, quad.point3, quad.point0),
    ];
    double minDistance = double.infinity;
    late Vector3 closestOverall;
    for (final Vector3 closePoint in closestPoints) {
      final double distance = math.sqrt(
        math.pow(point.x - closePoint.x, 2) + math.pow(point.y - closePoint.y, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestOverall = closePoint;
      }
    }
    return closestOverall;
  }

  @override
  State<Zoom> createState() => _ZoomState();
}

class _ZoomState extends State<Zoom> with TickerProviderStateMixin, WidgetsBindingObserver {
  TransformationController? _transformationController;

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();
  Animation<Offset>? _animation;
  late AnimationController _controller;
  Animation<double>? _scaleAnimation;
  late AnimationController _scaleController;
  Axis? _panAxis;
  Offset? _referenceFocalPoint;
  double? _scaleStart;
  _GestureType? _gestureType;
  ValueNotifier<_ScrollBarData> verticalScrollNotifier = ValueNotifier(_ScrollBarData(length: 0, position: 0));
  ValueNotifier<_ScrollBarData> horizontalScrollNotifier = ValueNotifier(_ScrollBarData(length: 0, position: 0));
  Size parentSize = Size.zero;
  Size childSize = Size.zero;
  Orientation? _orientation;
  Offset? _doubleTapFocalPoint;
  bool doubleTapZoomIn = true;
  bool firstDraw = true;

  static const double _kDrag = 0.0000135;

  Rect get _boundaryRect {
    assert(_childKey.currentContext != null);

    final Rect boundaryRect = EdgeInsets.zero.inflateRect(Offset.zero & childSize);
    assert(
      !boundaryRect.isEmpty,
      "Zoom's child must have nonzero dimensions.",
    );

    assert(
      boundaryRect.isFinite || (boundaryRect.left.isInfinite && boundaryRect.top.isInfinite && boundaryRect.right.isInfinite && boundaryRect.bottom.isInfinite),
      'boundaryRect must either be infinite in all directions or finite in all directions.',
    );
    return boundaryRect;
  }

  Rect get _viewport {
    assert(_parentKey.currentContext != null);
    final RenderBox parentRenderBox = _parentKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  double _getScrollPercent(Matrix4 matrix, {required _ScrollType scrollType}) {
    switch (scrollType) {
      case _ScrollType.horizontal:
        return _getMatrixTranslation(matrix).dx.abs() / ((childSize.width * matrix.getMaxScaleOnAxis()) - parentSize.width) * 100.0;

      case _ScrollType.vertical:
        return _getMatrixTranslation(matrix).dy.abs() / ((childSize.height * matrix.getMaxScaleOnAxis()) - parentSize.height) * 100.0;
    }
  }

  double _getScrollBarLength(Matrix4 matrix, {required _ScrollType scrollType}) {
    double percent = 0;
    switch (scrollType) {
      case _ScrollType.horizontal:
        percent = (parentSize.width / (childSize.width * matrix.getMaxScaleOnAxis()));
        return parentSize.width * percent;

      case _ScrollType.vertical:
        percent = (parentSize.height / (childSize.height * matrix.getMaxScaleOnAxis()));
        return parentSize.height * percent;
    }
  }

  void onDisabledScrolls() {
    if (horizontalScrollNotifier.value.length == 0 &&
        horizontalScrollNotifier.value.position == 0 &&
        verticalScrollNotifier.value.length == 0 &&
        verticalScrollNotifier.value.position == 0) {
      widget.onMinZoom?.call(true);
    } else {
      widget.onMinZoom?.call(false);
    }
  }

  void _updateScroll(Matrix4 matrix) {
    if (childSize.width * matrix.getMaxScaleOnAxis() > parentSize.width + (parentSize.width * 0.01)) {
      var horizontalPercent = _getScrollPercent(matrix, scrollType: _ScrollType.horizontal);

      final horizontalLength = _getScrollBarLength(matrix, scrollType: _ScrollType.horizontal);

      horizontalScrollNotifier.value = _ScrollBarData(length: horizontalLength, position: (horizontalPercent / 100.0) * (parentSize.width - horizontalLength));
    } else {
      horizontalScrollNotifier.value = _ScrollBarData(length: 0, position: 0);
      onDisabledScrolls();
    }

    if (childSize.height * matrix.getMaxScaleOnAxis() > parentSize.height + (parentSize.height * 0.01)) {
      final verticalPercent = _getScrollPercent(matrix, scrollType: _ScrollType.vertical);

      final verticalLength = _getScrollBarLength(matrix, scrollType: _ScrollType.vertical);

      verticalScrollNotifier.value = _ScrollBarData(length: verticalLength, position: (verticalPercent / 100) * (parentSize.height - verticalLength));
    } else {
      verticalScrollNotifier.value = _ScrollBarData(length: 0, position: 0);
      onDisabledScrolls();
    }
  }

  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation, {bool fixOffset = false}) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    final Offset alignedTranslation = translation;

    final Matrix4 nextMatrix = matrix.clone()
      ..translate(
        alignedTranslation.dx,
        alignedTranslation.dy,
      );

    final Quad nextViewport = _transformViewport(nextMatrix, _viewport);

    if (_boundaryRect.isInfinite && !fixOffset) {
      _updateScroll(nextMatrix);
      widget.onPositionUpdate?.call(_getMatrixTranslation(nextMatrix));
      return nextMatrix;
    }

    final Quad boundariesAabbQuad = _getAxisAlignedBoundingBoxWithRotation(
      _boundaryRect,
      0.0,
    );

    final Offset offendingDistance = _exceedsBy(boundariesAabbQuad, nextViewport);
    if (offendingDistance == Offset.zero) {
      _updateScroll(nextMatrix);
      widget.onPositionUpdate?.call(_getMatrixTranslation(nextMatrix));
      return nextMatrix;
    }

    final Offset nextTotalTranslation = _getMatrixTranslation(nextMatrix);
    final double currentScale = matrix.getMaxScaleOnAxis();
    final Offset correctedTotalTranslation = Offset(
      nextTotalTranslation.dx - offendingDistance.dx * currentScale,
      nextTotalTranslation.dy - offendingDistance.dy * currentScale,
    );

    final Matrix4 correctedMatrix = matrix.clone()
      ..setTranslation(Vector3(
        correctedTotalTranslation.dx,
        correctedTotalTranslation.dy,
        0.0,
      ));

    final Quad correctedViewport = _transformViewport(correctedMatrix, _viewport);
    final Offset offendingCorrectedDistance = _exceedsBy(boundariesAabbQuad, correctedViewport);
    if (offendingCorrectedDistance == Offset.zero && !fixOffset) {
      _updateScroll(correctedMatrix);
      widget.onPositionUpdate?.call(_getMatrixTranslation(correctedMatrix));
      return correctedMatrix;
    }

    if (offendingCorrectedDistance.dx != 0.0 &&
        offendingCorrectedDistance.dy != 0.0 &&
        !fixOffset &&
        (childSize.width > parentSize.width || childSize.height > parentSize.height)) {
      return matrix.clone();
    }

    final Offset unidirectionalCorrectedTotalTranslation = Offset(
      offendingCorrectedDistance.dx == 0.0 ? correctedTotalTranslation.dx : 0.0,
      offendingCorrectedDistance.dy == 0.0 ? correctedTotalTranslation.dy : 0.0,
    );
    final verticalMidLength = (parentSize.height - childSize.height * matrix.getMaxScaleOnAxis()) / 2;
    final horizontalMidLength = (parentSize.width - (childSize.width * matrix.getMaxScaleOnAxis())) / 2;

    double horizontalMid = 0;
    double verticalMid = 0;

    void calculateMids(bool sizeCondition) {
      if (sizeCondition) {
        verticalMid = verticalMidLength;
        if (childSize.width < parentSize.width) {
          horizontalMid = horizontalMidLength;
        }
      } else {
        horizontalMid = horizontalMidLength;
        if (childSize.height < parentSize.height) {
          verticalMid = verticalMidLength;
        }
      }
    }

    if (childSize.width == childSize.height) {
      calculateMids(parentSize.height > parentSize.width);
    } else {
      calculateMids(childSize.height < childSize.width);
    }

    final midMatrix = matrix.clone()
      ..setTranslation(Vector3(
        unidirectionalCorrectedTotalTranslation.dx +
            (widget.centerOnScale
                ? horizontalMid < 0
                    ? 0
                    : horizontalMid
                : 0),
        unidirectionalCorrectedTotalTranslation.dy +
            (widget.centerOnScale
                ? verticalMid < 0
                    ? 0
                    : verticalMid
                : 0),
        0.0,
      ));
    _updateScroll(midMatrix);
    widget.onPositionUpdate?.call(_getMatrixTranslation(midMatrix));
    return midMatrix;
  }

  Matrix4 _matrixScale(Matrix4 matrix, double scale, {bool fixScale = false}) {
    double sensibleScale = scale > 1.0 ? 1.0 + ((scale - 1.0) * widget.zoomSensibility) : 1.0 - ((1.0 - scale) * widget.zoomSensibility);
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    final nextScale = (matrix.clone()..scale(sensibleScale)).getMaxScaleOnAxis();

    if (childSize.width == childSize.height) {
      if (parentSize.height > parentSize.width) {
        if ((childSize.width * nextScale) < parentSize.width && nextScale < 1.0) {
          return matrix.clone();
        }
      } else {
        if ((childSize.height * nextScale) < parentSize.height && nextScale < 1.0) {
          return matrix.clone();
        }
      }
    } else {
      if (childSize.height < childSize.width) {
        if ((childSize.width * nextScale) < parentSize.width && nextScale < 1.0) {
          return matrix.clone();
        }
      } else {
        if ((childSize.height * nextScale) < parentSize.height && nextScale < 1.0) {
          return matrix.clone();
        }
      }
    }

    if (matrix.getMaxScaleOnAxis() > widget.maxScale && sensibleScale > 1) {
      return matrix.clone();
    }
    final newMatrix = matrix.clone()..scale(fixScale ? scale : sensibleScale.abs());

    widget.onScaleUpdate?.call(
      fixScale ? scale : sensibleScale.abs(),
      newMatrix.getMaxScaleOnAxis(),
    );

    return newMatrix;
  }

  bool _gestureIsSupported(_GestureType? gestureType) {
    switch (gestureType) {
      case _GestureType.scale:
        return true;

      case _GestureType.pan:
      case null:
        return true;
    }
  }

  _GestureType _getGestureType(ScaleUpdateDetails details) {
    final double scale = details.scale;
    if ((scale - 1).abs() != 0) {
      return _GestureType.scale;
    } else {
      return _GestureType.pan;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
      _animation?.removeListener(_onAnimate);
      _animation = null;
    }

    _gestureType = null;
    _panAxis = null;
    _scaleStart = _transformationController!.value.getMaxScaleOnAxis();
    _referenceFocalPoint = _transformationController!.toScene(
      details.localFocalPoint,
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController!.value.getMaxScaleOnAxis();
    final Offset focalPointScene = _transformationController!.toScene(
      details.localFocalPoint,
    );

    if (_gestureType == _GestureType.pan) {
      _gestureType = _getGestureType(details);
    } else {
      _gestureType ??= _getGestureType(details);
    }

    switch (_gestureType!) {
      case _GestureType.scale:
        assert(_scaleStart != null);

        final double desiredScale = _scaleStart! * details.scale;
        final double scaleChange = desiredScale / scale;
        _transformationController!.value = _matrixScale(
          _transformationController!.value,
          scaleChange,
        );

        final Offset focalPointSceneScaled = _transformationController!.toScene(
          details.localFocalPoint,
        );

        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          focalPointSceneScaled - _referenceFocalPoint!,
        );

        final Offset focalPointSceneCheck = _transformationController!.toScene(
          details.localFocalPoint,
        );
        if (_round(_referenceFocalPoint!) != _round(focalPointSceneCheck)) {
          _referenceFocalPoint = focalPointSceneCheck;
        }
        break;

      case _GestureType.pan:
        assert(_referenceFocalPoint != null);

        _panAxis ??= _getPanAxis(_referenceFocalPoint!, focalPointScene);

        final Offset translationChange = focalPointScene - _referenceFocalPoint!;
        _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          translationChange,
        );
        _referenceFocalPoint = _transformationController!.toScene(
          details.localFocalPoint,
        );
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;

    _animation?.removeListener(_onAnimate);
    _controller.reset();

    if (!_gestureIsSupported(_gestureType)) {
      _panAxis = null;
      return;
    }

    if (_gestureType != _GestureType.pan || details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
      _panAxis = null;
      return;
    }

    final Vector3 translationVector = _transformationController!.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final FrictionSimulation frictionSimulationX = FrictionSimulation(
      _kDrag,
      translation.dx,
      details.velocity.pixelsPerSecond.dx,
    );
    final FrictionSimulation frictionSimulationY = FrictionSimulation(
      _kDrag,
      translation.dy,
      details.velocity.pixelsPerSecond.dy,
    );
    final double tFinal = _getFinalTime(
      details.velocity.pixelsPerSecond.distance,
      _kDrag,
    );
    _animation = Tween<Offset>(
      begin: translation,
      end: Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));
    _controller.duration = Duration(milliseconds: (tFinal * 1000).round());
    _animation!.addListener(_onAnimate);
    _controller.forward();
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy == 0.0) {
        return;
      }

      final double scaleChange = math.exp(-event.scrollDelta.dy / 200);

      final Offset focalPointScene = _transformationController!.toScene(
        event.localPosition,
      );

      _transformationController!.value = _matrixScale(
        _transformationController!.value,
        scaleChange,
      );

      final Offset focalPointSceneScaled = _transformationController!.toScene(
        event.localPosition,
      );
      _transformationController!.value = _matrixTranslate(
        _transformationController!.value,
        focalPointSceneScaled - focalPointScene,
      );
    }
  }

  void _onDoubleTap() {
    if (!_scaleController.isAnimating && widget.doubleTapZoom) {
      doubleTapZoomIn = _transformationController!.value.getMaxScaleOnAxis() < widget.maxScale;

      _scaleAnimation = Tween<double>(
        begin: _transformationController!.value.getMaxScaleOnAxis(),
        end: widget.maxScale,
      ).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Curves.decelerate,
      ));
      _scaleController.duration = doubleTapZoomIn ? Duration(milliseconds: 100 + widget.doubleTapAnimDuration.inMilliseconds) : widget.doubleTapAnimDuration;
      _scaleAnimation!.addListener(_onAnimateScale);
      _scaleController.forward();
    }
  }

  void _onAnimate() {
    if (!_controller.isAnimating) {
      _panAxis = null;
      _animation?.removeListener(_onAnimate);
      _animation = null;
      _controller.reset();
      return;
    }

    final Vector3 translationVector = _transformationController!.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = _transformationController!.toScene(
      translation,
    );
    final Offset animationScene = _transformationController!.toScene(
      _animation!.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      translationChangeScene,
    );
  }

  void _onAnimateScale() {
    if (!_scaleController.isAnimating) {
      _scaleAnimation?.removeListener(_onAnimateScale);
      _scaleAnimation = null;
      _scaleController.reset();
      return;
    }
    double scaleChange;

    if (widget.doubleTapScaleChange < 1.0) {
      scaleChange = doubleTapZoomIn ? 1.01 : 0.99;
    } else {
      scaleChange = doubleTapZoomIn ? widget.doubleTapScaleChange : 1 - (widget.doubleTapScaleChange - 1);
    }

    final Offset focalPointScene = _transformationController!.toScene(
      _doubleTapFocalPoint ?? Offset.zero,
    );

    _transformationController!.value = _matrixScale(
      _transformationController!.value,
      scaleChange,
      fixScale: true,
    );

    final Offset focalPointSceneScaled = _transformationController!.toScene(
      _doubleTapFocalPoint ?? Offset.zero,
    );

    Offset difference = focalPointSceneScaled - focalPointScene;

    _transformationController!.value = _matrixTranslate(
      _transformationController!.value,
      difference,
    );
  }

  void _onTransformationControllerChange() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _transformationController = widget.transformationController ?? TransformationController();
    _transformationController!.addListener(_onTransformationControllerChange);
    _controller = AnimationController(
      vsync: this,
    );
    _scaleController = AnimationController(
      vsync: this,
    );
  }

  @override
  void didChangeMetrics() {
    setState(() {
      recalculateSizes();
    });
  }

  @override
  void didUpdateWidget(Zoom oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.transformationController == null) {
      if (widget.transformationController != null) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController!.dispose();
        _transformationController = widget.transformationController;
        _transformationController!.addListener(_onTransformationControllerChange);
      }
    } else {
      if (widget.transformationController == null) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController = TransformationController();
        _transformationController!.addListener(_onTransformationControllerChange);
      } else if (widget.transformationController != oldWidget.transformationController) {
        _transformationController!.removeListener(_onTransformationControllerChange);
        _transformationController = widget.transformationController;
        _transformationController!.addListener(_onTransformationControllerChange);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    _transformationController!.removeListener(_onTransformationControllerChange);
    WidgetsBinding.instance.removeObserver(this);
    if (widget.transformationController == null) {
      _transformationController!.dispose();
    }
    super.dispose();
  }

  void fixScale(double scale) {
    _transformationController!.value = _matrixScale(
      _transformationController!.value,
      scale,
      fixScale: true,
    );
    _transformationController!.toScene(
      _referenceFocalPoint ?? Offset.zero,
    );
    _transformationController!.toScene(
      _referenceFocalPoint ?? Offset.zero,
    );
  }

  void recalculateSizes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox parentRenderBox = _parentKey.currentContext!.findRenderObject()! as RenderBox;
      parentSize = parentRenderBox.size;
      final RenderBox childRenderBox = _childKey.currentContext!.findRenderObject()! as RenderBox;
      childSize = childRenderBox.size;
      double scale = 0;

      final currentScale = _transformationController!.value.getMaxScaleOnAxis();

      _transformationController!.value = _matrixTranslate(
          _transformationController!.value,
          const Offset(
            -0.01,
            -0.01,
          ),
          fixOffset: true);

      if (childSize.width == childSize.height) {
        if (childSize.width > parentSize.width && ((childSize.width * currentScale) < parentSize.width || (childSize.height * currentScale) < parentSize.height)) {
          scale = parentSize.width / (childSize.width * currentScale);
          fixScale(scale);
        }
      } else {
        if (childSize.width > childSize.height) {
          if (childSize.width > parentSize.width && (childSize.width * currentScale) < parentSize.width) {
            scale = parentSize.width / (childSize.width * currentScale);
            fixScale(scale);
          }
        } else {
          if (childSize.height > parentSize.height && (childSize.height * currentScale) < parentSize.height) {
            scale = parentSize.height / (childSize.height * currentScale);
            fixScale(scale);
          }
        }
      }

      _transformationController!.value = _matrixTranslate(_transformationController!.value, const Offset(-0.01, -0.01));

      void fitChild(bool condition) {
        if (condition) {
          _transformationController!.value = _matrixScale(_transformationController!.value, parentSize.height / childSize.height, fixScale: true);

          _transformationController!.value = _matrixTranslate(_transformationController!.value, const Offset(-0.01, -0.01), fixOffset: true);
        } else {
          _transformationController!.value = _matrixScale(_transformationController!.value, parentSize.width / childSize.width, fixScale: true);

          _transformationController!.value = _matrixTranslate(_transformationController!.value, const Offset(-0.01, -0.01), fixOffset: true);
        }
      }

      if (widget.initTotalZoomOut) {
        if (firstDraw && (childSize.width > parentSize.width || childSize.height > parentSize.height)) {
          if (childSize.width == childSize.height) {
            fitChild(parentSize.width > parentSize.height);
          } else {
            fitChild(childSize.width < childSize.height);
          }
          firstDraw = false;
        }
      } else {
        if (widget.initScale != null) {
          _transformationController!.value = _matrixScale(_transformationController!.value, widget.initScale ?? 0.0, fixScale: true);

          _transformationController!.value = _matrixTranslate(_transformationController!.value, const Offset(-0.01, -0.01), fixOffset: true);
        }
        if (widget.initPosition != null) {
          _transformationController!.value = _matrixTranslate(
            _transformationController!.value,
            widget.initPosition ?? Offset.zero,
          );

          _referenceFocalPoint = _transformationController!.toScene(
            widget.initPosition ?? Offset.zero,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    child = _ZoomBuilt(
      childKey: _childKey,
      constrained: false,
      matrix: _transformationController!.value,
      child: Listener(
        onPointerUp: (event) {
          if (widget.onPanUpPosition != null) {
            widget.onPanUpPosition!(event.localPosition);
          }
        },
        child: (widget.maxZoomWidth == null || widget.maxZoomHeight == null)
            ? Container(
                color: widget.canvasColor,
                child: widget.child,
              )
            : Center(
                child: Container(width: widget.maxZoomWidth, height: widget.maxZoomHeight, color: widget.canvasColor, child: widget.child),
              ),
      ),
    );

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        recalculateSizes();
        return true;
      },
      child: OrientationBuilder(builder: (context, orientation) {
        if (_orientation != orientation) {
          _orientation = orientation;
          recalculateSizes();
        }

        double opacity = widget.opacityScrollBars < 0
            ? 0
            : widget.opacityScrollBars > 1
                ? 1
                : widget.opacityScrollBars;

        return ClipRect(
          child: Container(
            color: widget.backgroundColor,
            child: Listener(
              key: _parentKey,
              onPointerSignal: _receivedPointerSignal,
              onPointerDown: (PointerDownEvent event) {
                _doubleTapFocalPoint = event.localPosition;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleEnd: _onScaleEnd,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onDoubleTap: _onDoubleTap,
                onTap: widget.onTap,
                child: widget.enableScroll
                    ? Stack(
                        children: [
                          child,
                          ValueListenableBuilder<_ScrollBarData>(
                              valueListenable: horizontalScrollNotifier,
                              builder: (_, scrollData, __) {
                                return scrollData.length == 0
                                    ? Container()
                                    : Positioned(
                                        top: parentSize.height - widget.scrollWeight,
                                        left: scrollData.position,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: widget.colorScrollBars.withAlpha((opacity * 255).toInt()),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                  widget.radiusScrollBars,
                                                ),
                                                topRight: Radius.circular(widget.radiusScrollBars),
                                              )),
                                          height: widget.scrollWeight,
                                          width: scrollData.length,
                                        ),
                                      );
                              }),
                          ValueListenableBuilder<_ScrollBarData>(
                              valueListenable: verticalScrollNotifier,
                              builder: (_, scrollData, __) {
                                return Positioned(
                                  left: parentSize.width - widget.scrollWeight,
                                  top: scrollData.position,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: widget.colorScrollBars.withAlpha((opacity * 255).toInt()),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(widget.radiusScrollBars),
                                          bottomLeft: Radius.circular(widget.radiusScrollBars),
                                        )),
                                    height: scrollData.length,
                                    width: widget.scrollWeight,
                                  ),
                                );
                              }),
                        ],
                      )
                    : child,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ZoomBuilt extends StatelessWidget {
  const _ZoomBuilt({
    required this.child,
    required this.childKey,
    required this.constrained,
    required this.matrix,
  });

  final Widget child;
  final GlobalKey childKey;
  final bool constrained;
  final Matrix4 matrix;

  @override
  Widget build(BuildContext context) {
    Widget child = Transform(
      transform: matrix,
      child: KeyedSubtree(
        key: childKey,
        child: this.child,
      ),
    );

    if (!constrained) {
      child = OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: child,
      );
    }

    return child;
  }
}

class TransformationController extends ValueNotifier<Matrix4> {
  TransformationController([Matrix4? value]) : super(value ?? Matrix4.identity());

  Offset toScene(Offset viewportPoint) {
    final Matrix4 inverseMatrix = Matrix4.inverted(value);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }
}

enum _GestureType {
  pan,
  scale,
}

enum _ScrollType {
  horizontal,
  vertical,
}

class _ScrollBarData {
  _ScrollBarData({
    required this.length,
    required this.position,
  });

  final double position;
  final double length;
}

double _getFinalTime(double velocity, double drag) {
  const double effectivelyMotionless = 10.0;
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

Offset _getMatrixTranslation(Matrix4 matrix) {
  final Vector3 nextTranslation = matrix.getTranslation();
  return Offset(nextTranslation.x, nextTranslation.y);
}

Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(Vector3(
      viewport.topLeft.dx,
      viewport.topLeft.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.topRight.dx,
      viewport.topRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomRight.dx,
      viewport.bottomRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomLeft.dx,
      viewport.bottomLeft.dy,
      0.0,
    )),
  );
}

Quad _getAxisAlignedBoundingBoxWithRotation(Rect rect, double rotation) {
  final Matrix4 rotationMatrix = Matrix4.identity()
    ..translate(rect.size.width / 2, rect.size.height / 2)
    ..rotateZ(rotation)
    ..translate(-rect.size.width / 2, -rect.size.height / 2);
  final Quad boundariesRotated = Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
  return Zoom.getAxisAlignedBoundingBox(boundariesRotated);
}

Offset _exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0,
    viewport.point1,
    viewport.point2,
    viewport.point3,
  ];
  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside = Zoom.getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return _round(largestExcess);
}

Offset _round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}

Axis? _getPanAxis(Offset point1, Offset point2) {
  if (point1 == point2) {
    return null;
  }
  final double x = point2.dx - point1.dx;
  final double y = point2.dy - point1.dy;
  return x.abs() > y.abs() ? Axis.horizontal : Axis.vertical;
}
