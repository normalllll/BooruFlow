import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/widgets/browse_card.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// Explicit App-owned media outlines, reused by the first-load skeleton only.
const browseSkeletonRatios = <double>[1.2, .8, 1.5, .66, 1.0, 1.4, .75, 1.1];

/// The one media grid browse and results share: it owns the paged source and
/// the scroll position, so a collection keeps both while a detail page is open.
class PostWaterfall extends ConsumerStatefulWidget {
  const PostWaterfall({
    required this.collection,
    required this.header,
    this.filterBar,
    super.key,
  });
  final CollectionIdentity collection;
  final Widget Function(BuildContext context, PostListSource source) header;
  final Widget? filterBar;

  @override
  ConsumerState<PostWaterfall> createState() => PostWaterfallState();
}

class PostWaterfallState extends ConsumerState<PostWaterfall> {
  late PostListSource source;
  late ScrollController _scroll;
  final _waterfall = FrostWaterfallController();

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    source = PostListSource(
      widget.collection.key,
      loader: widget.collection.loader ?? ref.read(collectionLoaderProvider),
    );
    _scroll = ScrollController(keepScrollOffset: false);
  }

  @override
  void didUpdateWidget(PostWaterfall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collection == widget.collection) return;
    source.dispose();
    final previous = _scroll;
    _create();
    // The old viewport detaches in this frame; no post-layout scroll jump.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  Future<bool> refresh() => source.refresh(true);

  @override
  void dispose() {
    source.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): refresh,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): refresh,
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): refresh,
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: ListenableBuilder(
          listenable: source,
          builder: (context, _) => FrostRefreshView(
            scrollController: _scroll,
            onRefresh: source.refresh,
            builder: (context, physics, locators) => AppPage(
              maxWidth: double.infinity,
              header: widget.header(context, source),
              filterBar: widget.filterBar,
              slivers: [
                ?locators.sliverHeader,
                PostGrid(
                  source: source,
                  controller: _waterfall,
                  collection: widget.collection.key,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The media grid of one collection. Opening a card passes the loaded items
/// on, and the means to load more; paging in the detail page brings that card
/// into view through [controller] before the page returns, so the Hero lands
/// on it.
class PostGrid extends ConsumerWidget {
  const PostGrid({
    required this.source,
    required this.controller,
    required this.collection,
    super.key,
  });
  final PostListSource source;
  final FrostWaterfallController controller;
  final CollectionKey collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = ref.watch(
      settingsProvider.select((s) => s.thumbnailSize.preferredTileWidth),
    );
    final labels = Translations.of(context);
    final filtered = collection.ratings.isNotEmpty;
    return FrostSliverDataWaterfallGrid<Post>(
      source: source,
      preferredTileWidth: width,
      controller: controller,
      // The page's content column already insets the grid; its own horizontal
      // inset would push the first column off the header's left line.
      padding: const EdgeInsets.only(
        top: FrostGap.inline,
        bottom: FrostGap.section,
      ),
      firstLoadSkeleton: BrowseSkeleton(preferredTileWidth: width),
      empty: FrostEmptyState(
        icon: appIcons.empty,
        title: switch ((filtered, collection.request)) {
          (true, _) => labels.discovery.noFilteredPosts,
          (_, TagSearchCollectionRequest()) => labels.discovery.noSearchResults,
          _ => labels.discovery.noFeedPosts,
        },
        actionLabel: filtered ? labels.discovery.resetFilters : null,
        onAction: filtered
            ? () => ref.read(settingsProvider.notifier).setRatings(const [])
            : null,
      ),
      itemBuilder: (context, post, index) => BrowseCard(
        key: ValueKey(post.postKey),
        post: post,
        imageRefreshRevision: source.refreshRevision,
        onRefresh: () => unawaited(source.refresh(true)),
        onTap: (tag, preview) => context.pushPost(
          post,
          collection: source.items,
          initialIndex: index,
          heroTag: tag,
          preview: preview,
          onIndexChanged: controller.reveal,
          paging: PostPaging(
            hasMore: () => source.canLoadMore,
            loadMore: source.loadNext,
          ),
          query: switch (collection.request) {
            TagSearchCollectionRequest(:final tags) => tags,
            _ => const [],
          },
        ),
      ),
    );
  }
}

/// First-load placeholder with the card outlines at the real column count.
class BrowseSkeleton extends StatelessWidget {
  const BrowseSkeleton({required this.preferredTileWidth, super.key});
  final double preferredTileWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = frostWaterfallColumnCount(
        width: constraints.maxWidth,
        preferredTileWidth: preferredTileWidth,
        gap: FrostGap.grid,
        textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
      );
      return Padding(
        padding: const EdgeInsets.only(top: FrostGap.grid),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) const SizedBox(width: FrostGap.grid),
              Expanded(
                child: Column(
                  children: [
                    for (var r = 0; r < 4; r++) ...[
                      if (r > 0) const SizedBox(height: FrostGap.grid),
                      FrostMediaCard.skeleton(
                        aspectRatio:
                            browseSkeletonRatios[(c * 3 + r * 2) %
                                browseSkeletonRatios.length],
                        footer: null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
