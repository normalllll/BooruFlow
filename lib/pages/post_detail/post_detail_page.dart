import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/components/translated_tag/translated_tag.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/pages/post_detail/logic.dart';
import 'package:yande_gui/router/app_router.dart';
import 'package:yande_gui/services/app_toast.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';
import 'package:yande_gui/themes.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

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
    AppToast.dismissAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relatedGroupId = post.parentId ?? (post.hasChildren ? post.id : null);
    final relatedValue = relatedGroupId != null
        ? ref.watch(getSimilarProvider(id: relatedGroupId))
        : null;
    final imagePosts = <Post>[post];
    final seenIds = <int>{post.id};
    if (relatedValue case AsyncData(:final value)) {
      for (final relatedPost in [value.source, ...value.posts]) {
        if (seenIds.add(relatedPost.id)) imagePosts.add(relatedPost);
      }
    }
    final pageIndex = _pageIndex.clamp(0, imagePosts.length - 1);
    final selectedPost = imagePosts[pageIndex];
    final loadingRelated = relatedValue is AsyncLoading;
    final relatedError = switch (relatedValue) {
      AsyncError(:final error) => error,
      _ => null,
    };
    final retryRelated = relatedGroupId == null
        ? null
        : () => ref.invalidate(getSimilarProvider(id: relatedGroupId));

    return AutoScaffold(
      titleWidget: Text(i18n.postDetail.titleWithId(id: selectedPost.id)),
      topSafeArea: false,
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
              child: _PostImageViewer(
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
              child: _PostDetailPanel(
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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: imageHeight,
            child: _PostImageViewer(
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
          child: _PostDetailPanel(
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
    AppRouter.pushImageViewer(
      context,
      url: targetPost.fileUrl ?? targetPost.jpegUrl ?? targetPost.previewUrl,
      width: targetPost.width.toDouble(),
      height: targetPost.height.toDouble(),
    );
  }

  void _downloadPost(Post targetPost) {
    HapticFeedback.mediumImpact();
    Downloader.instance.add(targetPost);
  }

  void _openTag(String tag) {
    AppRouter.pushTaggedPosts(context, [tag]);
  }

  Future<void> _copyValue(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppToast.success(i18n.generic.copiedWithValue(value: value));
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
      return launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

class _PostImageViewer extends StatelessWidget {
  const _PostImageViewer({
    required this.posts,
    required this.pageController,
    required this.pageIndex,
    required this.loadingRelated,
    required this.relatedError,
    required this.onRetryRelated,
    required this.showPageControls,
    required this.onPageChanged,
    required this.onOpen,
    required this.onDownload,
  });

  final List<Post> posts;
  final PageController pageController;
  final int pageIndex;
  final bool loadingRelated;
  final Object? relatedError;
  final VoidCallback? onRetryRelated;
  final bool showPageControls;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Post> onOpen;
  final ValueChanged<Post> onDownload;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPost = posts[pageIndex];

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: posts.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final pagePost = posts[index];
              return _PostImagePage(
                post: pagePost,
                onOpen: () => onOpen(pagePost),
                onDownload: () => onDownload(pagePost),
              );
            },
          ),
          if (selectedPost.rating != 's')
            PositionedDirectional(
              top: 16,
              end: 16,
              child: _RatingBadge(rating: selectedPost.rating),
            ),
          if (loadingRelated)
            const PositionedDirectional(
              top: 18,
              start: 18,
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (relatedError != null && onRetryRelated != null)
            PositionedDirectional(
              top: selectedPost.rating == 's' ? 12 : 58,
              start: 12,
              child: _RelatedLoadError(
                error: relatedError!,
                onRetry: onRetryRelated!,
              ),
            ),
          if (posts.length > 1) ...[
            PositionedDirectional(
              bottom: 18,
              start: 0,
              end: 0,
              child: Center(
                child: _PageIndicator(
                  pageIndex: pageIndex,
                  pageCount: posts.length,
                ),
              ),
            ),
            if (showPageControls) ...[
              PositionedDirectional(
                start: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _SurfaceIconButton(
                    icon: Icons.chevron_left,
                    tooltip: '',
                    onPressed: pageIndex == 0
                        ? null
                        : () => _animateToPage(pageIndex - 1),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _SurfaceIconButton(
                    icon: Icons.chevron_right,
                    tooltip: '',
                    onPressed: pageIndex >= posts.length - 1
                        ? null
                        : () => _animateToPage(pageIndex + 1),
                  ),
                ),
              ),
            ],
          ],
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SurfaceIconButton(
                  icon: Icons.zoom_out_map_outlined,
                  tooltip: i18n.postDetail.viewOriginal,
                  onPressed: () => onOpen(selectedPost),
                ),
                const SizedBox(width: 8),
                _SurfaceIconButton(
                  icon: Icons.download_outlined,
                  tooltip: i18n.postDetail.download,
                  onPressed: () => onDownload(selectedPost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _animateToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PostImagePage extends StatelessWidget {
  const _PostImagePage({
    required this.post,
    required this.onOpen,
    required this.onDownload,
  });

  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _fitImage(
          post: post,
          maxWidth: math.max(1.0, constraints.maxWidth - 32),
          maxHeight: math.max(1.0, constraints.maxHeight - 32),
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          onLongPress: onDownload,
          child: Center(
            child: SizedBox(
              width: imageSize.width,
              height: imageSize.height,
              child: YandeImage(
                post.sampleUrl ?? post.previewUrl,
                width: imageSize.width,
                height: imageSize.height,
                fit: BoxFit.contain,
                placeholderWidget: YandeImage(
                  post.previewUrl,
                  width: imageSize.width,
                  height: imageSize.height,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.pageIndex, required this.pageCount});

  final int pageIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '${pageIndex + 1} / $pageCount',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RelatedLoadError extends StatelessWidget {
  const _RelatedLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.36)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: error.toString(),
                child: Icon(
                  Icons.error_outline,
                  size: 18,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  i18n.postDetail.relatedLoadFailed,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: onRetry,
                style: const ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStatePropertyAll(Colors.transparent),
                ),
                child: Text(i18n.generic.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostDetailPanel extends StatelessWidget {
  const _PostDetailPanel({
    super.key,
    required this.post,
    required this.scrollable,
    required this.onOpenImage,
    required this.onDownload,
    required this.onOpenSource,
    required this.onCopy,
    required this.onTagTap,
  });

  final Post post;
  final bool scrollable;
  final VoidCallback onOpenImage;
  final VoidCallback onDownload;
  final ValueChanged<String> onOpenSource;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tags = post.tags.split(' ').where((tag) => tag.isNotEmpty).toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    final sourceIsUrl = _isUrl(post.source);
    final content = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '#${post.id}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (post.rating != 's') ...[
            const SizedBox(width: 8),
            _RatingBadge(rating: post.rating),
          ],
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              post.author.trim().isEmpty ? 'yande.re' : post.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _StatsStrip(post: post),
      const SizedBox(height: 18),
      _SectionTitle(title: i18n.postDetail.tags, icon: Icons.tag_outlined),
      const SizedBox(height: 8),
      if (tags.isEmpty)
        Text(
          i18n.generic.notFound,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        )
      else
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onTagTap(tag),
                onLongPress: () => onCopy(tag),
                child: TranslatedTag(text: tag),
              ),
          ],
        ),
      const SizedBox(height: 18),
      _SectionTitle(title: i18n.postDetail.details, icon: Icons.info_outline),
      const SizedBox(height: 4),
      _MetadataRow(
        label: 'ID',
        value: '${post.id}',
        onCopy: () => onCopy('${post.id}'),
      ),
      _MetadataRow(
        label: i18n.postDetail.createdAt,
        value: _formatDateTime(post.createdAt),
      ),
      _MetadataRow(
        label: i18n.postDetail.author,
        value: post.author.trim().isEmpty ? 'yande.re' : post.author,
      ),
      if (post.source.trim().isNotEmpty)
        _MetadataRow(
          label: i18n.postDetail.source,
          value: post.source,
          onTap: sourceIsUrl ? () => onOpenSource(post.source) : null,
          onCopy: () => onCopy(post.source),
        ),
      _MetadataRow(label: i18n.postDetail.width, value: '${post.width} px'),
      _MetadataRow(label: i18n.postDetail.height, value: '${post.height} px'),
      _MetadataRow(
        label: i18n.postDetail.fileType,
        value: post.fileExt.toUpperCase(),
      ),
      _MetadataRow(
        label: i18n.postDetail.rating,
        value: _ratingLabel(post.rating),
      ),
      if (post.parentId != null)
        _MetadataRow(label: i18n.postDetail.parent, value: '${post.parentId}'),
      _MetadataRow(
        label: i18n.postDetail.hasChildren,
        value: '${post.hasChildren}',
      ),
      const SizedBox(height: 18),
      _SectionTitle(
        title: i18n.postDetail.actions,
        icon: Icons.touch_app_outlined,
      ),
      const SizedBox(height: 8),
      _ActionButtons(onDownload: onDownload, onOpenImage: onOpenImage),
    ];

    final body = scrollable
        ? ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: content,
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          );
    return ColoredBox(color: colorScheme.surface, child: body);
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final dimensions = '${post.width}×${post.height}';

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.aspect_ratio_outlined,
            label: i18n.postDetail.size,
            value: dimensions,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatTile(
            icon: Icons.favorite_border,
            label: i18n.postDetail.score,
            value: '${post.score}',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatTile(
            icon: Icons.data_usage_outlined,
            label: i18n.postDetail.size,
            value: '${(post.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatTile(
            icon: Icons.insert_drive_file_outlined,
            label: i18n.postDetail.fileType,
            value: post.fileExt.toUpperCase(),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onDownload, required this.onOpenImage});

  final VoidCallback onDownload;
  final VoidCallback onOpenImage;

  @override
  Widget build(BuildContext context) {
    final downloadButton = FilledButton.icon(
      onPressed: onDownload,
      style: const ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      icon: const Icon(Icons.download_outlined),
      label: Text(i18n.postDetail.download),
    );
    final openButton = OutlinedButton.icon(
      onPressed: onOpenImage,
      style: const ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      icon: const Icon(Icons.zoom_out_map_outlined),
      label: Text(i18n.postDetail.viewOriginal),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [downloadButton, const SizedBox(height: 8), openButton],
          );
        }
        return Row(
          children: [
            Expanded(child: downloadButton),
            const SizedBox(width: 8),
            Expanded(child: openButton),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$label: $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    this.onTap,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueWidget = Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: onTap == null ? colorScheme.onSurface : colorScheme.primary,
        decoration: onTap == null ? null : TextDecoration.underline,
        decorationColor: colorScheme.primary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: onTap == null
                ? valueWidget
                : InkWell(onTap: onTap, child: valueWidget),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              onPressed: onCopy,
              icon: const Icon(Icons.content_copy_outlined, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExplicit = rating == 'e';
    final background = isExplicit
        ? const Color(0xFFE53935)
        : colorScheme.surfaceContainerHighest;
    final foreground = isExplicit ? Colors.white : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: isExplicit
            ? null
            : Border.all(color: colorScheme.outlineVariant),
        boxShadow: isExplicit
            ? const [
                BoxShadow(
                  color: Color(0x52000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExplicit ? Icons.explicit_outlined : Icons.shield_outlined,
              size: 14,
              color: foreground,
            ),
            const SizedBox(width: 5),
            Text(
              _ratingLabel(rating),
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceIconButton extends StatelessWidget {
  const _SurfaceIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final child = Semantics(
      button: true,
      enabled: enabled,
      label: tooltip.isEmpty ? null : tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised.withValues(
                alpha: enabled ? 0.92 : 0.55,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: tokens.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              ),
            ),
          ),
        ),
      ),
    );

    return tooltip.isEmpty ? child : Tooltip(message: tooltip, child: child);
  }
}

Size _fitImage({
  required Post post,
  required double maxWidth,
  required double maxHeight,
}) {
  final width = post.width.toDouble();
  final height = post.height.toDouble();
  if (width <= 0 || height <= 0) return Size(maxWidth, maxHeight);
  final scale = math.min(maxWidth / width, maxHeight / height);
  return Size(width * scale, height * scale);
}

String _formatDateTime(int timestamp) {
  final value = DateTime.fromMillisecondsSinceEpoch(
    timestamp * 1000,
    isUtc: true,
  ).toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

bool _isUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

String _ratingLabel(String rating) {
  return rating == 'e' ? 'R-18' : rating.toUpperCase();
}
