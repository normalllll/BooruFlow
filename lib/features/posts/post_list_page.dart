import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/features/downloads/logic.dart';
import 'package:yande_gui/features/booru/booru_service.dart';
import 'package:yande_gui/features/posts/models/post.dart';
import 'package:yande_gui/features/posts/widgets/post_search_field.dart';
import 'package:yande_gui/features/posts/widgets/post_waterfall_skeleton.dart';
import 'package:yande_gui/features/posts/resolution.dart';
import 'package:yande_gui/features/posts/widgets/yande_image.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/core/settings_service.dart';
import 'package:yande_gui/shared/app_navigation.dart';
import 'package:yande_gui/src/rust/api/booru_models.dart';
import 'package:yande_gui/shared/app_theme.dart';
import 'package:yande_gui/shared/widgets/auto_scaffold.dart';
import 'package:yande_gui/shared/widgets/data_refresh_view.dart';
import 'package:yande_gui/shared/widgets/loading_more_indicator.dart';

import 'package:yande_gui/features/posts/logic.dart';

class PostListPage extends ConsumerStatefulWidget {
  final List<String>? tags;

  const PostListPage({super.key, this.tags});

  @override
  ConsumerState createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  late var provider = postListProvider(
    runtimeType,
    sourceId: BooruService.instance.selectedSource.value,
    tags: widget.tags ?? [],
  );
  late final ScrollController _scrollController;
  TextEditingController? _searchController;

  bool get needTopPadding => widget.tags == null;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    BooruService.instance.selectedSource.addListener(_handleSourceChanged);
    BooruService.instance.revision.addListener(_handleEngineChanged);
    if (widget.tags case final tags?) {
      _searchController = TextEditingController(text: tags.join(' '));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialLoad());
  }

  @override
  void didUpdateWidget(covariant PostListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.tags, widget.tags)) return;

    provider = postListProvider(
      runtimeType,
      sourceId: BooruService.instance.selectedSource.value,
      tags: widget.tags ?? [],
    );
    final query = widget.tags?.join(' ');
    if (query == null) {
      _searchController?.dispose();
      _searchController = null;
    } else if (_searchController == null) {
      _searchController = TextEditingController(text: query);
    } else {
      _searchController!.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialLoad());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController?.dispose();
    BooruService.instance.selectedSource.removeListener(_handleSourceChanged);
    BooruService.instance.revision.removeListener(_handleEngineChanged);
    super.dispose();
  }

  void _handleSourceChanged() {
    if (!mounted) return;
    setState(() {
      provider = postListProvider(
        runtimeType,
        sourceId: BooruService.instance.selectedSource.value,
        tags: widget.tags ?? [],
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialLoad());
  }

  void _handleEngineChanged() {
    if (!mounted) return;
    ref.invalidate(provider);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialLoad());
  }

  void _ensureInitialLoad() {
    if (!mounted) return;
    final source = ref.read(provider).source;
    if (source.isEmpty &&
        !source.isLoading &&
        source.indicatorStatus == IndicatorStatus.fullScreenBusying) {
      unawaited(source.refresh());
    } else {
      _maybeLoadMore();
    }
  }

  void _handleScroll() => _maybeLoadMore();

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    final source = ref.read(provider).source;
    if (source.isNotEmpty &&
        source.hasMore &&
        !source.isLoading &&
        _scrollController.position.extentAfter < 720) {
      unawaited(source.loadMore());
    }
  }

  List<String> _parseSearchTags(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  void _submitSearch(String text) {
    final tags = _parseSearchTags(text);
    if (tags.isEmpty || listEquals(tags, widget.tags)) return;
    context.pushTaggedPosts(tags);
  }

  Widget _buildResultSearchField() {
    return PostSearchField(
      controller: _searchController!,
      hintText: t.postSearch.title,
      onSubmitted: _submitSearch,
    );
  }

  Widget _buildDesktopSearchHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _buildResultSearchField(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    final configuredColumns = SettingsService.waterfallColumns;
    final useDesktopShell = shouldUseDesktopShell(context);

    final list = StreamBuilder<Iterable<Post>>(
      key: ValueKey(state.source),
      stream: state.source.rebuild,
      initialData: state.source.wrapData(state.source),
      builder: (context, snapshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeLoadMore();
        });

        final source = state.source;
        final showInitialSkeleton =
            source.isEmpty &&
            source.indicatorStatus == IndicatorStatus.fullScreenBusying;
        return DataRefreshView(
          scrollController: _scrollController,
          onRefresh: () => source.refresh(false, false),
          builder: (context, physics, sliverHeader) {
            return CustomScrollView(
              controller: _scrollController,
              physics: physics,
              slivers: [
                sliverHeader,
                if (needTopPadding)
                  SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.paddingOf(context).top),
                  ),
                const SliverToBoxAdapter(child: _SourceStrip()),
                if (widget.tags == null && source.isNotEmpty)
                  const SliverToBoxAdapter(child: _FreepivPromotionBanner()),
                if (showInitialSkeleton)
                  PostWaterfallSkeleton(configuredColumns: configuredColumns),
                if (source.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverWaterfallFlow(
                      gridDelegate: configuredColumns == null
                          ? const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            )
                          : SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                              crossAxisCount: configuredColumns.clamp(1, 100),
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = source[index];
                        return _PostPreviewCard(
                          post: post,
                          onTap: () => context.pushPost(post),
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            YandeDownloads.instance.add(post);
                          },
                        );
                      }, childCount: source.length),
                    ),
                  ),
                if (!showInitialSkeleton) _PostListStatusSliver(source: source),
              ],
            );
          },
        );
      },
    );

    if (widget.tags != null) {
      return Scaffold(
        appBar: useDesktopShell
            ? null
            : AppBar(
                titleSpacing: 0,
                toolbarHeight: 64,
                title: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: _buildResultSearchField(),
                ),
              ),
        body: Column(
          children: [
            if (useDesktopShell) _buildDesktopSearchHeader(),
            Expanded(child: list),
          ],
        ),
      );
    }

    return AutoScaffold(
      topSafeArea: false,
      builder: (context, horizontal) => list,
    );
  }
}

