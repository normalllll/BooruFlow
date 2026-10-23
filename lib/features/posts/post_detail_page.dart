import 'dart:async';
import 'dart:math' as math;
import 'package:booruflow/app/ambient_artwork.dart';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/background.dart';
import 'package:booruflow/core/settings/logic.dart' show settingsProvider;
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/logic.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/posts/widgets/post_detail_controls.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/post_video.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
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

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  late List<Post> _collection;
  late int _index;
  final _displayedFrame = DisplayedMediaFrame();
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
    _displayedFrame.dispose();
    for (final presentation in _presentations.values) {
      presentation.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 || index >= _collection.length || index == _index) return;
    setState(() {
      _index = index;
      _member = null;
    });
    _session.select(_collection[index]);
    _selectAmbient(_collection[index]);
  }

  void _selectAmbient(Post post) => unawaited(
    ref
        .read(ambientArtworkProvider.notifier)
        .select(
          post,
          preview:
              post.postKey ==
                  widget.args.collection[widget.args.initialIndex].postKey
              ? widget.args.preview
              : null,
        ),
  );

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
          onIndexChanged: (index) {
            if (mounted) _select(index);
          },
        ),
      ),
    );
  }

  List<FrostMenuEntry> _menu(Post post) => [
    FrostMenuAction(
      t.postDetail.fullscreen,
      icon: appIcons.fullscreen,
      onSelected: () => _open(post),
    ),
    FrostMenuAction(
      t.discovery.copyLink,
      icon: appIcons.link,
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
      icon: appIcons.externalLink,
      enabled: post.webUrl != null,
      onSelected: post.webUrl == null
          ? null
          : () => _openExternal(post.webUrl!),
    ),
    FrostMenuAction(
      t.postDetail.openSource,
      icon: appIcons.link,
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
  Widget _header(Post post) {
    final actions = [
      postIconAction(
        context,
        label: t.frost.previous,
        icon: appIcons.chevronLeft,
        onPressed: _index > 0 ? () => _select(_index - 1) : null,
      ),
      postIconAction(
        context,
        label: t.frost.next,
        icon: appIcons.chevronRight,
        onPressed: _index + 1 < _collection.length
            ? () => _select(_index + 1)
            : null,
      ),
      postMoreAction(context, _menu(post)),
    ];
    final source = ref
        .read(booruServiceProvider)
        .sourceById(post.sourceId)
        .displayName;
    final title = FrostText(
      '$source · #${post.id}',
      role: FrostTextRole.callout,
      tone: FrostTextTone.secondary,
      numeric: true,
    );
    return FrostPageHeader(
      title: title,
      onBack: () => context.pop(),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _current;
    final key = (sourceId: initial.sourceId, postId: initial.id);
    final detail = _session.detail(initial);
    final post = detail.value ?? initial;
    final loading = detail.request.isLoading && initial.data.tags.isEmpty;
    final heroTag = post.postKey == widget.args.post.postKey
        ? widget.args.heroTag
        : null;
    final family = _session.family(_collection[_index]);
    final layout = FrostDetailLayout(
      key: const ValueKey('post-detail-layout'),
      stackBelow: FrostSizeClass.expanded,
      headerPlacement: FrostDetailHeaderPlacement.page,
      header: _header(post),
      mediaHeader: (context, scrolled) => FrostPageHeader(
        title: scrolled
            ? FrostText(
                postInformationTitle(ref, post),
                role: FrostTextRole.headline,
              )
            : null,
        onBack: () => context.pop(),
        actions: [postMoreAction(context, _menu(post))],
      ),
      backdrop:
          ref.watch(settingsProvider.select((s) => s.background.material)) ==
              BackgroundMaterial.ambient
          ? ref.watch(ambientArtworkProvider)
          : null,
      stage: LayoutBuilder(
        builder: (context, constraints) {
          final radius = FrostMediaStage.radiusOf(context);
          Widget cover(VoidCallback? play) => PostMedia(
            displayedFrame: _displayedFrame,
            presentation: _presentation(post),
            key: ValueKey(('detail-stage', post.postKey)),
            post: post,
            onPlay: play,
            purpose: PostMediaPurpose.stage,
            fit: BoxFit.contain,
            // Capture the initial displayed width once per media identity. Tall
            // natural images never request an original-pixel-size decode.
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
              child: _FamilyMediaControls(
                family: family,
                post: post,
                session: _session,
                onSelected: _selectRelated,
                child: frame,
              ),
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
                borderRadius: FrostRadius.borderRadius(radius),
                onTap: play ?? () => _open(post),
                child: heroTag == null
                    ? image
                    : FrostMediaHero(
                        tag: heroTag,
                        radius: FrostRadius.borderRadius(radius),
                        fit: BoxFit.contain,
                        child: image,
                      ),
              ),
            ),
          );
          if (postMediaFormat(post) != PostMediaFormat.video) {
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
      primary: PostPrimaryInformation(
        key: const ValueKey('primary'),
        post: post,
      ).frostSkeleton(loading),
      actions: PostDetailActions(
        key: const ValueKey('actions'),
        displayedFrame: _displayedFrame,
        post: post,
        onOpen: () => _presentation(post).requestOriginal(post),
        presentation: _presentation(post),
      ).frostSkeleton(loading),
      sections: [
        if (family != null)
          _RelatedPosts(
            key: ValueKey(('family', family.root)),
            post: post,
            family: family,
            session: _session,
            onSelected: _selectRelated,
          ),
        FrostModuleGrid(
          key: const ValueKey('information-cards'),
          items: postInformationModules(post)
              .map(
                (item) => FrostModuleGridItem(
                  span: item.span,
                  child: item.child.frostSkeleton(loading),
                ),
              )
              .toList(),
        ),
        if (detail.request.hasError)
          FrostInlineBanner(
            tone: FrostBannerTone.negative,
            message: describeBooruError(
              detail.request.error!,
              includeDiagnostics: false,
            ),
            actionLabel: t.frost.retry,
            onAction: () {
              ref.invalidate(postAttributionDetailProvider(key));
              _session.retry(post);
            },
          ),
        if (loading || post.data.tags.isNotEmpty)
          PostTagsModule(
            key: const ValueKey('tags'),
            post: post,
          ).frostSkeleton(loading),
        if (post.source.isNotEmpty)
          PostSourceRow(key: const ValueKey('source'), post: post),
      ],
      technical: post.createdAt != 0
          ? PostTechnicalInformation(
              key: const ValueKey('technical'),
              post: post,
            )
          : null,
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
            null => FrostMediaFrame.skeleton(aspectRatio: null),
          },
        ),
      ],
    );
  }
}

