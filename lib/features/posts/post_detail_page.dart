import 'dart:io';
import 'dart:math' as math;

import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_detail_panel.dart';
import 'package:booruflow/features/posts/widgets/post_image_viewer.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  static const _desktopBreakpoint = 900.0;

  late final PageController _pageController;
  int _pageIndex = 0;

  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relatedGroupId = post.parentId ?? (post.hasChildren ? post.id : null);
    final relatedValue = switch (relatedGroupId) {
      null => null,
      _ => ref.watch(
        getSimilarProvider(sourceId: post.sourceId, id: relatedGroupId),
      ),
    };
    final imagePosts = <Post>[post];
    final seenIds = <String>{post.id};
    if (relatedValue case AsyncData(:final value)) {
      for (final relatedPost in value) {
        if (seenIds.add(relatedPost.id)) imagePosts.add(relatedPost);
      }
    }
    final pageIndex = _pageIndex.clamp(0, imagePosts.length - 1);
    var selectedPost = imagePosts[pageIndex];
    if (selectedPost.author.isEmpty) {
      final detail = ref.watch(
        postAttributionDetailProvider((
          sourceId: selectedPost.sourceId,
          postId: selectedPost.id,
        )),
      );
      if (detail case AsyncData(:final value)) selectedPost = value;
    }
    final loadingRelated = relatedValue is AsyncLoading;
    final relatedError = switch (relatedValue) {
      AsyncError(:final error) => error,
      _ => null,
    };
    final retryRelated = switch (relatedGroupId) {
      null => null,
      _ => () => ref.invalidate(
        getSimilarProvider(sourceId: post.sourceId, id: relatedGroupId),
      ),
    };

    return AutoScaffold(
      showAppBar: false,
      titleWidget: Text(t.postDetail.titleWithId(id: selectedPost.id)),
      builder: (context, horizontal) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _desktopBreakpoint) {
              return _buildDesktopLayout(
                context,
                constraints,
                imagePosts: imagePosts,
                selectedPost: selectedPost,
                pageIndex: pageIndex,
                loadingRelated: loadingRelated,
                relatedError: relatedError,
                retryRelated: retryRelated,
              );
            }
            return _buildMobileLayout(
              context,
              constraints,
              imagePosts: imagePosts,
              selectedPost: selectedPost,
              pageIndex: pageIndex,
              loadingRelated: loadingRelated,
              relatedError: relatedError,
              retryRelated: retryRelated,
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    BoxConstraints constraints, {
    required List<Post> imagePosts,
    required Post selectedPost,
    required int pageIndex,
    required bool loadingRelated,
    required Object? relatedError,
    required VoidCallback? retryRelated,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final panelWidth = math.min(
      460.0,
      math.max(380.0, constraints.maxWidth * 0.34),
    );

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: PostImageViewer(
                posts: imagePosts,
                pageController: _pageController,
                pageIndex: pageIndex,
                loadingRelated: loadingRelated,
                relatedError: relatedError,
                onRetryRelated: retryRelated,
                showPageControls: true,
                onPageChanged: _setPageIndex,
                onOpen: _openImage,
                onDownload: _downloadPost,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant,
            ),
            SizedBox(
              width: panelWidth,
              child: PostDetailPanel(
                key: ValueKey(selectedPost.id),
                post: selectedPost,
                scrollable: true,
                onOpenImage: () => _openImage(selectedPost),
                onDownload: () => _downloadPost(selectedPost),
                onOpenSource: _openUrl,
                onCopy: _copyValue,
                onTagTap: _openTag,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    BoxConstraints constraints, {
    required List<Post> imagePosts,
    required Post selectedPost,
    required int pageIndex,
    required bool loadingRelated,
    required Object? relatedError,
    required VoidCallback? retryRelated,
  }) {
    final size = MediaQuery.sizeOf(context);
    final imageHeight = math.min(
      size.height * 0.62,
      math.max(280.0, constraints.maxWidth * 1.05),
    );

    return CustomScrollView(
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          title: Text(t.postDetail.titleWithId(id: selectedPost.id)),
          floating: true,
          snap: false,
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: imageHeight,
            child: PostImageViewer(
              posts: imagePosts,
              pageController: _pageController,
              pageIndex: pageIndex,
              loadingRelated: loadingRelated,
              relatedError: relatedError,
              onRetryRelated: retryRelated,
              showPageControls: false,
              onPageChanged: _setPageIndex,
              onOpen: _openImage,
              onDownload: _downloadPost,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: PostDetailPanel(
            key: ValueKey(selectedPost.id),
            post: selectedPost,
            scrollable: false,
            onOpenImage: () => _openImage(selectedPost),
            onDownload: () => _downloadPost(selectedPost),
            onOpenSource: _openUrl,
            onCopy: _copyValue,
            onTagTap: _openTag,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _setPageIndex(int index) {
    if (_pageIndex == index) return;
    setState(() => _pageIndex = index);
  }

  void _openImage(Post targetPost) {
    context.pushImageViewer(
      url: targetPost.fileUrl ?? targetPost.jpegUrl ?? targetPost.previewUrl,
      width: targetPost.width.toDouble(),
      height: targetPost.height.toDouble(),
      sourceId: targetPost.sourceId,
      postId: targetPost.id,
    );
  }

  void _downloadPost(Post targetPost) {
    HapticFeedback.mediumImpact();
    ref.read(booruDownloadsProvider).add(targetPost);
  }

  void _openTag(String tag) {
    context.pushTaggedPosts([tag], sourceId: widget.post.sourceId);
  }

  Future<void> _copyValue(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppToast.success(t.generic.copiedWithValue(value: value));
  }

  Future<void> _openUrl(String url) async {
    var targetUrl = url;
    if (url.startsWith('https://i.pximg.net/')) {
      final id = url.split('/').last.split('_').first;
      targetUrl = 'https://www.pixiv.net/artworks/$id';
    }

    final schemeUrl = _pixivSchemeUrlFromWebUrl(targetUrl);
    if (schemeUrl != null && await _openExternalUrl(schemeUrl)) return;
    await _openExternalUrl(targetUrl);
  }

  String? _pixivSchemeUrlFromWebUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host != 'www.pixiv.net' && host != 'pixiv.net') return null;

    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'artworks') {
      return 'pixiv://illusts/${segments[1]}';
    }
    if (segments.length >= 2 && segments[0] == 'users') {
      return 'pixiv://users/${segments[1]}';
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
}
