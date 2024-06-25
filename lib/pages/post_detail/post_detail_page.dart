import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/pages/downloader/logic.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/post_detail/post_similar_widget.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';
import 'package:yande_gui/widgets/tag/tag.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  ConsumerState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  Post get post => widget.post;

  @override
  void dispose() {
    EasyLoading.dismiss();
    super.dispose();
  }

  static String formatIntDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true).toLocal();

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> openUrl(String url) async {
    if (post.source.startsWith('https://i.pximg.net/')) {
      // try to get id from source because direct link is 403 Forbidden
      final list1 = post.source.split('/');
      final idPart = list1.last;

      final list2 = idPart.split('_');

      final id = list2.first;

      url = 'https://www.pixiv.net/artworks/$id';
    }

    final String? schemeUrl;

    if (url.contains('https://www.pixiv.net/artworks') || url.contains('https://pixiv.net/artworks')) {
      final id = url.split('/').last;
      schemeUrl = 'pixiv://illusts/$id';
    } else if (url.contains('https://www.pixiv.net/users') || url.contains('https://pixiv.net/users')) {
      final id = url.split('/').last;
      schemeUrl = 'pixiv://users/$id';
    } else {
      schemeUrl = null;
    }

    if (schemeUrl case String schemeUrl?) {
      if (Platform.isAndroid) {
        launchUrlString(schemeUrl, mode: LaunchMode.externalApplication).catchError((e) => launchUrlString(url, mode: LaunchMode.externalApplication));
      } else {
        if (await canLaunchUrlString(schemeUrl)) {
          launchUrlString(schemeUrl, mode: LaunchMode.externalApplication);
        } else {
          launchUrlString(url, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget buildMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('id: ${post.id}'),
            Text('date: ${formatIntDateTime(post.createdAt)}'),
            Text('author: ${post.author}'),
            if (RegExp(
              r'^(?:http|https)://[\w\-]+(?:\.[\w\-]+)*(?::\d+)?(?:/\S*)?$',
              caseSensitive: false,
              multiLine: false,
            ).hasMatch(post.source))
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => openUrl(post.source),
                onLongPress: () {
                  //set clipboard
                  Clipboard.setData(ClipboardData(text: post.source));
                  EasyLoading.showSuccess('Copied ${post.source}');
                },
                child: Row(
                  children: [
                    const Text('source: '),
                    Expanded(
                      child: Text(
                        post.source,
                        style: const TextStyle(color: Colors.blueAccent, overflow: TextOverflow.ellipsis),
                      ),
                    )
                  ],
                ),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  //set clipboard
                  Clipboard.setData(ClipboardData(text: post.source));
                  EasyLoading.showSuccess('Copied ${post.source}');
                },
                child: Text('source: ${post.source}', overflow: TextOverflow.ellipsis),
              ),
            Text('width: ${post.width}'),
            Text('height: ${post.height}'),
            Text('score: ${post.score}'),
            Text('size: ${(post.fileSize / 1024 / 1024).toStringAsFixed(2)}MB'),
            Text('parent: ${post.parentId}'),
            Text('hasChildren: ${post.hasChildren}'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                runSpacing: 6,
                spacing: 6,
                children: [
                  for (final tag in post.tags.split(' '))
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostListPage(tags: [tag])));
                      },
                      onLongPress: () {
                        //set clipboard
                        Clipboard.setData(ClipboardData(text: tag));
                        EasyLoading.showSuccess('Copied $tag');
                      },
                      child: TagWidget(
                        text: tag,
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildImage({required double width, required double height}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ImageZoomPage(url: post.fileUrl)));
      },
      onLongPress: () {
        ref.read(downloaderProvider.notifier).addTask(post).then((downloadTaskProvider) {
          if (downloadTaskProvider != null) {
            ref.read(downloadTaskProvider.notifier).doDownload();
          }
        });
      },
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Hero(
            tag: post.id,
            child: YandeImage(
              post.sampleUrl,
              width: width,
              height: height,
              placeholderWidget: YandeImage(
                post.previewUrl,
                width: width,
                height: height,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildImageList({required double maxWidth, required double maxHeight}) {
    final double calcHeight;
    final double calcWidth;

    if (post.width > post.height) {
      calcWidth = maxWidth;
      calcHeight = calcWidth * post.height / post.width;
    } else {
      calcHeight = maxHeight;
      calcWidth = calcHeight * post.width / post.height;
    }
    return [
      SliverToBoxAdapter(
        child: buildImage(width: calcWidth, height: calcHeight),
      ),
      if (post.parentId != null || post.hasChildren)
        SliverToBoxAdapter(
          child: PostSimilarWidget(
            id: post.id,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      titleWidget: Text('Post :${post.id}'),
      builder: (context, horizontal) {
        if (horizontal) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 400,
                    child: buildMetadata(),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: buildImageList(
                        maxWidth: constraints.maxWidth - 400,
                        maxHeight: constraints.maxHeight,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: buildMetadata()),
                  ...buildImageList(
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  )
                ],
              );
            },
          );
        }
      },
    );
  }
}
