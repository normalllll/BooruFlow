import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/pages/downloader/logic.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/post_detail/logic.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

class PostSimilarWidget extends ConsumerStatefulWidget {
  final int id;
  final double maxWidth;
  final double maxHeight;

  const PostSimilarWidget({
    super.key,
    required this.id,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  ConsumerState createState() => _PostSimilarWidgetState();
}

class _PostSimilarWidgetState extends ConsumerState<PostSimilarWidget> {
  Widget buildPost(Post post) {
    final double calcHeight;
    final double calcWidth;

    if (post.width > post.height) {
      calcWidth = min(widget.maxWidth, post.width.toDouble());
      calcHeight = calcWidth * post.height / post.width;
    } else {
      calcHeight = min(widget.maxHeight, post.height.toDouble());
      calcWidth = calcHeight * post.width / post.height;
    }
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return ImageZoomPage(url: post.fileUrl);
        }));
      },
      onLongPress: () {
        ref.read(downloaderProvider.notifier).addTask(post).then((downloadTaskProvider) {
          if (downloadTaskProvider != null) {
            ref.read(downloadTaskProvider.notifier).doDownload();
          }
        });
      },
      child: YandeImage(
        post.sampleUrl,
        width: calcWidth,
        height: calcHeight,
        placeholderWidget: YandeImage(
          post.previewUrl,
          width: calcWidth,
          height: calcHeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = getSimilarProvider(id: widget.id);

    return switch (ref.watch(provider)) {
      AsyncData(:final value) => Column(
          children: [
            const Text('Similar Posts'),
            for (final post in value.posts) ...[
              const Divider(),
              if (post.parentId == widget.id) Text('Parent Post: ${widget.id}') else Text('Child Post: ${post.id}'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: buildPost(post),
              ),
            ],
          ],
        ),
      AsyncError(:final error) => GestureDetector(
          onTap: () => ref.refresh(provider),
          behavior: HitTestBehavior.opaque,
          child: Text('Error: $error'),
        ),
      _ => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
    };
  }
}
