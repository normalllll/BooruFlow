import 'dart:math' as math;
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_preview_card.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

// Explicit App-owned media outlines, reused by the first-load skeleton only.
const browseSkeletonRatios = <double>[
  1.32,
  .78,
  1.08,
  1.58,
  .92,
  1.22,
  1.44,
  .86,
  1.16,
  .88,
  1.42,
  1.02,
];
const _preferredMediaWidth = 240.0;
const _maxBrowseColumns = 8;

class PostCollectionView extends ConsumerStatefulWidget {
  const PostCollectionView({
    super.key,
    required this.collection,
    required this.headerBuilder,
    this.filterBarBuilder,
    this.columns,
  });
  final CollectionIdentity collection;
  final Widget Function(BuildContext context, PostListSource source)
  headerBuilder;
  final Widget Function(PostListSource source)? filterBarBuilder;
  final int? columns;
  @override
  ConsumerState<PostCollectionView> createState() => PostCollectionViewState();
}

class PostCollectionViewState extends ConsumerState<PostCollectionView> {
  late PostListSource source;
  late ScrollController _scroll;
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
  void didUpdateWidget(PostCollectionView oldWidget) {
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: source,
    builder: (context, _) => FrostRefreshView(
      scrollController: _scroll,
      onRefresh: source.refresh,
      builder: (context, physics, locators) => FrostBrowseLayout(
        maxWidth: double.infinity,
        contentInset: FrostBrowseContentInset.edge,
        header: widget.headerBuilder(context, source),
        filterBar: widget.filterBarBuilder?.call(source),
        slivers: [
          ?locators.sliverHeader,
          FrostSliverDataWaterfallGrid<Post>(
            source: source,
            columns: widget.columns,
            maxColumns: _maxBrowseColumns,
            preferredTileWidth: _preferredMediaWidth,
            padding: EdgeInsets.zero,
            firstLoadSkeleton: _BrowseSkeleton(columns: widget.columns),
            empty: FrostEmptyState(
              icon: FrostIconSet.of(context).empty,
              title: switch ((
                widget.collection.key.ratings.isNotEmpty,
                widget.collection.key.request,
              )) {
                (true, _) => Translations.of(context).discovery.noFilteredPosts,
                (_, TagSearchCollectionRequest()) => Translations.of(
                  context,
                ).discovery.noSearchResults,
                _ => Translations.of(context).discovery.noFeedPosts,
              },
            ),
            itemBuilder: (context, post, index) => PostPreviewCard(
              key: ValueKey(post.postKey),
              post: post,
              imageRefreshRevision: source.refreshRevision,
              onTap: (tag, preview) => context.pushPost(
                post,
                collection: source.items,
                initialIndex: index,
                heroTag: tag,
                preview: preview,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BrowseSkeleton extends StatelessWidget {
  const _BrowseSkeleton({required this.columns});
  final int? columns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = FrostGap.grid;
      final count = frostWaterfallColumnCount(
        width: FrostContentColumnBudget.columnWidth(
          context,
          constraints.maxWidth,
        ),
        preferredTileWidth: _preferredMediaWidth,
        gap: gap,
        textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
        columns: columns,
        maxColumns: _maxBrowseColumns,
      );
      final tile = math.max(
        1.0,
        (constraints.maxWidth - gap * (count - 1)) / count,
      );
      final rows =
          (MediaQuery.sizeOf(context).height / (tile / 1.6 + gap)).ceil() + 1;
      return FrostWaterfallGrid<int>(
        items: List.generate(rows * count, (index) => index),
        columns: columns,
        maxColumns: _maxBrowseColumns,
        preferredTileWidth: _preferredMediaWidth,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, index, _) => FrostMediaCard.skeleton(
          aspectRatio:
              browseSkeletonRatios[index % browseSkeletonRatios.length],
          footer: null,
        ),
      );
    },
  );
}
