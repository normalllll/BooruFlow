import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:booruflow/app/ambient_artwork.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/logic.dart' show settingsProvider;
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/posts/logic.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/widgets/post_detail_layout.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/post_video.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'detail_session.dart';
import 'displayed_media_frame.dart';
import 'stage_image_presentation.dart';

export 'media_presentation.dart' show postStageMedia;

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({required this.args, super.key});
  final PostDetailRouteArgs args;
  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

/// How many posts from the loaded end paging starts loading the next page.
const _prefetchAhead = 3;

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  late List<Post> _collection;
  late int _index;
  // Each page has its own frame: a neighbour coming into view must not take
  // over what the current post's actions copy.
  final _displayedFrames = <String, DisplayedMediaFrame>{};
  DisplayedMediaFrame _frame(Post post) =>
      _displayedFrames.putIfAbsent(post.postKey, DisplayedMediaFrame.new);
  // Kept across stacked and wide, so a video survives the change of layout.
  final _stageKeys = <String, GlobalKey>{};
  GlobalKey _stageKey(Post post) =>
      _stageKeys.putIfAbsent(post.postKey, GlobalKey.new);

  /// The stacked pages; null while the layout is wide.
  PageController? _pages;

  /// Whether the current page has scrolled its stage out from under the header.
  final _pastStage = ValueNotifier(false);
  final _scrolledPast = <String, bool>{};
  late final PostDetailSession _session;
  final _detailSubscriptions = <ProviderSubscription<AsyncValue<Post>>>[];
  final _familySubscriptions = <ProviderSubscription<AsyncValue<List<Post>>>>[];
  Future<Post> _loadPost(PostIdentity key) {
    final provider = postAttributionDetailProvider(key);
    _detailSubscriptions.add(ref.listenManual(provider, (_, _) {}));
    return ref.read(provider.future);
  }

  Future<List<Post>> _loadFamily(PostIdentity key) {
    final provider = getSimilarProvider(sourceId: key.sourceId, id: key.postId);
    _familySubscriptions.add(ref.listenManual(provider, (_, _) {}));
    return ref.read(provider.future);
  }

  void _detailsChanged() {
    if (mounted) setState(() {});
  }

  final _previews = <String, ImageProvider>{};
  final _presentations = <String, StageImagePresentation>{};
  StageImagePresentation _presentation(Post post) => _presentations.putIfAbsent(
    post.postKey,
    () => StageImagePresentation(post: post, preview: _previews[post.postKey]),
  );
  Post? _member;
  Post get _current => _member ?? _collection[_index];
  late final _ambient = ref.read(ambientArtworkProvider.notifier);

  /// The grid's decoded frame of the work the page opened on, if it shows it.
  ImageProvider? _openingPreview(Post post) =>
      post.postKey == widget.args.collection[widget.args.initialIndex].postKey
      ? widget.args.preview
      : null;

  @override
  void initState() {
    super.initState();
    _collection = widget.args.collection;
    _index = widget.args.initialIndex;
    _session = PostDetailSession(
      initial: _collection[_index],
      knownPosts: _collection,
      loadPost: _loadPost,
      loadFamily: _loadFamily,
    )..addListener(_detailsChanged);
    _session.start();
    // Ambient selection may synchronously publish a ready card provider. Start
    // it outside the mounting stack, without waiting for route animation.
    Future.microtask(() {
      if (mounted) _selectAmbient(_current);
    });
    if (widget.args.preview case final image?) {
      _previews[_collection[_index].postKey] = image;
    }
  }

  @override
  void dispose() {
    _session.removeListener(_detailsChanged);
    _session.dispose();
    for (final subscription in _detailSubscriptions) {
      subscription.close();
    }
    for (final subscription in _familySubscriptions) {
      subscription.close();
    }
    for (final frame in _displayedFrames.values) {
      frame.dispose();
    }
    _pages?.dispose();
    _pastStage.dispose();
    for (final presentation in _presentations.values) {
      presentation.dispose();
    }
    // The window returns to the page below once this one is gone; publishing
    // waits until the tree is no longer locked for unmounting.
    final ambient = _ambient;
    Future.microtask(() => ambient.release(this));
    super.dispose();
  }

  bool get _hasMore => widget.args.paging?.hasMore() ?? false;
  Future<List<Post>>? _pendingLoad;

  /// Loads the next page of the collection this page opened from; the viewer
  /// shares it. A failure throws and leaves paging to retry.
  Future<List<Post>> _loadMore() =>
      _pendingLoad ??= _fetchMore().whenComplete(() => _pendingLoad = null);

  Future<List<Post>> _fetchMore() async {
    final items = await widget.args.paging!.loadMore();
    if (mounted) {
      setState(() {
        if (items.length > _collection.length) {
          _collection = [..._collection, ...items.skip(_collection.length)];
        }
      });
    }
    return _collection;
  }

  Future<void> _loadMoreReporting() async {
    try {
      await _loadMore();
    } catch (error) {
      if (mounted) FrostToast.fromError(context, error);
    }
  }

  Future<void> _loadAndSelect(int index) async {
    await _loadMoreReporting();
    if (mounted && index < _collection.length) _select(index);
  }

  /// Goes to a post from outside the pages: a key, a button, the viewer.
  void _select(int index, {bool animate = true}) {
    if (index >= _collection.length && _hasMore) {
      unawaited(_loadAndSelect(index));
      return;
    }
    if (index < 0 || index >= _collection.length || index == _index) return;
    final pages = _pages;
    if (pages == null || !pages.hasClients) {
      _show(index);
    } else if (animate && !MediaQuery.disableAnimationsOf(context)) {
      // The pages report the change as they pass the middle.
      unawaited(
        pages.animateToPage(
          index,
          duration: FrostMotion.standardDuration,
          curve: FrostMotion.hoverCurve,
        ),
      );
    } else {
      pages.jumpToPage(index);
    }
  }

  void _show(int index) {
    if (index == _index || index >= _collection.length) return;
    setState(() {
      _index = index;
      _member = null;
    });
    _pastStage.value = _scrolledPast[_collection[index].postKey] ?? false;
    _session.select(_collection[index]);
    _selectAmbient(_collection[index]);
    widget.args.onIndexChanged?.call(index);
    if (_index >= _collection.length - _prefetchAhead && _hasMore) {
      unawaited(_loadMoreReporting());
    }
  }

  void _selectAmbient(Post post) =>
      unawaited(_ambient.select(this, post, preview: _openingPreview(post)));

  /// This page's own artwork; until it resolves, the grid frame it opened with
  /// rather than whatever the window showed before.
  ImageProvider? _backdrop(Post post) {
    ref.watch(ambientArtworkProvider);
    return _ambient.imageOf(this) ?? _openingPreview(post);
  }

  void _selectRelated(Post post) {
    if (post.postKey == _current.postKey) return;
    setState(() => _member = post);
    _session.select(post);
    _selectAmbient(post);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final route = ModalRoute.of(context);
    final root = Navigator.of(context, rootNavigator: true);
    // Retained content routes must not consume input intended for a modal on
    // the root navigator, including while that modal previews system Back.
    if (route?.isCurrent == false ||
        root.userGestureInProgress ||
        route?.navigator != root && root.canPop()) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final next = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => _index - 1,
      LogicalKeyboardKey.arrowRight => _index + 1,
      _ => null,
    };
    if (next == null) return KeyEventResult.ignored;
    _select(next);
    return KeyEventResult.handled;
  }

  void _open(Post current, {Duration? playbackPosition, bool muted = false}) {
    final collection = [..._collection]..[_index] = current;
    unawaited(
      context.pushImageViewer(
        ImageViewerRouteArgs(
          collection: collection,
          initialIndex: _index,
          preview: _presentation(current).preview,
          presentation: _presentation(current),
          videoPosition: playbackPosition,
          videoMuted: muted,
          paging: widget.args.paging == null
              ? null
              : PostPaging(hasMore: () => _hasMore, loadMore: _loadMore),
          onIndexChanged: (index) {
            if (mounted) _select(index, animate: false);
          },
        ),
      ),
    );
  }

  List<FrostMenuEntry> _menu(Post post) => [
    FrostMenuAction(
      t.postDetail.fullscreen,
      leading: FrostGlyph.icon(appIcons.fullscreen),
      onSelected: () => _open(post),
    ),
    FrostMenuAction(
      t.discovery.copyLink,
      leading: FrostGlyph.icon(appIcons.link),
      enabled: post.webUrl != null,
      onSelected: post.webUrl == null
          ? null
          : () => performPostAction(
              context,
              () => copyPostValue(context, post.webUrl!),
            ),
    ),
    FrostMenuAction(
      t.frost.openInBrowser,
      leading: FrostGlyph.icon(appIcons.externalLink),
      enabled: post.webUrl != null,
      onSelected: post.webUrl == null
          ? null
          : () => _openExternal(post.webUrl!),
    ),
    FrostMenuAction(
      t.postDetail.openSource,
      leading: FrostGlyph.icon(appIcons.link),
      enabled: isPostWebUrl(post.source),
      onSelected: isPostWebUrl(post.source)
          ? () => _openExternal(post.source)
          : null,
    ),
  ];
  Future<void> _openExternal(String url) =>
      performPostAction(context, () async {
        if (!await openPostUrl(url)) throw StateError(t.generic.loadFailed);
      });
  Post _postAt(int index) => index == _index ? _current : _collection[index];

  /// The stage of the post at [index]; the buttons sit on the fixed stage slot,
  /// not on the media, whose rectangle changes with every post's ratio.
  Widget _stageOf(int index, {required bool stacked}) {
    final initial = _postAt(index);
    final post = _session.detail(initial).value ?? initial;
    final current = index == _index;
    // A page that is only passing by never flies back to the grid.
    final heroTag = current && post.postKey == widget.args.post.postKey
        ? widget.args.heroTag
        : null;
    final radius = postStageRadius(stacked: stacked);
    return _StagePaging(
      index: index,
      count: _collection.length,
      hasMore: _hasMore,
      swipes: !stacked,
      onSelect: _select,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget cover(VoidCallback? play) => PostMedia(
            displayedFrame: _frame(post),
            presentation: _presentation(post),
            key: ValueKey(('detail-stage', post.postKey)),
            post: post,
            onPlay: play,
            purpose: PostMediaPurpose.stage,
            fit: BoxFit.contain,
            // Capture the initial displayed width once per media identity.
            // Tall natural images never request an original-pixel decode.
            decodeWidth: math.max(
              1,
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
            ),
            preview: _previews[post.postKey],
            stageRadius: radius,
            stageBuilder: (_, ratio, frame) => FrostMediaStage(
              key: ValueKey(post.postKey),
              aspectRatio: ratio,
              child: frame,
            ),
            onImageReady: (image) {
              if (image == null || !mounted) return;
              _previews[post.postKey] = image;
            },
            frameBuilder: (image) => Semantics(
              button: true,
              label: '${t.postDetail.fullscreen} · #${post.id}',
              child: FrostClickSurface(
                feedback: FrostClickFeedback.media,
                shape: FrostClickShape.rounded(
                  FrostRadius.borderRadius(radius),
                ),
                onTap: play ?? () => _open(post),
                child: heroTag == null
                    ? image
                    : FrostMediaHero(
                        tag: heroTag,
                        fit: BoxFit.contain,
                        child: image,
                      ),
              ),
            ),
          );
          // Only the page on screen plays; a neighbour shows its poster.
          if (postMediaFormat(post) != PostMediaFormat.video || !current) {
            return cover(null);
          }
          return PostVideo(
            key: ValueKey(('detail-video', post.postKey)),
            post: post,
            preview: _previews[post.postKey],
            cover: cover,
            onFullscreen: (position, muted) =>
                _open(post, playbackPosition: position, muted: muted),
            stage: (ratio, player) => FrostMediaStage(
              key: ValueKey(post.postKey),
              aspectRatio: ratio,
              child: FrostMediaFrame(radius: radius, child: player),
            ),
          );
        },
      ),
    );
  }

  Widget _informationOf(int index) {
    final initial = _postAt(index);
    final key = (sourceId: initial.sourceId, postId: initial.id);
    final detail = _session.detail(initial);
    final post = detail.value ?? initial;
    final loading = detail.request.isLoading && initial.data.tags.isEmpty;
    final family = _session.family(_collection[index]);
    final failure = detail.request.error;
    return PostInformationSliver(
      primary: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: FrostGap.group),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FrostInlineBanner(
                    tone: FrostBannerTone.negative,
                    message: describeBooruError(
                      failure,
                      includeDiagnostics: false,
                    ),
                    actionLabel: t.frost.retry,
                    onAction: () {
                      ref.invalidate(postAttributionDetailProvider(key));
                      _session.retry(post);
                    },
                  ),
                  if (booruErrorDetails(failure) case final details?)
                    FrostErrorDetails.quiet(details: details),
                ],
              ),
            ),
          PostPrimaryInformation(
            key: const ValueKey('primary'),
            post: post,
            loading: loading,
          ),
        ],
      ),
      actions: PostDetailActions(
        key: const ValueKey('actions'),
        displayedFrame: _frame(post),
        post: post,
        onOpen: () => _presentation(post).requestOriginal(post),
        presentation: _presentation(post),
        moreEntries: _menu(post),
      ),
      sections: [
        if (family != null && (family.error != null || family.keys.length > 1))
          _RelatedPosts(
            key: ValueKey(('family', family.root)),
            post: post,
            family: family,
            session: _session,
            onSelected: _selectRelated,
          ),
        if (loading || post.data.tags.isNotEmpty)
          PostTagsSection(
            key: const ValueKey('tags'),
            post: post,
            query: widget.args.query,
          ).frostSkeleton(loading),
        PostInformationSection(key: const ValueKey('information'), post: post),
      ],
    );
  }

  void _stageScrolled(Post page, ScrollMetrics metrics) {
    void update() {
      if (!mounted) return;
      final stage = _stageKey(page).currentContext?.findRenderObject();
      if (stage is! RenderBox || !stage.hasSize) return;
      final header =
          MediaQuery.paddingOf(context).top + FrostPageHeader.verticalHeight;
      final past = metrics.extentBefore >= stage.size.height - header;
      _scrolledPast[page.postKey] = past;
      if (page.postKey == _collection[_index].postKey) _pastStage.value = past;
    }

    // Metrics also arrive during layout, before the header may rebuild.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => update());
    } else {
      update();
    }
  }

  Widget _stacked(Post post) {
    final pages = _pages ??= PageController(initialPage: _index);
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const ValueKey('post-detail-pages'),
          controller: pages,
          itemCount: _collection.length,
          onPageChanged: _show,
          itemBuilder: (context, index) {
            final page = _collection[index];
            return PostStackedScroll(
              key: ValueKey(('post-detail-page', page.postKey)),
              stageKey: _stageKey(page),
              stage: _stageOf(index, stacked: true),
              information: _informationOf(index),
              onMetrics: (metrics) => _stageScrolled(page, metrics),
            );
          },
        ),
        PostMediaHeader(pastStage: _pastStage, menu: _menu(post)),
      ],
    );
  }

  Widget _wide() {
    final old = _pages;
    if (old != null) {
      _pages = null;
      _pastStage.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return PostWideLayout(
      stageKey: _stageKey(_collection[_index]),
      stage: _stageOf(_index, stacked: false),
      information: _informationOf(_index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _current;
    final post = _session.detail(initial).value ?? initial;
    final ambient =
        ref.watch(settingsProvider.select((s) => s.background.material)) ==
        BackgroundMaterial.ambient;
    final layout = LayoutBuilder(
      builder: (context, box) {
        final stacked = postDetailStacked(context, box.biggest);
        return Stack(
          key: const ValueKey('post-detail-layout'),
          fit: StackFit.expand,
          children: [
            PostDetailBackdrop(
              image: ambient ? _backdrop(post) : null,
              stageKey: _stageKey(post),
            ),
            FrostLayoutCrossfade(
              layoutIdentity: stacked,
              child: stacked ? _stacked(post) : _wide(),
            ),
          ],
        );
      },
    );
    return FrostWindowTitleContribution(
      path: '/posts/${widget.args.post.id}',
      page: FrostPageTitle(id: this, title: '#${post.id}'),
      child: Focus(autofocus: true, onKeyEvent: _key, child: layout),
    );
  }
}

class _RelatedPosts extends StatelessWidget {
  const _RelatedPosts({
    required this.post,
    required this.session,
    required this.family,
    required this.onSelected,
    super.key,
  });
  final Post post;
  final PostDetailSession session;
  final PostFamily family;
  final ValueChanged<Post> onSelected;
  @override
  Widget build(BuildContext context) {
    final keys = family.keys;
    final children = keys
        .map(session.lookup)
        .where((item) => item?.parentId == post.id)
        .length;
    final relationships = [
      if (post.parentId != null)
        t.postDetail.parentCount(count: formatCount(1)),
      if (children > 0) t.postDetail.childCount(count: formatCount(children)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostSectionHeader(
          title: t.postDetail.similarPosts,
          trailing: [
            if (relationships.isNotEmpty)
              FrostText(
                relationships.join(' · '),
                role: FrostTextRole.footnote,
                tone: FrostTextTone.secondary,
              ),
          ],
        ),
        const SizedBox(height: FrostGap.related),
        if (family.error != null)
          FrostInlineBanner(
            tone: FrostBannerTone.negative,
            message: t.postDetail.relatedLoadFailed,
            actionLabel: t.frost.retry,
            onAction: () => session.retryFamily(family),
          ),
        FrostThumbnailStrip(
          itemCount: keys.length,
          selectedIndex: keys.contains(postIdentity(post))
              ? keys.indexOf(postIdentity(post))
              : null,
          onSelected: (index) {
            if (session.lookup(keys[index]) case final item?) onSelected(item);
          },
          itemBuilder: (_, index) => switch (session.lookup(keys[index])) {
            final item? => LayoutBuilder(
              builder: (context, constraints) => PostMedia(
                post: item,
                decodeWidth:
                    (math.max(
                              constraints.maxWidth,
                              constraints.maxHeight * item.aspectRatio,
                            ) *
                            MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
              ),
            ),
            null => FrostMediaFrame.skeleton(aspectRatio: null, radius: 0),
          },
        ),
      ],
    );
  }
}

/// Previous and next over the stage while the pointer is on it, and optionally
/// a swipe for touch. Only this overlay rebuilds on hover; the media stays mounted.
class _StagePaging extends StatefulWidget {
  const _StagePaging({
    required this.index,
    required this.count,
    required this.hasMore,
    required this.swipes,
    required this.onSelect,
    required this.child,
  });
  final int index, count;
  final bool hasMore;

  /// Whether a swipe on the stage pages; stacked pages move by themselves.
  final bool swipes;
  final ValueChanged<int> onSelect;
  final Widget child;
  @override
  State<_StagePaging> createState() => _StagePagingState();
}

class _StagePagingState extends State<_StagePaging> {
  static const _swipeVelocity = 300.0;
  bool _hovered = false, _focused = false;

  VoidCallback? _page(int target) =>
      target < 0 || target >= widget.count && !widget.hasMore
      ? null
      : () => widget.onSelect(target);

  @override
  Widget build(BuildContext context) {
    // One structure either way: the stage's media must survive a change here.
    final pageable = widget.count >= 2 || widget.hasMore;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      supportedDevices: const {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      },
      onHorizontalDragEnd: !pageable || !widget.swipes
          ? null
          : (details) {
              final velocity = (details.primaryVelocity ?? 0) * (rtl ? -1 : 1);
              if (velocity.abs() < _swipeVelocity) return;
              _page(widget.index + (velocity < 0 ? 1 : -1))?.call();
            },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          canRequestFocus: false,
          onFocusChange: (value) => setState(() => _focused = value),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              if (pageable && FrostInputCapability.of(context).hoverAvailable)
                Positioned.fill(
                  child: FrostPresence(
                    visible: _hovered || _focused,
                    child: Stack(
                      children: [
                        for (final previous in [true, false])
                          Align(
                            alignment: previous
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: FrostGap.group,
                              ),
                              child: FrostButton.iconOnMedia(
                                label: previous
                                    ? t.frost.previous
                                    : t.frost.next,
                                icon: previous
                                    ? appIcons.chevronLeft
                                    : appIcons.chevronRight,
                                onPressed: _page(
                                  widget.index + (previous ? -1 : 1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
