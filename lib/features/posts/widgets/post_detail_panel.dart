import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_models.dart'
    show DownloadBlock;
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/tag_menu.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/ui/custom/download_flight.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

import '../displayed_media_frame.dart';
import '../stage_image_presentation.dart';

String postRatingLabel(ContentRating rating) => switch (rating) {
  ContentRating.general => t.postDetail.ratingGeneral,
  ContentRating.sensitive => t.postDetail.ratingSensitive,
  ContentRating.questionable => t.postDetail.ratingQuestionable,
  ContentRating.explicit => t.postDetail.ratingExplicit,
  ContentRating.unknown => t.postDetail.ratingUnknown,
};

String postDate(Post post, {bool full = false}) {
  final date = DateTime.tryParse(post.data.createdAtIso8601 ?? '')?.toLocal();
  if (date == null) return t.generic.notFound;
  final locale = LocaleSettings.currentLocale.languageTag;
  final format = full
      ? DateFormat.yMd(locale).add_jm()
      : DateFormat.yMd(locale);
  return format.format(date);
}

String postInformationTitle(WidgetRef ref, Post post) {
  ref.watch(userTagsProvider);
  final repository = ref.watch(tagSuggestionRepositoryProvider);
  return postCreator(
    post,
    translate: (raw) => distinctTagTranslation(
      raw,
      repository.displayName(
        post.sourceId,
        LocaleSettings.currentLocale.languageTag,
        raw,
      ),
    ),
  );
}

