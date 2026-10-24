import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/app/bootstrap.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/platform/native_download_engine.dart';
import 'package:booruflow/features/image_viewer/image_zoom_page.dart';
import 'package:booruflow/features/posts/post_detail_page.dart';
import 'package:booruflow/features/posts/widgets/post_video.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/booru/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart'
    show simulateKeyDownEvent, simulateKeyUpEvent;
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/src/motion/_material_reveal.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'automation_binding.dart';
import 'media_inspection.dart';
import 'partial_codec_probe.dart';
import 'preview/feedback.dart';
import 'preview/fixture.dart';
import 'preview/media.dart' show mediaFixtureRoot;
import 'preview/playback.dart';
import 'preview/progressive.dart';
import 'preview/r16_interactions.dart';
import 'profile_paths.dart';

// Test-only entrypoint: real bootstrap and UI, isolated storage and input.

const _native = MethodChannel('booruflow/automation');

final automationFlutterErrors = <FlutterErrorDetails>[];

void captureAutomationErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    automationFlutterErrors.add(details);
    previous?.call(details);
  };
}

Future<void> main() async {
  if (kReleaseMode || !Platform.isWindows) {
    throw StateError(
      'UI automation requires the dedicated Windows Debug/Profile build',
    );
  }
  final root = Platform.environment['BOORUFLOW_AUTOMATION_PROFILE'];
  if (root == null || root.isEmpty || !Directory(root).isAbsolute) {
    throw StateError('Set an explicit absolute BOORUFLOW_AUTOMATION_PROFILE');
  }
  final board = Platform.environment['BOORUFLOW_PREVIEW_BOARD'];
  final key = GlobalKey<AutomationHostState>();
  AutomationBinding((message) async {
    final state = key.currentState;
    if (state == null) throw StateError('Application is not ready');
    return state.request(message);
  });
  captureAutomationErrors();
  // Fail before production bootstrap if the build lacks the native test mode.
  // Dart can start before the native view constructor has registered channels.
  // Await the exact test channel with a bound; do not launch normal bootstrap
  // or fall back to an uninstrumented runner when it is unavailable.
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (true) {
    try {
      await _native.invokeMethod<Object?>('status');
      break;
    } on MissingPluginException {
      if (DateTime.now().isAfter(deadline)) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  if (board != null) {
    if (isPhonePreview(board)) {
      // Keep a caption-free native test HWND, then simulate only the Flutter
      // platform/layout. This is not an Android device or real-touch claim.
      final frame = FrostWindowController(minimumSize: const Size(320, 480));
      await frame.initialize();
      frame.dispose();
    }
    if (isPhonePreview(board) && !kDebugMode) {
      throw StateError(
        'Phone simulation requires Debug; Profile measures Windows only',
      );
    }
    if (kDebugMode) {
      debugDefaultTargetPlatformOverride = isPhonePreview(board)
          ? TargetPlatform.android
          : TargetPlatform.windows;
    }
  }
  AutomationPaths.install(Directory(root));
  await bootstrap(
    appBuilder: (app) => AutomationHost(
      key: key,
      child: board == null ? app : PreviewFixture(board: board),
    ),
  );
}

class AutomationHost extends StatefulWidget {
  const AutomationHost({required this.child, super.key});
  final Widget child;
  @override
  State<AutomationHost> createState() => AutomationHostState();
}

class AutomationHostState extends State<AutomationHost>
    with WidgetsBindingObserver {
  final _motionTrace = <Map<String, Object?>>[];
  int _motionTraceGeneration = 0;

  final _timings = <ui.FrameTiming>[];
  bool _windowTrace = false;
  final _windowMetrics = <Map<String, Object?>>[];
  void _windowSample(String phase, Size size) {
    if (!_windowTrace) return;
    final layout = FrostSizeLayout.fromSize(
      size,
      mobileBreakpoint: 600,
      tabletBreakpoint: 900,
      desktopBreakpoint: 1200,
    );
    _windowMetrics.add({
      'phase': phase,
      'timeUs': DateTime.now().microsecondsSinceEpoch,
      'width': size.width,
      'height': size.height,
      'sizeClass': layout.sizeClass.name,
    });
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      _windowSample(
        'platformMetrics',
        view.physicalSize / view.devicePixelRatio,
      );
    }
  }

  final _progressive = GlobalKey<ProgressiveProbeState>();
  void _recordTimings(List<ui.FrameTiming> timings) => _timings.addAll(timings);
  final _boundary = GlobalKey();
  final _probe = GlobalKey();
  int _token = 0;
  bool _showsCaptureProbe = true;
  // A dedicated Flutter pointer; this never moves the native cursor.
  static const _automationPointer = 900001;
  Offset? _pointerPosition;
  Offset? _heldTouchPosition;
  PointerDeviceKind _heldPointerKind = PointerDeviceKind.touch;
  Brightness? _platformBrightness;
  ui.ViewFocusState _viewFocus = ui.ViewFocusState.unfocused;
  AutomationBinding get _binding =>
      WidgetsBinding.instance as AutomationBinding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addTimingsCallback(_recordTimings);
  }

  @override
  void didChangeViewFocus(ui.ViewFocusEvent event) => _viewFocus = event.state;

  Future<void> _refresh() async {
    WidgetsBinding.instance.scheduleForcedFrame();
    await WidgetsBinding.instance.endOfFrame.timeout(
      const Duration(seconds: 3),
    );
    if (!mounted) throw StateError('Automation host unmounted');
    if (Platform.isWindows) await _native.invokeMethod<void>('present');
  }

  Future<Map<String, Object?>> _state() async {
    final status = Platform.isWindows
        ? (await _native.invokeMapMethod<String, Object?>('status'))!
        : <String, Object?>{
            'pid': pid,
            'platform': Platform.operatingSystem,
            'nativeWindowStatusAvailable': false,
          };
    if (!mounted) throw StateError('Automation host unmounted');
    if (Platform.isWindows) {
      _binding.initializePlatformState(
        visible: status['visible'] == true,
        isForeground: status['isForeground'] == true,
      );
    }
    return {
      'native': status,
      'profile': Platform.environment['BOORUFLOW_AUTOMATION_PROFILE'],
      'pretendForeground': _binding.pretendForeground,
      'platformBrightness': _platformBrightness?.name ?? 'system',
      'rawLifecycle': _binding.rawLifecycle?.name,
      'effectiveLifecycle': _binding.lifecycleState?.name,
      'effectiveViewFocus': _viewFocus.name,
      'frameworkFocusAllowed': FocusManager.instance.rootScope.canRequestFocus,
      'primaryFocus': FocusManager.instance.primaryFocus?.toStringShort(),
      'insets': {
        'bottom': View.of(context).viewInsets.bottom,
        'topPadding': View.of(context).padding.top,
      },
      'viewSize': {
        'width': View.of(context).physicalSize.width,
        'height': View.of(context).physicalSize.height,
        'pixelRatio': View.of(context).devicePixelRatio,
      },
    };
  }

  Future<String> request(String? message) async {
    final data = jsonDecode(message ?? '{}') as Map<String, Object?>;
    switch (data['command']) {
      case 'flutterErrors':
        return jsonEncode([
          for (final error in automationFlutterErrors)
            {
              'message': error.exceptionAsString(),
              'stack': error.stack.toString(),
            },
        ]);
      case 'progressiveProbe':
        final name = data['file'] as String;
        if (!{
          'r9-baseline.jpg',
          'r9-progressive.jpg',
          'r9-noninterlaced.png',
          'r9-large.jpg',
        }.contains(name)) {
          throw ArgumentError.value(name);
        }
        unawaited(
          AppRouter.rootNavigatorKey.currentState!.push(
            FrostDetailPage<void>(
              child: ProgressiveProbe(key: _progressive, filename: name),
            ).createRoute(context),
          ),
        );
        await _refresh();
        return jsonEncode({'file': name});
      case 'progressiveDiagnostics':
        return jsonEncode(_progressive.currentState?.diagnostics());
      case 'captionDiagnostics':
        return jsonEncode({'nativeRegions': _binding.captionRegions});
      case 'partialCodecProbe':
        return jsonEncode(await partialCodecProbe(mediaFixtureRoot!));
      case 'frameTimings':
        final frames = _timings
            .map(
              (frame) => {
                'buildStartUs': frame.timestampInMicroseconds(
                  ui.FramePhase.buildStart,
                ),
                'rasterStartUs': frame.timestampInMicroseconds(
                  ui.FramePhase.rasterStart,
                ),
                'buildUs': frame.buildDuration.inMicroseconds,
                'rasterUs': frame.rasterDuration.inMicroseconds,
                'totalUs': frame.totalSpan.inMicroseconds,
              },
            )
            .toList();
        _timings.clear();
        return jsonEncode({
          'mode': kProfileMode ? 'profile' : 'debug',
          'frames': frames,
        });
      case 'operationFailureToast':
        // Deliberately injected diagnostics prove the UI path, not a native failure.
        AppToast.errorWithCause(
          t.webChallenge.failed,
          const BooruError(
            code: BooruErrorCode.internal,
            sourceId: 'aibooru',
            userMessageKey: 'webChallenge.windowFailed',
            diagnosticId: 'toast-layout-fixture',
            details: 'stage=fixture-webview-create\nHRESULT=0x80070005',
          ),
        );
        await _refresh();
        return jsonEncode({'injected': true});
      case 'previewNotices':
        final board =
            activePreviewBoard ??
            Platform.environment['BOORUFLOW_PREVIEW_BOARD'];
        if (board != 'F01' && board != 'F04') {
          throw StateError('No preview notice fixture');
        }
        showPreviewNotices(board!);
        await _refresh();
        final label = board == 'F04'
            ? t.settings.account.verified
            : t.verificationPage.linkCopied;
        Element? target;
        void find(Element element) {
          if (element.widget case Text(data: final data)) {
            if (data == label) target = element;
          }
          element.visitChildren(find);
        }
        _boundary.currentContext!.visitChildElements(find);
        final box = target?.renderObject;
        if (box is! RenderBox || !box.hasSize) {
          throw StateError('Notice has no actual bounds');
        }
        final position = box.localToGlobal(box.size.center(Offset.zero));
        if (board == 'F04') {
          GestureBinding.instance.handlePointerEvent(
            PointerDownEvent(
              pointer: 900002,
              device: 900002,
              kind: PointerDeviceKind.touch,
              position: position,
            ),
          );
          await Future<void>.delayed(
            kLongPressTimeout + const Duration(milliseconds: 50),
          );
          await _refresh();
          return jsonEncode({
            'touchDownSent': true,
            'x': position.dx,
            'y': position.dy,
            'nativeInput': false,
          });
        }
        await request(
          jsonEncode({
            'command': 'pointer',
            'action': 'hover',
            'x': position.dx,
            'y': position.dy,
          }),
        );
        return jsonEncode({'hovered': true, 'nativeInput': false});
      case 'releasePreviewNotice':
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(
            pointer: 900002,
            device: 900002,
            kind: PointerDeviceKind.touch,
          ),
        );
        await _refresh();
        return jsonEncode({'released': true, 'nativeInput': false});
      case 'pumpFrames':
        final count = (data['count'] as int? ?? 30).clamp(1, 120);
        for (var i = 0; i < count; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
          await _refresh();
        }
        return jsonEncode({
          'frames': count,
          'transientCallbacks': WidgetsBinding.instance.transientCallbackCount,
        });
      case 'semanticsTree':
        await _refresh();
        final boundary = _boundary.currentContext!.findRenderObject()!;
        final root = boundary.owner?.semanticsOwner?.rootSemanticsNode;
        if (root == null) throw StateError('Enable Driver semantics first');
        return jsonEncode({'tree': root.toStringDeep()});
      case 'viewportDiagnostics':
        await _refresh();
        if (!mounted) throw StateError('Automation host disposed');
        final viewports = <Map<String, Object?>>[];
        void inspect(Element element) {
          if (element.widget case InteractiveViewer(
            :final transformationController,
            :final maxScale,
          )) {
            if (transformationController != null) {
              viewports.add({
                'scale': transformationController.value.getMaxScaleOnAxis(),
                'maxScale': maxScale,
                'matrix': transformationController.value.storage.toList(),
              });
            }
          }
          element.visitChildren(inspect);
        }
        context.visitChildElements(inspect);
        return jsonEncode({'viewports': viewports});
      case 'materialDiagnostics':
        await _refresh();
        final filters = <Map<String, Object?>>[];
        void visit(RenderObject node, List<double> opacity) {
          final inherited = [
            ...opacity,
            if (node is RenderOpacity) node.opacity,
            if (node is RenderAnimatedOpacity) node.opacity.value,
          ];
          if (node is RenderBackdropFilter) {
            final origin = node.localToGlobal(Offset.zero);
            filters.add({
              'filter': node.filterConfig.toString(),
              'enabled': node.enabled,
              'opacityAncestors': inherited,
              'x': origin.dx,
              'y': origin.dy,
              'width': node.size.width,
              'height': node.size.height,
            });
          }
          node.visitChildren((child) => visit(child, inherited));
        }
        visit(_boundary.currentContext!.findRenderObject()!, const []);
        return jsonEncode({'filters': filters});
      case 'tree':
        await _refresh();
        return jsonEncode({
          'tree': (_boundary.currentContext! as Element).toStringDeep(),
        });
      case 'historicalPostFixture':
        final source = data['source'] as String;
        final id = data['postId'] as String;
        unawaited(
          AppRouter.router.pushNamed<void>(
            AppRoute.postDetail.name,
            pathParameters: {'id': id},
            queryParameters: {'source': source},
          ),
        );
        await _refresh();
        return jsonEncode({'source': source, 'postId': id});
      case 'enterText':
        await _binding.enterText(data['text'] as String);
        await _refresh();
        return jsonEncode({'entered': true, 'nativeInput': false});
      case 'inputs':
        final inputs = <Map<String, Object?>>[];
        void visitInput(Element element) {
          if (element.widget case EditableText(
            :final controller,
            :final focusNode,
          )) {
            final box = element.renderObject;
            if (box is RenderBox && box.hasSize) {
              final center = box.localToGlobal(box.size.center(Offset.zero));
              inputs.add({
                'x': center.dx,
                'y': center.dy,
                'text': controller.text,
                'width': box.size.width,
                'height': box.size.height,
                'selectionBase': controller.selection.baseOffset,
                'selectionExtent': controller.selection.extentOffset,
                'focused': focusNode.hasFocus,
              });
            }
          }
          element.visitChildren(visitInput);
        }
        _boundary.currentContext!.visitChildElements(visitInput);
        return jsonEncode(inputs);
      case 'layoutDiagnostics':
        final items = <Map<String, Object?>>[];
        void inspectLayout(RenderObject node) {
          if (node is RenderBox && node.attached && node.hasSize) {
            final type = node.runtimeType.toString();
            if (node is RenderClipRSuperellipse ||
                node is RenderClipPath ||
                node is RenderCustomPaint &&
                    node.foregroundPainter is ScrollbarPainter) {
              final origin = node.localToGlobal(Offset.zero);
              final painter =
                  node is RenderCustomPaint &&
                      node.foregroundPainter is ScrollbarPainter
                  ? node.foregroundPainter! as ScrollbarPainter
                  : null;
              items.add({
                'type': type,
                'x': origin.dx,
                'y': origin.dy,
                'width': node.size.width,
                'height': node.size.height,
                'detail': node.toStringShort(),
                if (painter != null) 'margin': painter.crossAxisMargin,
                if (painter != null) 'padding': painter.padding.toString(),
              });
            }
          }
          node.visitChildren(inspectLayout);
        }
        inspectLayout(_boundary.currentContext!.findRenderObject()!);
        return jsonEncode(items);
      case 'texts':
        final texts = <Map<String, Object?>>[];
        void visitText(Element element) {
          if (element.renderObject case final RenderParagraph paragraph) {
            if (paragraph.attached && paragraph.hasSize) {
              final origin = paragraph.localToGlobal(Offset.zero);
              texts.add({
                'text': paragraph.text.toPlainText(),
                'x': origin.dx,
                'y': origin.dy,
                'width': paragraph.size.width,
                'height': paragraph.size.height,
                'truncated': paragraph.didExceedMaxLines,
              });
            }
          }
          element.visitChildren(visitText);
        }
        _boundary.currentContext!.visitChildElements(visitText);
        return jsonEncode(texts);
      case 'buttons':
        final buttons = <Map<String, Object?>>[];
        void inspect(Element element) {
          final label = switch (element.widget) {
            FrostButton(:final label) => label,
            Semantics(:final properties) => properties.label,
            _ => null,
          };
          if (label != null) {
            final object = element.renderObject;
            if (object is RenderBox && object.hasSize && object.attached) {
              final center = object.localToGlobal(
                object.size.center(Offset.zero),
              );
              // Collapsed/offstage variants can have a singular transform.
              // They are not actionable and NaN cannot cross the JSON bridge.
              if (!center.dx.isFinite ||
                  !center.dy.isFinite ||
                  !object.size.isFinite) {
                return;
              }
              final hits = HitTestResult();
              GestureBinding.instance.hitTestInView(
                hits,
                center,
                View.of(context).viewId,
              );
              final hitTestable = hits.path.any((entry) {
                var target = entry.target;
                if (target is! RenderObject) return false;
                RenderObject? ancestor = target;
                while (ancestor != null) {
                  if (identical(ancestor, object)) return true;
                  ancestor = ancestor.parent;
                }
                return false;
              });
              buttons.add({
                'hitTestable': hitTestable,
                'label': label,
                'x': center.dx,
                'y': center.dy,
                'width': object.size.width,
                'height': object.size.height,
              });
            }
          }
          element.visitChildren(inspect);
        }
        _boundary.currentContext!.visitChildElements(inspect);
        return jsonEncode(buttons);
      case 'r16PreviewProbe':
        final navigator = AppRouter.rootNavigatorKey.currentState!;
        unawaited(
          navigator.push(
            FrostDetailPage<void>(
              child: const R16InteractionProbe(),
            ).createRoute(navigator.context),
          ),
        );
        await _refresh();
        return jsonEncode({'opened': true, 'testOnly': true});
      case 'motionTraceStart':
        final dilation = (data['dilation'] as num?)?.toDouble() ?? 1;
        if (dilation < 1 || dilation > 10) {
          throw ArgumentError('dilation 1..10');
        }
        timeDilation = dilation;
        _motionTrace.clear();
        final generation = ++_motionTraceGeneration;
        var remaining = (data['frames'] as int?) ?? 300;
        void sample(Duration time) {
          if (!mounted ||
              generation != _motionTraceGeneration ||
              remaining-- <= 0) {
            return;
          }
          final records = <Map<String, Object?>>[];
          void inspect(Element element) {
            final widget = element.widget;
            final flight = widget.runtimeType.toString() == '_FlightFrame';
            if (flight ||
                widget is FrostMediaHero ||
                widget is PostDetailPage) {
              var box = element.findRenderObject();
              if (flight && box is RenderShiftedBox && box.child != null) {
                box = box.child;
              }
              if (box is RenderBox && box.attached && box.hasSize) {
                final rect = MatrixUtils.transformRect(
                  box.getTransformTo(null),
                  Offset.zero & box.size,
                );
                records.add({
                  'kind': flight
                      ? 'flight'
                      : widget is PostDetailPage
                      ? 'page'
                      : 'hero',
                  'x': rect.left,
                  'y': rect.top,
                  'w': rect.width,
                  'h': rect.height,
                  if (widget is PostDetailPage)
                    'opacity': element
                        .findAncestorWidgetOfExactType<FrostMaterialReveal>()
                        ?.opacity,
                });
              }
            }
            element.visitChildren(inspect);
          }

          _boundary.currentContext?.visitChildElements(inspect);
          _motionTrace.add({'us': time.inMicroseconds, 'records': records});
          WidgetsBinding.instance.addPostFrameCallback(sample);
        }
        WidgetsBinding.instance.addPostFrameCallback(sample);
        return jsonEncode({'started': true, 'dilation': timeDilation});
      case 'motionTrace':
        return jsonEncode(_motionTrace);
      case 'motionTraceStop':
        _motionTraceGeneration++;
        timeDilation = 1;
        return jsonEncode({'dilation': timeDilation});
      case 'listDiagnostics':
        final sources = <Map<String, Object?>>[];
        final scrolls = <Map<String, Object?>>[];
        final footers = <Map<String, Object?>>[];
        void inspectList(Element element) {
          final widget = element.widget;
          final source = switch (widget) {
            FrostSliverDataList<Object?>(:final source) => source,
            FrostSliverDataGrid<Object?>(:final source) => source,
            FrostSliverDataWaterfallGrid<Object?>(:final source) => source,
            _ => null,
          };
          // Inspection must not register inherited dependencies. In particular,
          // an InheritedElement can look up itself and become its own dependent.
          var current = true;
          element.visitAncestorElements((ancestor) {
            if (ancestor.widget case Offstage(offstage: true)) {
              current = false;
              return false;
            }
            return true;
          });
          if (source != null) {
            sources.add({
              'count': source.length,
              'phase': source.phase.name,
              'hasMore': source.hasMore,
              'busy': source.busy,
              'revision': source.refreshRevision,
              'error': source.lastError?.runtimeType.toString(),
              'current': current,
            });
          }
          if (element is StatefulElement && element.state is ScrollableState) {
            final position = (element.state as ScrollableState).position;
            if (position.hasContentDimensions) {
              scrolls.add({
                'pixels': position.pixels,
                'max': position.maxScrollExtent,
                'viewport': position.viewportDimension,
                'axis': position.axis.name,
                'current': current,
              });
            }
          }
          if (widget is FrostLoadingMoreIndicator<Object?>) {
            final render = element.findRenderObject();
            if (render is RenderBox && render.hasSize) {
              final top = render.localToGlobal(Offset.zero);
              footers.add({
                'x': top.dx,
                'y': top.dy,
                'width': render.size.width,
                'height': render.size.height,
                'current': current,
              });
            }
          }
          element.visitChildren(inspectList);
        }
        _boundary.currentContext!.visitChildElements(inspectList);
        return jsonEncode({
          'sources': sources,
          'scrolls': scrolls,
          'footers': footers,
        });
      case 'navigationDiagnostics':
        var viewers = 0, details = 0, videos = 0, overlays = 0;
        final detailTransitions = <Map<String, Object?>>[];
        void inspectNavigation(Element element) {
          final widget = element.widget;
          if (widget is ImageZoomPage) viewers++;
          if (widget is PostDetailPage) {
            details++;
            final route = ModalRoute.of(element);
            detailTransitions.add({
              'value': route?.animation?.value,
              'status': route?.animation?.status.name,
              'durationUs': route?.transitionDuration.inMicroseconds,
            });
          }
          if (widget is PostVideo) videos++;
          if (widget is Overlay) overlays++;
          element.visitChildren(inspectNavigation);
        }
        _boundary.currentContext!.visitChildElements(inspectNavigation);
        return jsonEncode({
          'path': AppRouter.currentUri.path,
          'viewers': viewers,
          'details': details,
          'detailTransitions': detailTransitions,
          'videoWidgets': videos,
          'overlays': overlays,
        });
      case 'glassDiagnostics':
        final surfaces = <Map<String, Object?>>[];
        void inspect(Element element) {
          final widget = element.widget;
          if (widget is FrostSurface) {
            final render = element.findRenderObject();
            var scope = element
                .getInheritedWidgetOfExactType<FrostContentRevealScope>();
            var factor = 1.0;
            final scopes = <Map<String, double>>[];
            while (scope != null) {
              scopes.add({
                'opacity': scope.opacity,
                'nested': scope.nestedProgress,
              });
              factor *= scope.opacity < 1 ? 0 : scope.nestedProgress;
              scope = scope.parent;
            }
            surfaces.add({
              'role': widget.role.name,
              'blurFactor': factor,
              'scopes': scopes,
              if (render is RenderBox && render.hasSize)
                'rect': {
                  'x': render.localToGlobal(Offset.zero).dx,
                  'y': render.localToGlobal(Offset.zero).dy,
                  'width': render.size.width,
                  'height': render.size.height,
                },
            });
          }
          element.visitChildren(inspect);
        }
        _boundary.currentContext!.visitChildElements(inspect);
        return jsonEncode(surfaces);
      case 'videoOutputDiagnostics':
        final controllers = <VideoController>{};
        void inspectVideo(Element element) {
          if (element.widget case Video(:final controller)) {
            controllers.add(controller);
          }
          element.visitChildren(inspectVideo);
        }
        _boundary.currentContext!.visitChildElements(inspectVideo);
        final outputs = <Map<String, Object?>>[];
        for (final controller in controllers) {
          final platform = await controller.platform.future;
          final values = <String, Object?>{
            'rect': controller.rect.value.toString(),
            'id': controller.id.value,
          };
          if (platform.player.platform case final NativePlayer player) {
            for (final name in [
              'vo',
              'android-surface-size',
              'wid',
              'video-frame-info/interlaced',
              'video-out-params/w',
              'video-out-params/h',
            ]) {
              try {
                values[name] = await player.getProperty(name);
              } catch (error) {
                values[name] = error.toString();
              }
            }
          }
          outputs.add(values);
        }
        return jsonEncode(outputs);
      case 'saveFormatFixtures':
        if (!Platform.isAndroid) throw StateError('Android-only save probe');
        final saved = <Map<String, Object?>>[];
        final stamp = DateTime.now().microsecondsSinceEpoch;
        for (final (name, extension, format) in [
          ('r7-public.webp', 'webp', UgoiraExport.losslessWebp),
          ('r7-public.zip', 'zip', UgoiraExport.originalZip),
          ('test_video.mp4', 'mp4', null),
          ('test_video.webm', 'webm', null),
        ]) {
          final file = File(
            '/data/user/0/io.github.normalllll.booruflow/files/r5-fixtures/$name',
          );
          final length = await file.length();
          final filename = 'r7-verification-$stamp.$extension';
          final job = DownloadJob.create(
            resourceId: 12411796,
            variantIndex: 0,
            url: Uri.parse('https://preview.invalid/source.$extension'),
            filename: filename,
            sourceId: 'r7-verification',
            ugoiraExport: format,
            saveTarget: const SaveTarget.mediaStore(
              subdirectory: 'r7-verification',
            ),
            validation: DownloadValidationOptions(
              expectedBytes: format == UgoiraExport.losslessWebp
                  ? 2354861
                  : length,
            ),
          );
          final result = await NativeMediaSaver().saveDownloadedFile(
            job: job,
            file: DownloadedFile(path: file.path, bytesWritten: length),
          );
          saved.add({
            'filename': filename,
            'source': name,
            'uri': result.path,
            'bytes': result.bytesWritten,
            'directory': switch (extension) {
              'webp' => 'Pictures',
              'zip' => 'Download',
              _ => 'Movies',
            },
          });
        }
        return jsonEncode(saved);
      case 'videoDiagnostics':
        return jsonEncode(videoDiagnostics());
      case 'mediaDiagnostics':
        return jsonEncode({
          'media': inspectMedia(_boundary.currentContext! as Element),
        });
      case 'state':
        return jsonEncode(await _state());
      case 'refresh':
        await _refresh();
        return jsonEncode({'refreshed': true});
      case 'prepareCapture':
        setState(() {
          _showsCaptureProbe = true;
          _token = (_token + 1) & 0xffffff;
        });
        await _refresh();
        if (!mounted) throw StateError('Automation host unmounted');
        final box = _probe.currentContext!.findRenderObject()! as RenderBox;
        final origin = box.localToGlobal(Offset.zero);
        final pixelRatio = View.of(context).devicePixelRatio;
        return jsonEncode({
          'token': _token,
          'rect': {
            'x': origin.dx,
            'y': origin.dy,
            'width': box.size.width,
            'height': box.size.height,
          },
          'pixelRatio': pixelRatio,
          'native': (await _state())['native'],
        });
      case 'captureProbe':
        final enabled = data['enabled'];
        if (enabled is! bool) throw ArgumentError('enabled must be bool');
        setState(() => _showsCaptureProbe = enabled);
        await _refresh();
        return jsonEncode({'captureProbe': enabled});
      case 'appScreenshot':
        await _refresh();
        if (!mounted) throw StateError('Automation host unmounted');
        final boundary =
            _boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final ratio = View.of(context).devicePixelRatio;
        final image = await boundary.toImage(pixelRatio: ratio);
        try {
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          return jsonEncode({
            'png': base64Encode(bytes.buffer.asUint8List()),
            'width': image.width,
            'height': image.height,
            'pixelRatio': ratio,
          });
        } finally {
          image.dispose();
        }
      case 'pretendForeground':
        final enabled = data['enabled'];
        if (enabled is! bool) throw ArgumentError('enabled must be bool');
        _binding.setPretendForeground(enabled);
        await _refresh();
        return jsonEncode(await _state());
      case 'orientation':
        final orientations = switch (data['value']) {
          'landscape' => [DeviceOrientation.landscapeLeft],
          'portrait' => [DeviceOrientation.portraitUp],
          'system' => <DeviceOrientation>[],
          _ => throw ArgumentError('Use landscape/portrait/system orientation'),
        };
        await SystemChrome.setPreferredOrientations(orientations);
        await _refresh();
        return jsonEncode({'orientation': data['value']});
      case 'platformBrightness':
        final brightness = switch (data['value']) {
          'light' => Brightness.light,
          'dark' => Brightness.dark,
          'system' => null,
          _ => throw ArgumentError('Use light/dark/system platformBrightness'),
        };
        setState(() => _platformBrightness = brightness);
        await _refresh();
        return jsonEncode({'platformBrightness': brightness?.name ?? 'system'});
      case 'touch':
        // Hold/cancel through Flutter for pressed-state captures, without device
        // or host input. Keep a separate pointer from hover and preview notices.
        const pointer = _automationPointer + 2;
        final action = data['action'] as String;
        if (action == 'down') {
          if (_heldTouchPosition != null) {
            throw StateError('Touch already held');
          }
          final position = Offset(
            (data['x'] as num).toDouble(),
            (data['y'] as num).toDouble(),
          );
          final view = View.of(context);
          if (!(Offset.zero & (view.physicalSize / view.devicePixelRatio))
              .contains(position)) {
            throw ArgumentError('Touch is outside this Flutter view');
          }
          final kind = data['kind'] ?? 'touch';
          if (kind != 'touch' && kind != 'mouse') {
            throw ArgumentError('Use touch or mouse');
          }
          _heldPointerKind = kind == 'mouse'
              ? PointerDeviceKind.mouse
              : PointerDeviceKind.touch;
          _heldTouchPosition = position;
          GestureBinding.instance.handlePointerEvent(
            PointerDownEvent(
              pointer: pointer,
              device: pointer,
              kind: _heldPointerKind,
              position: position,
              // Flutter uses the primary-button bit for touch contacts too.
              buttons: kPrimaryButton,
            ),
          );
        } else if (action == 'up' || action == 'cancel') {
          final position = _heldTouchPosition;
          if (position == null) throw StateError('No touch held');
          _heldTouchPosition = null;
          GestureBinding.instance.handlePointerEvent(
            action == 'up'
                ? PointerUpEvent(
                    pointer: pointer,
                    device: pointer,
                    kind: _heldPointerKind,
                    position: position,
                  )
                : PointerCancelEvent(
                    pointer: pointer,
                    device: pointer,
                    kind: _heldPointerKind,
                    position: position,
                  ),
          );
        } else {
          throw ArgumentError('Use down/up/cancel');
        }
        await _refresh();
        return jsonEncode({'touchAction': action, 'nativeInput': false});
      case 'pointer':
        final action = data['action'];
        if (action == 'remove') {
          _removePointer();
        } else {
          final x = data['x'], y = data['y'];
          if (x is! num || y is! num) {
            throw ArgumentError('Pointer needs logical x/y');
          }
          final position = Offset(x.toDouble(), y.toDouble());
          final view = View.of(context);
          final bounds =
              Offset.zero & (view.physicalSize / view.devicePixelRatio);
          if (!position.dx.isFinite ||
              !position.dy.isFinite ||
              !bounds.contains(position)) {
            throw ArgumentError('Pointer is outside this Flutter view');
          }
          if (!const {
            'hover',
            'scroll',
            'tap',
            'secondaryTap',
            'longPress',
          }.contains(action)) {
            throw ArgumentError(
              'Use hover/scroll/tap/secondaryTap/longPress/remove',
            );
          }
          final gestures = GestureBinding.instance;
          if (_pointerPosition == null) {
            gestures.handlePointerEvent(
              PointerAddedEvent(
                pointer: _automationPointer,
                device: _automationPointer,
                kind: PointerDeviceKind.mouse,
                position: position,
              ),
            );
          }
          _pointerPosition = position;
          gestures.handlePointerEvent(
            PointerHoverEvent(
              pointer: _automationPointer,
              device: _automationPointer,
              kind: PointerDeviceKind.mouse,
              position: position,
            ),
          );
          if (action == 'scroll') {
            gestures.handlePointerEvent(
              PointerScrollEvent(
                device: _automationPointer,
                kind: PointerDeviceKind.mouse,
                position: position,
                scrollDelta: Offset(
                  (data['dx'] as num? ?? 0).toDouble(),
                  (data['dy'] as num? ?? 0).toDouble(),
                ),
              ),
            );
          }
          if (action == 'longPress') {
            const pointer = _automationPointer + 1;
            gestures.handlePointerEvent(
              PointerDownEvent(
                pointer: pointer,
                device: pointer,
                kind: PointerDeviceKind.touch,
                position: position,
              ),
            );
            await Future<void>.delayed(
              kLongPressTimeout + const Duration(milliseconds: 50),
            );
            gestures.handlePointerEvent(
              PointerUpEvent(
                pointer: pointer,
                device: pointer,
                kind: PointerDeviceKind.touch,
                position: position,
              ),
            );
          }
          if (action == 'tap' || action == 'secondaryTap') {
            gestures.handlePointerEvent(
              PointerDownEvent(
                pointer: _automationPointer,
                device: _automationPointer,
                kind: PointerDeviceKind.mouse,
                position: position,
                buttons: action == 'secondaryTap'
                    ? kSecondaryMouseButton
                    : kPrimaryMouseButton,
              ),
            );
            gestures.handlePointerEvent(
              PointerUpEvent(
                pointer: _automationPointer,
                device: _automationPointer,
                kind: PointerDeviceKind.mouse,
                position: position,
              ),
            );
          }
        }
        await _refresh();
        return jsonEncode({'pointerAction': action, 'nativeInput': false});
      case 'key':
        final keys = <String, LogicalKeyboardKey>{
          'Escape': LogicalKeyboardKey.escape,
          'Enter': LogicalKeyboardKey.enter,
          'Tab': LogicalKeyboardKey.tab,
          'ArrowDown': LogicalKeyboardKey.arrowDown,
          'ArrowUp': LogicalKeyboardKey.arrowUp,
          'ArrowLeft': LogicalKeyboardKey.arrowLeft,
          'ArrowRight': LogicalKeyboardKey.arrowRight,
          'Space': LogicalKeyboardKey.space,
          'Equal': LogicalKeyboardKey.equal,
          'Minus': LogicalKeyboardKey.minus,
        };
        const physicalKeys = <String, PhysicalKeyboardKey>{
          'Escape': PhysicalKeyboardKey.escape,
          'Enter': PhysicalKeyboardKey.enter,
          'Tab': PhysicalKeyboardKey.tab,
          'ArrowDown': PhysicalKeyboardKey.arrowDown,
          'ArrowUp': PhysicalKeyboardKey.arrowUp,
          'ArrowLeft': PhysicalKeyboardKey.arrowLeft,
          'ArrowRight': PhysicalKeyboardKey.arrowRight,
          'Space': PhysicalKeyboardKey.space,
          'Equal': PhysicalKeyboardKey.equal,
          'Minus': PhysicalKeyboardKey.minus,
          'M': PhysicalKeyboardKey.keyM,
        };
        keys['M'] = LogicalKeyboardKey.keyM;
        final key = keys[data['key']];
        final physical = physicalKeys[data['key']];
        if (key == null || physical == null) {
          throw ArgumentError('Unsupported framework key');
        }
        // Explicit physical codes also work in AOT, where debugName is null.
        await simulateKeyDownEvent(key, physicalKey: physical);
        await simulateKeyUpEvent(key, physicalKey: physical);
        await _refresh();
        return jsonEncode(await _state());
      case 'windowMetrics':
        if (data['enabled'] case final bool enabled) _windowTrace = enabled;
        if (data['clear'] == true) _windowMetrics.clear();
        return jsonEncode(_windowMetrics);
      case 'windowMinimize':
        if (!Platform.isWindows) throw StateError('Windows test window only');
        await const MethodChannel(
          'frost_window',
        ).invokeMethod<void>('minimize');
        return jsonEncode({'minimized': true});
      case 'resize':
        await _native.invokeMethod<void>('resize', {
          'width': (data['width'] as num).toDouble(),
          'height': (data['height'] as num).toDouble(),
        });
        await _refresh();
        return jsonEncode(await _state());
      case 'close':
        _removePointer();
        _binding.setPretendForeground(false);
        await _native.invokeMethod<void>('close');
        return jsonEncode({'closing': true});
      default:
        throw ArgumentError('Unknown command: ${data['command']}');
    }
  }

  void _removePointer() {
    final position = _pointerPosition;
    if (position == null) return;
    _pointerPosition = null;
    GestureBinding.instance.handlePointerEvent(
      PointerRemovedEvent(
        pointer: _automationPointer,
        device: _automationPointer,
        kind: PointerDeviceKind.mouse,
        position: position,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.removeTimingsCallback(_recordTimings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundary,
    child: Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(
          child: MediaQuery.fromView(
            view: View.of(context),
            child: Builder(
              builder: (context) {
                _windowSample('mediaQueryBuild', MediaQuery.sizeOf(context));
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(platformBrightness: _platformBrightness),
                  child: widget.child,
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 8,
          // Keep Android presentation markers below its native status bar.
          top: Platform.isAndroid
              ? View.of(context).padding.top / View.of(context).devicePixelRatio
              : 0,
          child: IgnorePointer(
            child: Opacity(
              opacity: _showsCaptureProbe ? 1 : 0,
              child: SizedBox(
                key: _probe,
                width: 128,
                height: 4,
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: List.generate(32, (index) {
                    final word = (0xa << 28) | (_token << 4) | 0x5;
                    return Expanded(
                      child: ColoredBox(
                        color: (word >> (31 - index)) & 1 == 1
                            ? const Color(0xfff0b429)
                            : const Color(0xff16324f),
                        child: const SizedBox.expand(),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
