import 'dart:async';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/media_viewer_page.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import '../posts/displayed_media_frame.dart';
import '../posts/stage_image_presentation.dart';
import 'viewer_controls.dart';
import 'viewer_stage.dart';

const _viewerIdle = Duration(seconds: 2);
const _viewerZoomStep = 1.5;
const _viewerMaxScale = 5.0;
const _viewerEdgeInset = FrostGap.section;

class ImageZoomPage extends ConsumerStatefulWidget {
  const ImageZoomPage({required this.args, super.key});
  final ImageViewerRouteArgs args;
  @override
  ConsumerState<ImageZoomPage> createState() => _ImageZoomPageState();
}

class _ImageZoomPageState extends ConsumerState<ImageZoomPage> {
  final _displayedFrame = DisplayedMediaFrame();
  void _frameChanged() {
    if (mounted) setState(() {});
  }

  late int _index;
  Duration? _videoPosition;
  bool _videoMuted = false;
  double _scale = 1;
  bool _visible = true, _headerHovered = false;
  Timer? _idle;
  var _viewport = FrostMediaViewportController();
  final _headerFocus = FocusNode(debugLabel: 'Viewer controls');
  final _previews = <int, ImageProvider>{};
  final _presentations = <int, StageImagePresentation>{};
  StageImagePresentation _presentation(int index) => _presentations.putIfAbsent(
    index,
    () {
      final presentation =
          index == widget.args.initialIndex && widget.args.presentation != null
          ? widget.args.presentation!
          : StageImagePresentation(
              post: widget.args.collection[index],
              preview: _previews[index],
            );
      presentation.addListener(_frameChanged);
      return presentation;
    },
  );
  void _dismiss() => context.pop();

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex;
    _displayedFrame.addListener(_frameChanged);
    _videoPosition = widget.args.videoPosition;
    _videoMuted = widget.args.videoMuted;
    if (widget.args.preview case final image?) _previews[_index] = image;
    _arm();
  }

  @override
  void dispose() {
    _idle?.cancel();
    _displayedFrame.dispose();
    _headerFocus.dispose();
    for (final MapEntry(key: index, value: presentation)
        in _presentations.entries) {
      presentation.removeListener(_frameChanged);
      if (index != widget.args.initialIndex ||
          widget.args.presentation == null) {
        presentation.dispose();
      }
    }
    super.dispose();
  }

  void _arm() {
    _idle?.cancel();
    if (_headerHovered || _headerFocus.hasFocus) {
      return;
    }
    _idle = Timer(_viewerIdle, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _show() {
    if (!_visible) setState(() => _visible = true);
    _arm();
  }

  void _select(int index) {
    if (Navigator.of(context).userGestureInProgress) return;
    if (index < 0 ||
        index >= widget.args.collection.length ||
        index == _index) {
      return;
    }
    widget.args.onIndexChanged?.call(index);
    setState(() {
      _index = index;
      _videoPosition = null;
      _videoMuted = false;
      _scale = 1;
      // A keyed viewport may mount before its outgoing State disposes. Each
      // occurrence owns a fresh reset handle, preserving one-viewport binding.
      _viewport = FrostMediaViewportController();
    });
    _show();
  }

  void _zoom(bool increase) {
    _viewport.zoomTo(
      increase ? _scale * _viewerZoomStep : _scale / _viewerZoomStep,
    );
    _show();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (Navigator.of(context).userGestureInProgress) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    _show();
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _dismiss();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.numpadAdd:
        if (_scale < _viewerMaxScale) _zoom(true);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.minus:
      case LogicalKeyboardKey.numpadSubtract:
        if (_scale > 1) _zoom(false);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (postMediaFormat(widget.args.collection[_index]) ==
            PostMediaFormat.video) {
          return KeyEventResult.ignored;
        }
        _select(_index - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (postMediaFormat(widget.args.collection[_index]) ==
            PostMediaFormat.video) {
          return KeyEventResult.ignored;
        }
        _select(_index + 1);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.args.collection[_index];
    final index = _index;
    final presentation = _presentation(index);
    Widget chrome({required Widget child}) =>
        FrostPresence(visible: _visible, child: child);
    final controls = ViewerControls(
      post: post,
      presentation: presentation,
      displayedFrame: _displayedFrame,
      index: index,
      itemCount: widget.args.collection.length,
      scale: _scale,
      maxScale: _viewerMaxScale,
      onClose: _dismiss,
      onSelect: _select,
      onZoom: _zoom,
    );
    final clear = FrostThemeTokens.of(
      context,
    ).onMediaScrim.withValues(alpha: 0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Edge-to-edge transparent system bars keep the viewer immersive without
      // a first-use system-modal prompt interrupting the playback handoff.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: clear,
        systemNavigationBarColor: clear,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: FrostWindowTitleContribution(
        path: AppRoute.imageViewer.path,
        page: FrostPageTitle(
          id: this,
          title: '${t.imageZoom.title} · #${post.id}',
        ),
        child: Focus(
          autofocus: true,
          onKeyEvent: _key,
          child: MouseRegion(
            onHover: (_) => _show(),
            onEnter: (_) => _show(),
            child: Listener(
              onPointerDown: (_) => _show(),
              // The viewport owns the single media background for both images
              // and videos; chrome is fixed while only media zooms and pans.
              child: ViewerStage(
                post: post,
                index: index,
                presentation: presentation,
                displayedFrame: _displayedFrame,
                preview: _previews[index],
                videoPosition: _videoPosition,
                videoMuted: _videoMuted,
                viewport: _viewport,
                scale: _scale,
                maxScale: _viewerMaxScale,
                onDismiss: () =>
                    MediaViewerPage.completeViewportDismissal(context),
                onScaleChanged: (value) {
                  if (mounted && index == _index && value != _scale) {
                    setState(() => _scale = value);
                    _arm();
                  }
                },
                onImageReady: (image) {
                  if (image != null && mounted) {
                    _previews[index] = image;
                  }
                },
                overlay: Stack(
                  children: [
                    for (final previous in [true, false])
                      Align(
                        alignment: previous
                            ? AlignmentDirectional.centerStart
                            : AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _viewerEdgeInset,
                          ),
                          child: chrome(
                            child: ClipOval(
                              child: FrostSurface(
                                role: FrostSurfaceRole.onMediaChrome,
                                elevated: false,
                                borderRadius: BorderRadius.circular(
                                  FrostControlSize.regular.height(context) / 2,
                                ),
                                child: FrostButton.icon(
                                  size: FrostControlSize.regular,
                                  label: previous
                                      ? t.frost.previous
                                      : t.frost.next,
                                  icon: previous
                                      ? appIcons.chevronLeft
                                      : appIcons.chevronRight,
                                  style: FrostIconButtonStyle.onMedia,
                                  onPressed: previous
                                      ? (_index > 0
                                            ? () => _select(_index - 1)
                                            : null)
                                      : (_index + 1 <
                                                widget.args.collection.length
                                            ? () => _select(_index + 1)
                                            : null),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: FrostGap.group + FrostGap.related,
                          ),
                          child: chrome(
                            child: FrostBadge(
                              label:
                                  '${_index + 1} / ${widget.args.collection.length}',
                              tone: FrostBadgeTone.onMedia,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: MouseRegion(
                        onEnter: (_) {
                          _headerHovered = true;
                          _show();
                        },
                        onExit: (_) {
                          _headerHovered = false;
                          _arm();
                        },
                        child: Focus(
                          focusNode: _headerFocus,
                          canRequestFocus: false,
                          onFocusChange: (_) => _show(),
                          child: chrome(
                            child: FrostSurface(
                              role: FrostSurfaceRole.onMediaChrome,
                              borderRadius: BorderRadius.zero,
                              child: controls,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
