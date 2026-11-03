import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/media_viewer_page.dart';
import 'package:booruflow/features/image_viewer/viewer_controls.dart';
import 'package:booruflow/features/image_viewer/viewer_stage.dart';
import 'package:booruflow/features/posts/displayed_media_frame.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/stage_image_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';
import 'package:go_router/go_router.dart';

const _viewerZoomStep = 1.5;
const _viewerMaxScale = 5.0;

/// How many posts from the loaded end paging starts loading the next page.
const _prefetchAhead = 3;

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

  late List<Post> _collection;
  late int _index;
  Duration? _videoPosition;
  bool _videoMuted = false;
  double _scale = 1;
  var _viewport = FrostMediaViewportController();
  final _previews = <int, ImageProvider>{};
  final _presentations = <int, StageImagePresentation>{};
  StageImagePresentation _presentation(int index) => _presentations.putIfAbsent(
    index,
    () {
      final presentation =
          index == widget.args.initialIndex && widget.args.presentation != null
          ? widget.args.presentation!
          : StageImagePresentation(
              post: _collection[index],
              preview: _previews[index],
            );
      presentation.addListener(_frameChanged);
      return presentation;
    },
  );

  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    context.pop();
  }

  @override
  void initState() {
    super.initState();
    _collection = widget.args.collection;
    _index = widget.args.initialIndex;
    _displayedFrame.addListener(_frameChanged);
    _videoPosition = widget.args.videoPosition;
    _videoMuted = widget.args.videoMuted;
    if (widget.args.preview case final image?) _previews[_index] = image;
  }

  @override
  void dispose() {
    _displayedFrame.dispose();
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

  bool get _hasMore => widget.args.paging?.hasMore() ?? false;
  Future<void>? _pendingLoad;

  /// Loads the next page of the collection the viewer opened from. A failure
  /// shows the error and leaves paging usable to retry.
  Future<void> _loadMore() =>
      _pendingLoad ??= _fetchMore().whenComplete(() => _pendingLoad = null);

  Future<void> _fetchMore() async {
    try {
      final items = await widget.args.paging!.loadMore();
      if (!mounted) return;
      setState(() {
        if (items.length > _collection.length) {
          _collection = [..._collection, ...items.skip(_collection.length)];
        }
      });
    } catch (error) {
      if (mounted) FrostToast.fromError(context, error);
    }
  }

  Future<void> _loadAndSelect(int index) async {
    await _loadMore();
    if (mounted && index < _collection.length) _select(index);
  }

  void _select(int index) {
    if (Navigator.of(context).userGestureInProgress) return;
    if (index >= _collection.length && _hasMore) {
      unawaited(_loadAndSelect(index));
      return;
    }
    if (index < 0 || index >= _collection.length || index == _index) {
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
    if (_index >= _collection.length - _prefetchAhead && _hasMore) {
      unawaited(_loadMore());
    }
  }

  void _zoom(bool increase) {
    _viewport.zoomTo(
      increase ? _scale * _viewerZoomStep : _scale / _viewerZoomStep,
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (Navigator.of(context).userGestureInProgress) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _close();
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
        if (postMediaFormat(_collection[_index]) == PostMediaFormat.video) {
          return KeyEventResult.ignored;
        }
        _select(_index - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (postMediaFormat(_collection[_index]) == PostMediaFormat.video) {
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
    final post = _collection[_index];
    final index = _index;
    final presentation = _presentation(index);
    final clear = FrostThemeTokens.of(
      context,
    ).onMediaScrim.withValues(alpha: 0);
    final viewer = Focus(
      autofocus: true,
      onKeyEvent: _key,
      // The viewport owns the single media background for both images and
      // videos; chrome is fixed while only media zooms and pans.
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
        // Pull-down reveals the page below, which the opaque desktop viewer
        // does not paint: Escape and Close leave instead.
        onDismiss: frostUsesCustomTitleBar
            ? null
            : () => MediaViewerPage.completeViewportDismissal(context),
        onScaleChanged: (value) {
          if (mounted && index == _index && value != _scale) {
            setState(() => _scale = value);
          }
        },
        onImageReady: (image) {
          if (image != null && mounted) {
            _previews[index] = image;
          }
        },
        overlay: FrostMediaChrome(
          top: ViewerTopBar(
            post: post,
            displayedFrame: _displayedFrame,
            index: index,
            itemCount: _collection.length,
            onClose: () => _close(),
          ),
          bottom: ViewerBottomBar(
            post: post,
            presentation: presentation,
            scale: _scale,
            maxScale: _viewerMaxScale,
            onZoom: _zoom,
          ),
          start: FrostButton.iconOnMedia(
            size: FrostControlSize.regular,
            label: t.frost.previous,
            icon: appIcons.chevronLeft,
            onPressed: _index > 0 ? () => _select(_index - 1) : null,
          ),
          end: FrostButton.iconOnMedia(
            size: FrostControlSize.regular,
            label: t.frost.next,
            icon: appIcons.chevronRight,
            onPressed: _index + 1 < _collection.length || _hasMore
                ? () => _select(_index + 1)
                : null,
          ),
        ),
      ),
    );
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
        child: viewer,
      ),
    );
  }
}
