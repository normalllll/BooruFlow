import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';
import 'package:yande_gui/components/loading_more_indicator/loading_more_indicator.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/enums.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'logic.dart';

class PostListPage extends ConsumerStatefulWidget {
  final List<String>? tags;

  const PostListPage({super.key, this.tags});

  @override
  ConsumerState createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  late final provider = postListProvider(runtimeType, tags: widget.tags ?? []);

  Widget buildPullToRefreshHeader(PullToRefreshScrollNotificationInfo? info) {
    return SliverToBoxAdapter(
      child: switch (info?.mode) {
        null => const SizedBox(),
        PullToRefreshIndicatorMode.drag => const Icon(Icons.arrow_downward_outlined),
        PullToRefreshIndicatorMode.armed => const Icon(Icons.arrow_upward_outlined),
        PullToRefreshIndicatorMode.snap => const Icon(Icons.arrow_upward_outlined),
        PullToRefreshIndicatorMode.refresh => const CupertinoActivityIndicator(),
        PullToRefreshIndicatorMode.done => const Icon(Icons.check),
        PullToRefreshIndicatorMode.canceled => const Icon(Icons.close_outlined),
        PullToRefreshIndicatorMode.error => const Icon(Icons.error_outline_outlined),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    double screenWidth = MediaQuery.of(context).size.width;

    int targetWidth = 180;

    int columnsMax = screenWidth ~/ targetWidth;

    return AutoScaffold(
      topSafeArea: false,
      builder: (context, horizontal) {
        return Column(
          children: [
            Expanded(
              child: PullToRefreshNotification(
                maxDragOffset: 30,
                pullBackOnRefresh: true,
                onRefresh: () async {
                  await HapticFeedback.mediumImpact();
                  return state.source.refresh(true);
                },
                child: LoadingMoreCustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      scrolledUnderElevation: 0,
                      title: switch (widget.tags) { final tags? => Text(i18n.postList.titleWithTags(tags.join(' '))), _ => Text(i18n.postList.title) },
                    ),
                    PullToRefreshContainer(buildPullToRefreshHeader),
                    LoadingMoreSliverList(
                      SliverListConfig(
                        extendedListDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(crossAxisCount: SettingsService.waterfallColumns ?? columnsMax),
                        itemBuilder: (BuildContext context, item, int index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostDetailPage(post: item)));
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const padding = 4;
                                final width = constraints.maxWidth - padding * 2;
                                final height = (item.height * width / item.width) - padding * 2;
                                return Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: YandeImage(
                                          item.previewUrl,
                                          width: width,
                                          height: height,
                                          imageBuilder: (child) {
                                            return Hero(
                                              tag: item.id,
                                              child: child,
                                            ).animate().fade(duration: 250.ms);
                                          },
                                        ),
                                      ),
                                      if (item.parentId != null)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                            child: const Icon(Icons.more_outlined, color: Colors.white),
                                          ),
                                        )
                                      else if (item.hasChildren)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                            child: const Icon(Icons.more_horiz, color: Colors.white),
                                          ),
                                        ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                          child: Text(
                                            '${Resolution.match(item.width * item.height).title} ${item.width} x ${item.height}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        sourceList: state.source,
                        padding: EdgeInsets.zero,
                        indicatorBuilder: (context, status) => LoadingMoreIndicator(
                          status: status,
                          isSliver: true,
                          errorRefresh: () {
                            state.source.errorRefresh();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
