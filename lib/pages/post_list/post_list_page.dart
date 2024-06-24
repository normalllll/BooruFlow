import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:yande_gui/components/loading_more_indicator/loading_more_indicator.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/enums.dart';
import 'package:yande_gui/pages/post_detail/post_detail_page.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

import 'logic.dart';

class PostListPage extends ConsumerStatefulWidget {
  final List<String>? tags;

  const PostListPage({super.key, this.tags});

  @override
  ConsumerState createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  final scrollController = ScrollController();
  final focusNode = FocusNode();
  late final searchInputController = TextEditingController(text: widget.tags?.join(' '));
  late final provider = postListProvider(runtimeType, tags: widget.tags ?? []);

  bool _hasFocus = false;

  void onFocusChanged() {
    setState(() {
      _hasFocus = focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('rebuild');

    final state = ref.watch(provider);
    double screenWidth = MediaQuery.of(context).size.width;

    int targetWidth = 180;

    int autoRowMax = screenWidth ~/ targetWidth;

    Widget buildRowCountSelector() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: DropdownButton<int>(
          value: state.rowMax,
          items: [
            DropdownMenuItem(value: 0, child: Text('Auto: $autoRowMax')),
            const DropdownMenuItem(value: 2, child: Text('Row: 2')),
            const DropdownMenuItem(value: 3, child: Text('Row: 3')),
            const DropdownMenuItem(value: 4, child: Text('Row: 4')),
            const DropdownMenuItem(value: 5, child: Text('Row: 5')),
          ],
          onChanged: (value) {
            ref.read(provider.notifier).onRowMaxChanged(value ?? 0);
          },
        ),
      );
    }

    Widget buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchInputController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Tags',
                ),
                onSubmitted: (value) {
                  ref.read(provider.notifier).onTagsChanged(value.trim().split(' '));
                },
              ),
            ),
            buildRowCountSelector(),
            IconButton(
              onPressed: () {
                searchInputController.clear();
                if (!focusNode.hasFocus) {
                  ref.read(provider.notifier).onTagsChanged([]);
                }
              },
              icon: Icon(switch (_hasFocus) {
                true => Icons.close,
                false => Icons.refresh,
              }),
            ),
          ],
        ),
      );
    }

    return AutoScaffold(
      verticalOnlyTitleWidget: widget.tags == null ? const Text('Post List') : null,
      titleWidget: switch (widget.tags) {
        null => null,
        final tags => Row(
            children: [
              Text('Post List: ${tags.join(' ')}'),
              const Spacer(),
              buildRowCountSelector(),
            ],
          ),
      },
      builder: (context, horizontal) {
        return Column(
          children: [
            if (widget.tags == null) buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => state.source.refresh(true),
                child: LoadingMoreList(
                  ListConfig(
                    extendedListDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(crossAxisCount: state.rowMax == 0 ? autoRowMax : state.rowMax),
                    controller: scrollController,
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
                                    child: Hero(
                                      tag: item.id,
                                      child: YandeImage(
                                        item.previewUrl,
                                        width: width,
                                        height: height,
                                      ),
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
                      errorRefresh: () {
                        state.source.refresh(true);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          scrollController.jumpTo(0);
        },
        mini: true,
        child: const Icon(Icons.vertical_align_top_outlined, color: Colors.white),
      ),
    );
  }
}