/// Only this overlay rebuilds on hover; the media and information stay mounted.
class _FamilyMediaControls extends StatefulWidget {
  const _FamilyMediaControls({
    required this.family,
    required this.post,
    required this.session,
    required this.onSelected,
    required this.child,
  });
  final PostFamily? family;
  final Post post;
  final PostDetailSession session;
  final ValueChanged<Post> onSelected;
  final Widget child;
  @override
  State<_FamilyMediaControls> createState() => _FamilyMediaControlsState();
}

class _FamilyMediaControlsState extends State<_FamilyMediaControls> {
  bool _hovered = false, _focused = false;
  @override
  Widget build(BuildContext context) {
    final family = widget.family;
    if (family == null || family.loading || family.keys.length < 2) {
      return widget.child;
    }
    final index = family.keys.indexOf(postIdentity(widget.post));
    void select(int index) {
      if (widget.session.lookup(family.keys[index]) case final item?) {
        widget.onSelected(item);
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        onFocusChange: (value) => setState(() => _focused = value),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: FrostOnMediaChromeScope(
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
                            child: FrostButton.icon(
                              label: previous ? t.frost.previous : t.frost.next,
                              icon: previous
                                  ? appIcons.chevronLeft
                                  : appIcons.chevronRight,
                              onPressed: previous
                                  ? (index > 0 ? () => select(index - 1) : null)
                                  : (index >= 0 &&
                                            index + 1 < family.keys.length
                                        ? () => select(index + 1)
                                        : null),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(FrostGap.group),
                          child: FrostBadge(
                            label: '${index + 1}/${family.keys.length}',
                            tone: FrostBadgeTone.onMedia,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
