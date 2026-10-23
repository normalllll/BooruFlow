import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_actions.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/features/tags/tag_translations_service.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
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

class PostPrimaryInformation extends ConsumerWidget {
  const PostPrimaryInformation({required this.post, super.key});
  final Post post;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FrostText(postInformationTitle(ref, post), role: FrostTextRole.title1),
      if (post.createdAt != 0 || postCopyrightMetadata(post).isNotEmpty) ...[
        const SizedBox(height: FrostGap.inline),
        FrostMetaLine(
          items: [
            ...postCopyrightMetadata(post),
            if (post.createdAt != 0)
              t.postDetail.uploadedAt(date: postDate(post)),
          ],
        ),
      ],
    ],
  );
}

class PostDetailActions extends ConsumerWidget {
  const PostDetailActions({
    required this.post,
    required this.onOpen,
    this.displayedFrame,
    this.presentation,
    super.key,
  });
  final Post post;
  final VoidCallback onOpen;
  final DisplayedMediaFrame? displayedFrame;
  final StageImagePresentation? presentation;
  Future<void> _copy(BuildContext context, WidgetRef ref) =>
      performPostAction(context, () async {
        await copyDisplayedPostImage(
          context,
          displayedFrame!,
          post.postKey,
          clipboard: ref.read(imageClipboardProvider),
        );
      });
  Widget _download(WidgetRef ref, {required bool text}) => text
      ? FrostButton(
          label: t.postDetail.download,
          icon: appIcons.download,
          variant: FrostButtonVariant.prominent,
          onPressedAsync: () => ref.read(booruDownloadsProvider).add(post),
        )
      : FrostButton.icon(
          label: t.postDetail.download,
          icon: appIcons.download,
          style: FrostIconButtonStyle.standard,
          onPressedAsync: () => ref.read(booruDownloadsProvider).add(post),
        );
  Widget _actions(
    BuildContext context,
    WidgetRef ref, {
    required bool downloadText,
    required bool originalText,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _download(ref, text: downloadText),
      const SizedBox(width: FrostGap.related),
      if (presentation?.canUpgrade(post) ?? true) ...[
        if (originalText)
          FrostButton(
            label: t.postDetail.viewOriginal,
            icon: appIcons.fullscreen,
            loading: presentation?.loadingOriginal(post) ?? false,
            onPressed: onOpen,
          )
        else
          FrostButton.icon(
            label: t.postDetail.viewOriginal,
            icon: appIcons.fullscreen,
            style: FrostIconButtonStyle.standard,
            loading: presentation?.loadingOriginal(post) ?? false,
            onPressed: onOpen,
          ),
        const SizedBox(width: FrostGap.related),
      ],
      FrostButton.icon(
        label: t.discovery.copyImage,
        tooltip: displayedFrame?.readyFor(post.postKey) == true
            ? null
            : t.generic.loading,
        icon: appIcons.copy,
        style: FrostIconButtonStyle.standard,
        loading: displayedFrame?.copying ?? false,
        onPressed:
            ref.watch(imageClipboardProvider).supportsImages &&
                displayedFrame?.readyFor(post.postKey) == true
            ? () => _copy(context, ref)
            : null,
      ),
    ],
  );
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListenableBuilder(
    listenable: Listenable.merge([displayedFrame, presentation]),
    builder: (context, _) => FrostFit(
      candidates: [
        (_) => _actions(context, ref, downloadText: true, originalText: true),
        (_) => _actions(context, ref, downloadText: true, originalText: false),
        (_) => _actions(context, ref, downloadText: false, originalText: false),
        (_) => SingleChildScrollView(
          primary: false,
          scrollDirection: Axis.horizontal,
          child: _actions(
            context,
            ref,
            downloadText: false,
            originalText: false,
          ),
        ),
      ],
    ),
  );
}

List<FrostModuleGridItem> postInformationModules(Post post) {
  final size = post.fileSize;
  final dimensions = post.dimensions;
  final unit = size >= 1024 * 1024 ? 'MB' : 'KB';
  final amount = size / (size >= 1024 * 1024 ? 1024 * 1024 : 1024);
  final fileSize = NumberFormat.decimalPatternDigits(
    locale: LocaleSettings.currentLocale.languageTag,
    decimalDigits: 1,
  ).format(amount);
  return [
    if (dimensions case (final width, final height))
      FrostModuleGridItem(
        child: FrostModule(
          key: const ValueKey('dimensions'),
          title: t.postDetail.dimensions,
          value: '${formatCount(width)} × ${formatCount(height)}',
        ),
      ),
    if (size > 0)
      FrostModuleGridItem(
        child: FrostModule(
          key: const ValueKey('file-size'),
          title: t.postDetail.size,
          value: '$fileSize $unit',
        ),
      ),
    if (post.data.score != null)
      FrostModuleGridItem(
        child: FrostModule(
          key: const ValueKey('score'),
          title: t.postDetail.score,
          value: formatCount(post.score),
        ),
      ),
    if (post.rating != ContentRating.unknown)
      FrostModuleGridItem(
        child: FrostModule(
          key: const ValueKey('rating'),
          title: t.postDetail.rating,
          value: postRatingLabel(post.rating),
        ),
      ),
  ];
}

