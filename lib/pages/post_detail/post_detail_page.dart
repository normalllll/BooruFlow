import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/image_zoom_page/image_zoom_page.dart';
import 'package:yande_gui/pages/post_detail/post_similar_widget.dart';
import 'package:yande_gui/pages/post_list/post_list_page.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  ConsumerState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  static const double _desktopSidebarWidth = 360;
  static const double _desktopGap = 20;
  static const EdgeInsets _desktopPagePadding = EdgeInsets.fromLTRB(
    20,
    16,
    20,
    20,
  );
  static const EdgeInsets _desktopImagePadding = EdgeInsets.fromLTRB(
    24,
    24,
    24,
    32,
  );

  final ScrollController _desktopMetadataController = ScrollController();
  final ScrollController _desktopImageController = ScrollController();

  Post get post => widget.post;

  @override
  void dispose() {
    _desktopMetadataController.dispose();
    _desktopImageController.dispose();
    EasyLoading.dismiss();
    super.dispose();
  }

  static String formatIntDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    ).toLocal();

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
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

    final schemeUrl = _pixivSchemeUrlFromWebUrl(url);

    // try pixiv://
    if (schemeUrl != null) {
      final openedScheme = await _openExternalUrl(schemeUrl);

      if (openedScheme) {
        return;
      }
    }

    await _openExternalUrl(url);
  }

  String? _pixivSchemeUrlFromWebUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();

    if (host != 'www.pixiv.net' && host != 'pixiv.net') {
      return null;
    }

    final segments = uri.pathSegments;

    if (segments.length >= 2 && segments[0] == 'artworks') {
      final id = segments[1];
      return 'pixiv://illusts/$id';
    }

    if (segments.length >= 2 && segments[0] == 'users') {
      final id = segments[1];
      return 'pixiv://users/$id';
    }

    return null;
  }

  Future<bool> _openExternalUrl(String url) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [url]);

        return result.exitCode == 0;
      }

      return await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  Widget buildLinkRow(String label, String url, Function() onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(ClipboardData(text: url));
        EasyLoading.showSuccess(i18n.generic.copiedWithValue(post.source));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
            Expanded(
              child: Text(
                url,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.blueAccent,
                  overflow: TextOverflow.ellipsis,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMetadata({
    EdgeInsetsGeometry margin = const EdgeInsets.all(8),
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDetailRow(
              i18n.postDetail.createdAt,
              formatIntDateTime(post.createdAt),
            ),
            buildDetailRow(i18n.postDetail.author, post.author),
            if (RegExp(
              r'^(?:http|https)://[\w\-]+(?:\.[\w\-]+)*(?::\d+)?(?:/\S*)?$',
              caseSensitive: false,
            ).hasMatch(post.source))
              buildLinkRow(
                i18n.postDetail.source,
                post.source,
                () => openUrl(post.source),
              )
            else
              buildDetailRow(i18n.postDetail.source, post.source),
            buildDetailRow(i18n.postDetail.width, '${post.width}'),
            buildDetailRow(i18n.postDetail.height, '${post.height}'),
            buildDetailRow(i18n.postDetail.score, '${post.score}'),
            buildDetailRow(
              i18n.postDetail.size,
              '${(post.fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
            ),
            buildDetailRow(i18n.postDetail.parent, '${post.parentId}'),
            buildDetailRow(i18n.postDetail.hasChildren, '${post.hasChildren}'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                runSpacing: 6,
                spacing: 6,
                children: [
                  for (final tag in post.tags.split(' '))
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostListPage(tags: [tag]),
                          ),
                        );
                      },
                      onLongPress: () {
                        //set clipboard
                        Clipboard.setData(ClipboardData(text: tag));
                        EasyLoading.showSuccess(
                          i18n.generic.copiedWithValue(tag),
                        );
                        HapticFeedback.mediumImpact();
                      },
                      child: TranslatedTag(text: tag),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImage({required double width, required double height}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageZoomPage(
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
          width: width,
          height: height,
          child: Hero(
            tag: post.id,
            child: YandeImage(
              post.sampleUrl ?? post.previewUrl,
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

  Size _calculateImageSize({
    required double maxWidth,
    required double maxHeight,
  }) {
    final usableMaxWidth = math.max(1.0, maxWidth);
    final usableMaxHeight = math.max(1.0, maxHeight);
    final postWidth = post.width.toDouble();
    final postHeight = post.height.toDouble();

    if (postWidth <= 0 || postHeight <= 0) {
      return Size(usableMaxWidth, usableMaxHeight);
    }

    final scale = math.min(
      usableMaxWidth / postWidth,
      usableMaxHeight / postHeight,
    );

    return Size(postWidth * scale, postHeight * scale);
  }

  List<Widget> buildImageList({
    required double maxWidth,
    required double maxHeight,
    EdgeInsetsGeometry imagePadding = EdgeInsets.zero,
    EdgeInsetsGeometry similarPadding = EdgeInsets.zero,
  }) {
    final imageSize = _calculateImageSize(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    return [
      SliverPadding(
        padding: imagePadding,
        sliver: SliverToBoxAdapter(
          child: buildImage(width: imageSize.width, height: imageSize.height),
        ),
      ),
      if (post.parentId != null || post.hasChildren)
        SliverPadding(
          padding: similarPadding,
          sliver: SliverToBoxAdapter(
            child: PostSimilarWidget(
              id: post.id,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
          ),
        ),
    ];
  }

  Widget buildDesktopLayout(BoxConstraints constraints) {
    final theme = Theme.of(context);
    final bodyWidth = math.max(
      1.0,
      constraints.maxWidth - _desktopPagePadding.horizontal,
    );
    final gap = bodyWidth < 640 ? 12.0 : _desktopGap;
    final preferredSidebarWidth = bodyWidth < 840
        ? math.max(220.0, bodyWidth * 0.36)
        : _desktopSidebarWidth;
    final sidebarWidth = math.min(
      preferredSidebarWidth,
      math.max(1.0, bodyWidth - gap - 160),
    );
    final imageMaxWidth =
        bodyWidth - sidebarWidth - gap - _desktopImagePadding.horizontal;
    final imageMaxHeight =
        constraints.maxHeight -
        _desktopPagePadding.vertical -
        _desktopImagePadding.vertical;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: _desktopPagePadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: sidebarWidth,
              child: Scrollbar(
                controller: _desktopMetadataController,
                child: SingleChildScrollView(
                  controller: _desktopMetadataController,
                  child: buildMetadata(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor.withAlpha(24)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Scrollbar(
                    controller: _desktopImageController,
                    child: CustomScrollView(
                      controller: _desktopImageController,
                      slivers: buildImageList(
                        maxWidth: math.max(1.0, imageMaxWidth),
                        maxHeight: math.max(1.0, imageMaxHeight),
                        imagePadding: _desktopImagePadding,
                        similarPadding: const EdgeInsets.fromLTRB(
                          24,
                          0,
                          24,
                          32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      titleWidget: Text(i18n.postDetail.titleWithId(post.id)),
      builder: (context, horizontal) {
        if (horizontal) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return buildDesktopLayout(constraints);
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
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}
