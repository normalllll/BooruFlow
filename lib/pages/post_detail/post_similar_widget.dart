import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/post_detail/logic.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

class PostSimilarWidget extends ConsumerStatefulWidget {
  final int id;
  final double maxWidth;
  final double maxHeight;

  const PostSimilarWidget({super.key, required this.id, required this.maxWidth, required this.maxHeight});

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
        if (post.fileUrl != null) {
          EasyLoading.showError('This item is not ');
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ImageZoomPage(
                  url: post.fileUrl ?? post.jpegUrl ?? post.previewUrl,
                  width: post.width.toDouble(),
                  height: post.height.toDouble(),
                ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Downloader.instance.add(post);
      },
      child: Center(
        child: SizedBox(
          width: calcWidth,
          height: calcHeight >= calcWidth ? null : calcHeight,
          child: YandeImage(
            post.sampleUrl ?? post.previewUrl,
            width: calcWidth,
            height: calcHeight >= calcWidth ? null : calcHeight,
            placeholderWidget: YandeImage(
              post.previewUrl,
              width: calcWidth,
              // height: height,
            ),
          ),
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
          Text(i18n.postDetail.similarPosts),
          for (final post in value.posts) ...[
            const Divider(),
            if (post.parentId == widget.id)
              Text('${i18n.postDetail.parentPost}: ${widget.id}')
            else
              Text('${i18n.postDetail.childPost}: ${post.id}'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: buildPost(post)),
          ],
        ],
      ),
      AsyncError(:final error) => GestureDetector(
        onTap: () => ref.refresh(provider),
        behavior: HitTestBehavior.translucent,
        child: Text(i18n.generic.errorWithValue(error.toString())),
      ),
      _ => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Center(child: CupertinoActivityIndicator())),
    };
  }
}
