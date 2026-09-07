import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:booruflow/features/discovery/logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/widgets/post_preview_card.dart';
import 'package:booruflow/features/posts/widgets/post_waterfall_skeleton.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/widgets/data_refresh_view.dart';
import 'package:booruflow/shared/widgets/loading_more_indicator.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

class PostCollectionView extends StatefulWidget {
  const PostCollectionView({
    super.key,
    required this.controller,
    this.columns,
    this.onResetFilters,
  });
  final PostCollectionController controller;
  final int? columns;
  final VoidCallback? onResetFilters;
  @override
  State<PostCollectionView> createState() => _PostCollectionViewState();
}

class _PostCollectionViewState extends State<PostCollectionView> {
  late final ScrollController _scroll;
  int _lastPrefetchCount = 0;
  PostCollectionController get state => widget.controller;
  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(initialScrollOffset: state.scrollOffset)
      ..addListener(_scrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (!state.initialized || state.stale)) {
        state.load(refresh: state.initialized);
      }
    });
  }

  void _scrollChanged() {
    state.scrollOffset = _scroll.offset;
    if (_scroll.position.extentAfter < 720 &&
        state.items.isNotEmpty &&
        state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) state.load();
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_scrollChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        if (state.items.length > _lastPrefetchCount) {
          _lastPrefetchCount = state.items.length;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scroll.hasClients) _scrollChanged();
          });
        }
        if (state.viewportWidth != null &&
            state.viewportWidth != constraints.maxWidth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scroll.hasClients) {
              _scroll.jumpTo(
                _scroll.offset.clamp(0, _scroll.position.maxScrollExtent),
              );
            }
          });
        }
        state.viewportWidth = constraints.maxWidth;
        final columns = widget.columns?.clamp(
          1,
          ((constraints.maxWidth - 24) / 100).floor().clamp(1, 100),
        );
        final skeleton =
            state.items.isEmpty &&
            (!state.initialized && state.error == null || state.loading);
        return DataRefreshView(
          scrollController: _scroll,
          onRefresh: () async {
            await state.load(refresh: true);
            return state.error == null;
          },
          builder: (context, physics, header) => CustomScrollView(
            controller: _scroll,
            physics: physics,
            slivers: [
              header,
              if (skeleton) PostWaterfallSkeleton(configuredColumns: columns),
              if (state.items.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverWaterfallFlow(
                    gridDelegate: columns == null
                        ? const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          )
                        : SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final post = state.items[index];
                      return PostPreviewCard(
                        key: ValueKey(post.postKey),
                        post: post,
                        imageRefreshRevision: state.imageRefreshRevision,
                        onTap: () => context.pushPost(post),
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          BooruDownloads.instance.add(post);
                        },
                      );
                    }, childCount: state.items.length),
                  ),
                ),
              if (!skeleton) _status(),
            ],
          ),
        );
      },
    ),
  );

  Widget _status() {
    if (state.error is NoSupportedRatings) {
      return _emptyState(t.discovery.unsupportedRatings, reset: true);
    }
    if (state.error != null) {
      final empty = state.items.isEmpty;
      final indicator = LoadingMoreIndicator(
        status: empty ? IndicatorStatus.fullScreenError : IndicatorStatus.error,
        isSliver: empty,
        error: state.error,
        errorRefresh: () => state.load(refresh: empty || state.refreshFailed),
      );
      return empty ? indicator : SliverToBoxAdapter(child: indicator);
    }
    if (!state.exhausted && !state.loading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: AppButton(
              label: state.items.isEmpty
                  ? t.discovery.filteredContinue
                  : t.discovery.loadMore,
              onPressed: state.load,
            ),
          ),
        ),
      );
    }
    if (state.exhausted &&
        state.items.isNotEmpty &&
        state.key.request is FeedCollectionRequest &&
        [
          FeedKind.recentPopular,
          FeedKind.historicalPopular,
        ].contains((state.key.request as FeedCollectionRequest).kind)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(t.discovery.rankingComplete, textAlign: TextAlign.center),
        ),
      );
    }
    final empty = state.items.isEmpty;
    if (empty && !state.loading) {
      final filtered = state.key.ratings.isNotEmpty;
      return _emptyState(
        filtered
            ? t.discovery.noFilteredPosts
            : state.key.request is TagSearchCollectionRequest
            ? t.discovery.noSearchResults
            : t.discovery.noFeedPosts,
        reset: filtered,
      );
    }
    final indicator = LoadingMoreIndicator(
      status: state.loading
          ? IndicatorStatus.loadingMoreBusying
          : empty
          ? IndicatorStatus.empty
          : IndicatorStatus.noMoreLoad,
      isSliver: empty,
      errorRefresh: () => state.load(refresh: true),
    );
    return empty ? indicator : SliverToBoxAdapter(child: indicator);
  }

  Widget _emptyState(String message, {bool reset = false}) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined, size: 40),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                AppButton(
                  label: reset ? t.discovery.resetFilters : t.generic.retry,
                  onPressed: reset
                      ? widget.onResetFilters
                      : () => state.load(refresh: true),
                ),
              ],
            ),
          ),
        ),
      );
}