class PostTagsModule extends ConsumerWidget {
  const PostTagsModule({required this.post, super.key});
  final Post post;
  Future<void> _addToQuery(BuildContext context, String tag) async {
    final query = await context.editSearch(
      [tag],
      sourceId: post.sourceId,
      autofocus: false,
    );
    if (context.mounted && query != null) {
      await context.pushTaggedPosts(query.tags, sourceId: query.sourceId);
    }
  }

  List<FrostMenuEntry> _entries(BuildContext context, String raw) => [
    FrostMenuAction(
      t.postDetail.searchTag,
      icon: appIcons.search,
      onSelected: () => context.pushTaggedPosts([raw], sourceId: post.sourceId),
    ),
    FrostMenuAction(
      t.postDetail.addToSearch,
      icon: appIcons.add,
      onSelected: () => _addToQuery(context, raw),
    ),
    FrostMenuAction(
      t.postDetail.excludeTag,
      icon: appIcons.remove,
      onSelected: () =>
          context.pushTaggedPosts(['-$raw'], sourceId: post.sourceId),
    ),
    FrostMenuAction(
      t.discovery.addCustomTag,
      icon: appIcons.edit,
      onSelected: () => editUserTag(
        context,
        source: post.sourceId,
        locale: LocaleSettings.currentLocale.languageTag,
        value: raw,
      ),
    ),
    FrostMenuAction(
      t.frost.copy,
      icon: appIcons.copy,
      onSelected: () =>
          performPostAction(context, () => copyPostValue(context, raw)),
    ),
  ];
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
    return FrostModule(
      title: t.postDetail.tags,
      content: groups.isEmpty
          ? FrostText(t.generic.notFound, tone: FrostTextTone.secondary)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, group) in groups.indexed) ...[
                  if (index > 0) const SizedBox(height: FrostGap.group),
                  // With no known categories a single general bucket conveys
                  // no classification; do not present it as authoritative.
                  if (groups.length > 1 || group.$1 != TagCategory.general) ...[
                    FrostText(
                      categoryLabel(group.$1),
                      role: FrostTextRole.footnote,
                      tone: FrostTextTone.tertiary,
                    ),
                    const SizedBox(height: FrostGap.inline),
                  ],
                  Wrap(
                    spacing: FrostGap.inline,
                    runSpacing: FrostGap.inline,
                    children: [
                      for (final tag in group.$2)
                        Builder(
                          builder: (context) {
                            final entries = _entries(context, tag.name);
                            return FrostMenuAnchor(
                              entries: entries,
                              builder: (context, focus, toggle) => Focus(
                                focusNode: focus,
                                canRequestFocus: false,
                                child: FrostTag(
                                  label: tag.name,
                                  detail: distinctTagTranslation(
                                    tag.name,
                                    repository.displayName(
                                      post.sourceId,
                                      LocaleSettings.currentLocale.languageTag,
                                      tag.name,
                                    ),
                                  ),
                                  dataColor:
                                      groups.length == 1 &&
                                          group.$1 == TagCategory.general
                                      ? null
                                      : group.$1.colorIndex,
                                  contextMenu: entries,
                                  onPressed: toggle,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

String postSourceDisplay(String source) {
  final uri = Uri.tryParse(source);
  if (uri == null || uri.host.isEmpty) return source;
  final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
  return '$host${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}${uri.hasFragment ? '#${uri.fragment}' : ''}';
}

class PostSourceRow extends StatelessWidget {
  const PostSourceRow({required this.post, super.key});
  final Post post;
  @override
  Widget build(BuildContext context) => FrostListRow(
    title: postSourceDisplay(post.source),
    subtitle: null,
    icon: appIcons.link,
    accessory: FrostRowAccessory.external,
    onPressed: isPostWebUrl(post.source)
        ? () => performPostAction(context, () async {
            if (!await openPostUrl(post.source)) {
              throw StateError(t.generic.loadFailed);
            }
          })
        : null,
  );
}

class PostTechnicalInformation extends StatelessWidget {
  const PostTechnicalInformation({required this.post, super.key});
  final Post post;
  @override
  Widget build(BuildContext context) {
    final details = [
      'ID: ${post.id}',
      if (post.createdAt != 0)
        '${t.postDetail.createdAt}: ${postDate(post, full: true)}',
    ].join('\n');
    return Row(
      children: [
        Expanded(
          child: FrostText(
            [
              if (post.createdAt != 0)
                '${t.postDetail.createdAt} ${postDate(post, full: true)}',
            ].join(' · '),
            role: FrostTextRole.footnote,
            tone: FrostTextTone.tertiary,
            numeric: true,
          ),
        ),
        FrostButton.icon(
          label: t.frost.copyDetails,
          edgeAlignment: FrostButtonEdgeAlignment.end,
          icon: appIcons.copy,
          size: FrostControlSize.compact,
          onPressed: () =>
              performPostAction(context, () => copyPostValue(context, details)),
        ),
      ],
    );
  }
}