/// The creator as the title, with copyright and upload date beneath it. The
/// list post supplies all of it; only an unknown creator waits for the detail,
/// and the id stays on the meta line meanwhile.
class PostPrimaryInformation extends ConsumerWidget {
  const PostPrimaryInformation({
    required this.post,
    this.loading = false,
    super.key,
  });
  final Post post;
  final bool loading;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorPending = loading && postHeadlineCategory(post) == null;
    final meta = [
      if (creatorPending) '#${post.id}',
      ...postCopyrightMetadata(post),
      if (post.createdAt != 0) t.postDetail.uploadedAt(date: postDate(post)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostText(
          postInformationTitle(ref, post),
          role: FrostTextRole.title2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          content: true,
        ).frostSkeleton(creatorPending),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: FrostGap.inline),
          FrostText(
            meta.join(' · '),
            role: FrostTextRole.footnote,
            tone: FrostTextTone.tertiary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Download is the one solid button. Narrow rows drop to icons first and then
/// fold the secondary actions into the more menu; the row never wraps.
class PostDetailActions extends ConsumerWidget {
  const PostDetailActions({
    required this.post,
    required this.onOpen,
    required this.moreEntries,
    this.displayedFrame,
    this.presentation,
    this.flightSource,
    super.key,
  });
  final Post post;
  final VoidCallback onOpen;

  /// Where the download flies from and what it shows, when the page has the
  /// artwork on screen. Without one, or when it returns null, the download
  /// does not fly and the added toast confirms it.
  final ({Rect rect, ImageProvider image})? Function()? flightSource;

  /// Full screen, links and the other entries of the more menu.
  final List<FrostMenuEntry> moreEntries;
  final DisplayedMediaFrame? displayedFrame;
  final StageImagePresentation? presentation;

  bool get _canOpenOriginal => presentation?.canUpgrade(post) ?? true;
  bool get _openingOriginal => presentation?.loadingOriginal(post) ?? false;
  bool _canCopy(WidgetRef ref) =>
      ref.watch(imageClipboardProvider).supportsImages &&
      displayedFrame?.readyFor(post.postKey) == true;

  Future<void> _copy(BuildContext context, WidgetRef ref) =>
      performPostAction(context, () async {
        await copyDisplayedPostImage(
          context,
          displayedFrame!,
          post.postKey,
          clipboard: ref.read(imageClipboardProvider),
        );
      });

  /// Claims the post first; only a claimed post flies. Without a flight the
  /// added toast says it was added. The add then runs in the background.
  void _startDownload(BuildContext context, WidgetRef ref) {
    final host = DownloadFlightHost.maybeOf(context);
    unawaited(
      ref
          .read(booruDownloadsProvider)
          .add(
            post,
            flight: host == null
                ? null
                : () {
                    final source = flightSource?.call();
                    return source != null &&
                        host.fly(
                          source: source.rect,
                          image: source.image,
                          claim: BooruDownloads.identityOf(post),
                        );
                  },
          ),
    );
  }

  Widget _download(BuildContext context, WidgetRef ref, {required bool text}) {
    // A post that is saved or being downloaded offers no second download.
    final block = ref.watch(
      downloadBlocksProvider.select(
        (blocks) => blocks[BooruDownloads.identityOf(post)],
      ),
    );
    final label = switch (block) {
      DownloadBlock.saved => t.downloads.downloaded,
      DownloadBlock.inProgress => t.downloads.downloading,
      null => t.postDetail.download,
    };
    final onPressed = block == null ? () => _startDownload(context, ref) : null;
    return text
        ? FrostButton.prominent(
            label: label,
            icon: appIcons.download,
            onPressed: onPressed,
          )
        : FrostButton.iconFilled(
            label: label,
            icon: appIcons.download,
            onPressed: onPressed,
          );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref, {
    required bool downloadText,
    required bool originalText,
    required bool folded,
  }) {
    final running = _openingOriginal
        ? const FrostActionState.running()
        : FrostActionState.idle;
    final canCopy = _canCopy(ref);
    final entries = [
      if (folded) ...[
        if (_canOpenOriginal)
          FrostMenuAction(
            t.postDetail.viewOriginal,
            leading: FrostGlyph.icon(appIcons.zoomIn),
            onSelected: onOpen,
          ),
        FrostMenuAction(
          t.discovery.copyImage,
          leading: FrostGlyph.icon(appIcons.copy),
          enabled: canCopy,
          onSelected: canCopy ? () => _copy(context, ref) : null,
        ),
        const FrostMenuDivider(),
      ],
      ...moreEntries,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _download(context, ref, text: downloadText),
        const SizedBox(width: FrostGap.related),
        if (!folded) ...[
          if (_canOpenOriginal)
            originalText
                ? FrostButton.tinted(
                    label: t.postDetail.viewOriginal,
                    icon: appIcons.zoomIn,
                    state: running,
                    onPressed: onOpen,
                  )
                : FrostButton.icon(
                    label: t.postDetail.viewOriginal,
                    icon: appIcons.zoomIn,
                    state: running,
                    onPressed: onOpen,
                  ),
          FrostButton.icon(
            label: t.discovery.copyImage,
            tooltip: displayedFrame?.readyFor(post.postKey) == true
                ? null
                : t.generic.loading,
            icon: appIcons.copy,
            state: (displayedFrame?.copying ?? false)
                ? const FrostActionState.running()
                : FrostActionState.idle,
            onPressed: canCopy ? () => _copy(context, ref) : null,
          ),
        ],
        FrostMenuAnchor(
          entries: entries,
          builder: (context, focus, toggle) => Focus(
            focusNode: focus,
            canRequestFocus: false,
            child: FrostButton.icon(
              label: t.frost.more,
              icon: appIcons.more,
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListenableBuilder(
    listenable: Listenable.merge([displayedFrame, presentation]),
    builder: (context, _) => FrostFit(
      candidates: [
        (_) => _row(
          context,
          ref,
          downloadText: true,
          originalText: true,
          folded: false,
        ),
        (_) => _row(
          context,
          ref,
          downloadText: true,
          originalText: false,
          folded: false,
        ),
        (_) => _row(
          context,
          ref,
          downloadText: false,
          originalText: false,
          folded: false,
        ),
        (_) => _row(
          context,
          ref,
          downloadText: false,
          originalText: false,
          folded: true,
        ),
      ],
    ),
  );
}

/// Tags grouped by category; a tap searches the tag, the menu has the rest.
class PostTagsSection extends ConsumerWidget {
  const PostTagsSection({required this.post, this.query = const [], super.key});
  final Post post;

  /// The tags of the search the post was listed in, which tag actions refine.
  final List<String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userTagsProvider);
    final repository = ref.watch(tagSuggestionRepositoryProvider);
    final groups = [
      for (final category in [
        TagCategory.artist,
        TagCategory.character,
        TagCategory.copyright,
        TagCategory.general,
        TagCategory.meta,
      ])
        (
          category,
          post.data.tags.where((tag) => tag.category == category).toList(),
        ),
    ].where((group) => group.$2.isNotEmpty).toList();
    // With no known categories a single general bucket conveys no
    // classification; it gets neither a name nor a colour.
    final plain = groups.length == 1 && groups.single.$1 == TagCategory.general;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostSectionHeader(title: t.postDetail.tags),
        const SizedBox(height: FrostGap.related),
        if (groups.isEmpty)
          FrostText(t.generic.notFound, tone: FrostTextTone.secondary)
        else
          for (final (index, group) in groups.indexed) ...[
            if (index > 0) const SizedBox(height: FrostGap.group),
            if (!plain) ...[
              FrostText(
                categoryLabel(group.$1),
                role: FrostTextRole.footnote,
                tone: FrostTextTone.tertiary,
              ),
              const SizedBox(height: FrostGap.inline),
            ],
            FrostWrap(
              children: [
                for (final tag in group.$2)
                  Builder(
                    builder: (context) => FrostTag(
                      label: tag.name,
                      detail: distinctTagTranslation(
                        tag.name,
                        repository.displayName(
                          post.sourceId,
                          LocaleSettings.currentLocale.languageTag,
                          tag.name,
                        ),
                      ),
                      dataColor: plain ? null : group.$1.colorIndex,
                      contextMenu: tagMenuEntries(
                        context,
                        tag.name,
                        sourceId: post.sourceId,
                        query: query,
                      ),
                      onPressed: () => context.pushTaggedPosts([
                        tag.name,
                      ], sourceId: post.sourceId),
                    ),
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

String postSourceDisplay(String source) {
  final uri = Uri.tryParse(source);
  if (uri == null || uri.host.isEmpty) return source;
  final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
  return '$host${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}${uri.hasFragment ? '#${uri.fragment}' : ''}';
}

/// File facts as key-value rows, with a button to copy them all.
class PostInformationSection extends ConsumerWidget {
  const PostInformationSection({required this.post, super.key});
  final Post post;

  String _fileSize() {
    final size = post.fileSize;
    final megabytes = size >= 1024 * 1024;
    final amount = NumberFormat.decimalPatternDigits(
      locale: LocaleSettings.currentLocale.languageTag,
      decimalDigits: 1,
    ).format(size / (megabytes ? 1024 * 1024 : 1024));
    return '$amount ${megabytes ? 'MB' : 'KB'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = post.dimensions;
    final source = ref
        .watch(booruSourcesProvider)
        .where((source) => source.sourceId == post.sourceId)
        .firstOrNull;
    final identity = [?source?.displayName, '#${post.id}'].join(' · ');
    final details = [
      'ID: ${post.id}',
      if (post.createdAt != 0)
        '${t.postDetail.createdAt}: ${postDate(post, full: true)}',
    ].join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostSectionHeader(
          title: t.postDetail.details,
          trailing: [
            FrostButton.icon(
              label: t.frost.copyDetails,
              icon: appIcons.copy,
              size: FrostControlSize.compact,
              onPressed: () => performPostAction(
                context,
                () => copyPostValue(context, details),
              ),
            ),
          ],
        ),
        FrostKeyValueList(
          entries: [
            FrostKeyValue(label: t.postDetail.post, value: identity),
            if (dimensions case (final width, final height))
              FrostKeyValue(
                label: t.postDetail.dimensions,
                value: '${formatCount(width)} × ${formatCount(height)}',
              ),
            if (post.fileSize > 0)
              FrostKeyValue(label: t.postDetail.size, value: _fileSize()),
            if (post.data.score != null)
              FrostKeyValue(
                label: t.postDetail.score,
                value: formatCount(post.score),
              ),
            if (post.rating != ContentRating.unknown)
              FrostKeyValue(
                label: t.postDetail.rating,
                value: postRatingLabel(post.rating),
              ),
            if (post.source.isNotEmpty)
              FrostKeyValue.link(
                label: t.postDetail.source,
                value: postSourceDisplay(post.source),
                onPressed: isPostWebUrl(post.source)
                    ? () => performPostAction(context, () async {
                        if (!await openPostUrl(post.source)) {
                          throw StateError(t.generic.loadFailed);
                        }
                      })
                    : null,
              ),
            if (post.createdAt != 0)
              FrostKeyValue(
                label: t.postDetail.createdAt,
                value: postDate(post, full: true),
              ),
          ],
        ),
      ],
    );
  }
}