class _PostListStatusSliver extends StatelessWidget {
  const _PostListStatusSliver({required this.source});

  final PostListSource source;

  @override
  Widget build(BuildContext context) {
    var status = source.indicatorStatus;
    if (source.isNotEmpty && status == IndicatorStatus.fullScreenError) {
      status = IndicatorStatus.error;
    } else if (status == IndicatorStatus.none && !source.hasMore) {
      status = IndicatorStatus.noMoreLoad;
    }

    final fullScreen =
        source.isEmpty &&
        (status == IndicatorStatus.fullScreenBusying ||
            status == IndicatorStatus.fullScreenError ||
            status == IndicatorStatus.empty);
    final indicator = LoadingMoreIndicator(
      status: status,
      isSliver: fullScreen,
      error: source.lastError,
      errorRefresh: () {
        source.errorRefresh();
      },
    );

    return fullScreen ? indicator : SliverToBoxAdapter(child: indicator);
  }
}

class _FreepivPromotionBanner extends StatelessWidget {
  const _FreepivPromotionBanner();

  static const _projectUrl = 'https://github.com/normalllll/freepiv';

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Semantics(
            button: true,
            link: true,
            label:
                '${t.postList.freepivPromotionTitle}. ${t.postList.freepivPromotionSubtitle}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => launchUrlString(
                _projectUrl,
                mode: LaunchMode.externalApplication,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surfaceRaised,
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      Color.alphaBlend(
                        tokens.brand.withValues(alpha: 0.14),
                        tokens.surfaceRaised,
                      ),
                      Color.alphaBlend(
                        tokens.accent.withValues(alpha: 0.08),
                        tokens.surfaceRaised,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tokens.brand.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.shadow,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 460;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 16,
                        vertical: compact ? 12 : 14,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/freepiv-icon.png',
                              width: compact ? 52 : 62,
                              height: compact ? 52 : 62,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: compact ? 12 : 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.postList.freepivPromotionTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: tokens.brand.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        child: Text(
                                          'OPEN SOURCE',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: tokens.brand,
                                                fontSize: 9,
                                                letterSpacing: 0.4,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t.postList.freepivPromotionSubtitle,
                                  maxLines: compact ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: compact ? 8 : 16),
                          if (compact)
                            Icon(
                              Icons.open_in_new,
                              size: 20,
                              color: tokens.brand,
                            )
                          else
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: tokens.brand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.postList.freepivPromotionAction,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 17,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard({
    required this.post,
    required this.onTap,
    required this.onLongPress,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final radius = BorderRadius.circular(8);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              tokens.brand.withValues(alpha: 0.018),
              tokens.surfaceRaised,
            ),
            Color.alphaBlend(
              tokens.surfaceTint.withValues(alpha: 0.20),
              tokens.surfaceRaised,
            ),
            tokens.surfaceRaised,
          ],
          stops: const [0, 0.62, 1],
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: tokens.brand.withValues(alpha: 0.06),
            highlightColor: tokens.brand.withValues(alpha: 0.035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PostPreviewImage(post: post),
                _PostPreviewFooter(post: post, accentColor: tokens.brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostPreviewImage extends StatelessWidget {
  const _PostPreviewImage({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = post.width > 0 && post.height > 0
        ? (post.width / post.height).clamp(0.6, 1.6).toDouble()
        : 1.0;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          YandeImage(
            post.previewUrl,
            sourceId: post.sourceId,
            postId: post.id,
            variant: post.displayMedia.kind,
            fit: BoxFit.cover,
            imageBuilder: (child) => child.animate().fade(duration: 250.ms),
          ),
          if (post.rating != ContentRating.general)
            PositionedDirectional(
              top: 8,
              end: 8,
              child: _RatingBadge(rating: post.rating),
            ),
          if (post.parentId != null || post.hasChildren)
            const PositionedDirectional(
              top: 8,
              start: 8,
              child: _CollectionBadge(),
            ),
          if (Resolution.match(post.width * post.height).title
              case final resolutionLabel when resolutionLabel.isNotEmpty)
            PositionedDirectional(
              end: 8,
              bottom: 8,
              child: _ResolutionBadge(label: resolutionLabel),
            ),
        ],
      ),
    );
  }
}

class _PostPreviewFooter extends StatelessWidget {
  const _PostPreviewFooter({required this.post, required this.accentColor});

  final Post post;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final author = post.author.trim().isEmpty ? 'yande.re' : post.author.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${post.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.favorite_outline,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${post.score}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final ContentRating rating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExplicit = rating == ContentRating.explicit;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isExplicit
            ? const Color(0xFFE53935)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
        border: isExplicit
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
        boxShadow: isExplicit
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          rating.shortLabel,
          style: TextStyle(
            color: isExplicit ? Colors.white : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _SourceStrip extends StatelessWidget {
  const _SourceStrip();

  @override
  Widget build(BuildContext context) {
    final service = BooruService.instance;
    return ValueListenableBuilder<String>(
      valueListenable: service.selectedSource,
      builder: (context, selected, _) {
        return SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            scrollDirection: Axis.horizontal,
            itemCount: service.sources.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final source = service.sources[index];
              final active = source.sourceId == selected;
              final colors = Theme.of(context).colorScheme;
              return Semantics(
                button: true,
                selected: active,
                child: GestureDetector(
                  onTap: () => service.selectSource(source.sourceId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? colors.primary : colors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      source.displayName,
                      style: TextStyle(
                        color: active
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CollectionBadge extends StatelessWidget {
  const _CollectionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Icon(Icons.collections_outlined, size: 13, color: Colors.white),
      ),
    );
  }
}

class _ResolutionBadge extends StatelessWidget {
  const _ResolutionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
