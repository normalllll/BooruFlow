import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:yande_gui/components/loading_more_indicator/loading_more_indicator.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/enums.dart';
import 'package:yande_gui/global.dart';
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
              child: LoadingMoreCustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: isMobile || widget.tags == null,
                    snap: isMobile,
                    pinned: isDesktop && widget.tags != null,
                    scrolledUnderElevation: 0,
                    title: switch (widget.tags) { final tags? => Text(i18n.postList.titleWithTags(tags.join(' '))), _ => Text(i18n.postList.title) },
                  ),
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      await state.source.refresh();
                    },
                  ),
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
          ],
        );
      },
      floatingActionButton: isDesktop
          ? FloatingActionButton(
              onPressed: () {
                state.source.refresh(true);
              },
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }
}
