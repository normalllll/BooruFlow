import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_attribution.dart';
import 'package:booruflow/features/tags/translated_tag.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';

class PostDetailPanel extends StatelessWidget {
  const PostDetailPanel({
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
          if (post.rating != ContentRating.general) ...[
            const SizedBox(width: 8),
            PostRatingBadge(rating: post.rating),
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
              post.authorLabel,
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
      const SizedBox(height: 6),
      Row(
        children: [
          Tooltip(
            message: t.postDetail.imageSource,
            child: Icon(
              Icons.public,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              post.sourceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      if (post.source.trim().isNotEmpty)
        _MetadataRow(
          label: t.postDetail.source,
          icon: Icons.link,
          value: post.source,
          onTap: sourceIsUrl ? () => onOpenSource(post.source) : null,
          onCopy: () => onCopy(post.source),
        ),
      const SizedBox(height: 12),
      _StatsStrip(post: post),
      const SizedBox(height: 18),
      _SectionTitle(title: t.postDetail.tags, icon: Icons.tag_outlined),
      const SizedBox(height: 8),
      if (tags.isEmpty)
        Text(
          t.generic.notFound,
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
      _SectionTitle(title: t.postDetail.details, icon: Icons.info_outline),
      const SizedBox(height: 4),
      _MetadataRow(label: 'ID', value: post.id, onCopy: () => onCopy(post.id)),
      _MetadataRow(
        label: t.postDetail.createdAt,
        value: _formatDateTime(post.createdAt),
      ),
      _MetadataRow(label: t.postDetail.author, value: post.authorLabel),
      _MetadataRow(label: t.postDetail.width, value: '${post.width} px'),
      _MetadataRow(label: t.postDetail.height, value: '${post.height} px'),
      _MetadataRow(
        label: t.postDetail.fileType,
        value: post.fileExt.toUpperCase(),
      ),
      _MetadataRow(
        label: t.postDetail.rating,
        value: _ratingLabel(post.rating),
      ),
      if (post.parentId != null)
        _MetadataRow(label: t.postDetail.parent, value: '${post.parentId}'),
      _MetadataRow(
        label: t.postDetail.hasChildren,
        value: '${post.hasChildren}',
      ),
      const SizedBox(height: 18),
      _SectionTitle(
        title: t.postDetail.actions,
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
            label: t.postDetail.size,
            value: dimensions,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatTile(
            icon: Icons.favorite_border,
            label: t.postDetail.score,
            value: '${post.score}',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatTile(
            icon: Icons.data_usage_outlined,
            label: t.postDetail.size,
            value: '${(post.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatTile(
            icon: Icons.insert_drive_file_outlined,
            label: t.postDetail.fileType,
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
    final downloadButton = AppButton(
      label: t.postDetail.download,
      kind: AppButtonKind.primary,
      onPressed: onDownload,
      icon: Icons.download_outlined,
    );
    final openButton = AppButton(
      label: t.postDetail.viewOriginal,
      onPressed: onOpenImage,
      icon: Icons.zoom_out_map_outlined,
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
    this.icon,
    this.onTap,
    this.onCopy,
  });

  final String label;
  final String value;
  final IconData? icon;
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
        color: switch (onTap) {
          null => colorScheme.onSurface,
          _ => colorScheme.primary,
        },
        decoration: switch (onTap) {
          null => null,
          _ => TextDecoration.underline,
        },
        decorationColor: colorScheme.primary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Tooltip(
              message: label,
              child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
          ] else
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
            child: switch (onTap) {
              null => valueWidget,
              _ => InkWell(onTap: onTap, child: valueWidget),
            },
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            AppIconButton(
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

class PostRatingBadge extends StatelessWidget {
  const PostRatingBadge({super.key, required this.rating});

  final ContentRating rating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExplicit = rating == ContentRating.explicit;
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

String _ratingLabel(ContentRating rating) {
  return rating.shortLabel;
}
