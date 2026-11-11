import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/edit_user_tag.dart';
import 'package:booruflow/features/tags/tag_menu.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

const _categories = [
  TagCategory.artist,
  TagCategory.character,
  TagCategory.copyright,
  TagCategory.general,
  TagCategory.meta,
];

/// The Tags destination: the saved tags and the current source's common tags
/// by category. Opening a tag opens its results. With [invalidQuery] it stands
/// in for a results link that could not be read.
class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({this.invalidQuery = false, super.key});
  final bool invalidQuery;

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends ConsumerState<TagsPage> {
  final _search = FrostPageHeaderSearchController();
  SearchSession? _session;
  String? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_session == null) {
      _session = SearchSession(locale: locale, followSource: true);
    } else if (_locale != locale) {
      Future.microtask(() {
        if (mounted) {
          ref.read(searchProvider(_session!).notifier).setLocale(locale);
        }
      });
    }
    _locale = locale;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _add(String sourceId) => editUserTag(
    context,
    source: sourceId,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  Widget _tag(
    String raw, {
    required String sourceId,
    required String label,
    String? detail,
    int? dataColor,
  }) => FrostTag(
    label: label,
    detail: detail,
    dataColor: dataColor,
    contextMenu: tagMenuEntries(context, raw, sourceId: sourceId),
    onPressed: () => context.pushTaggedPosts([raw], sourceId: sourceId),
  );

  @override
  Widget build(BuildContext context) {
    final session = _session!;
    final state = ref.watch(searchProvider(session));
    final logic = ref.read(searchProvider(session).notifier);
    final sources = ref.watch(booruSourcesProvider);
    final source = sources
        .where((item) => item.sourceId == state.sourceId)
        .firstOrNull;
    final aliases = [
      for (final alias in ref.watch(userTagsProvider).value ?? <UserTagAlias>[])
        if (alias.appliesTo(state.sourceId)) alias,
    ];
    final common = state.common.value;
    final commonUnsupported =
        source?.capabilities.discovery.commonTags ==
        CapabilityAvailability.unsupported;
    String? translation(TagSuggestion tag) {
      final name = logic.displayName(tag.value, tag.displayName);
      return name == tag.value ? null : name;
    }

    // The translation, then how many posts carry the tag.
    String? detailOf(TagSuggestion tag) {
      final posts = int.tryParse(tag.count ?? '');
      final parts = [
        ?translation(tag),
        if (posts != null) formatCompactCount(posts),
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }

    final inline = !FrostShell.titleContentInCaptionOf(context);
    return AppPage(
      header: FrostPageHeader(
        title: FrostText(t.navigation.tags),
        // As on Browse: the source leads the header, and the search follows it
        // where the title bar has no room for it.
        leading: [
          FrostTitleMenu(
            title: source?.displayName ?? state.sourceId,
            entries: [
              for (final item in sources)
                FrostMenuAction(
                  item.displayName,
                  checked: item.sourceId == state.sourceId,
                  onSelected: () => ref
                      .read(booruSessionProvider.notifier)
                      .selectSource(item.sourceId),
                ),
            ],
          ),
        ],
        middle: inline
            ? InlineSearch(
                sourceId: state.sourceId,
                acceptsRequests: true,
                controller: _search,
              )
            : null,
        searchController: _search,
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.invalidQuery || state.invalidSource)
                Padding(
                  padding: const EdgeInsets.only(bottom: FrostGap.group),
                  child: FrostInlineBanner(
                    tone: FrostBannerTone.caution,
                    message: t.booruError.invalidRequest,
                  ),
                ),
              FrostPresence(
                visible: state.initialization.hasError,
                effect: FrostPresenceEffect.expand,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: FrostGap.group),
                  child: FrostInlineBanner(
                    tone: FrostBannerTone.negative,
                    message: describeBooruError(state.initialization.error),
                    actionLabel: t.generic.retry,
                    onAction: () => ref.invalidate(searchProvider(session)),
                  ),
                ),
              ),
              FrostSectionHeader(
                title: t.discovery.myTags,
                actionLabel: t.discovery.manageTagsAction,
                onAction: () =>
                    context.pushUserTags<void>(sourceId: state.sourceId),
              ),
              const SizedBox(height: FrostGap.related),
              if (aliases.isEmpty)
                // The way to add one sits beside the note, not across the page.
                Row(
                  children: [
                    Flexible(
                      child: FrostText(
                        t.discovery.noCustomTags,
                        role: FrostTextRole.callout,
                        tone: FrostTextTone.secondary,
                      ),
                    ),
                    const SizedBox(width: FrostGap.related),
                    FrostTag(
                      label: t.discovery.addTag,
                      icon: appIcons.add,
                      onPressed: () => _add(state.sourceId),
                    ),
                  ],
                )
              else
                FrostWrap(
                  children: [
                    for (final alias in aliases)
                      _tag(
                        alias.value,
                        sourceId: state.sourceId,
                        label: alias.displayName ?? alias.value,
                        detail: alias.displayName == null ? null : alias.value,
                      ),
                    FrostTag(
                      label: t.discovery.addTagAction,
                      icon: appIcons.add,
                      onPressed: () => _add(state.sourceId),
                    ),
                  ],
                ),
              const SizedBox(height: FrostGap.section),
              const FrostDivider(),
              const SizedBox(height: FrostGap.group),
              FrostSectionHeader(
                title: t.discovery.commonTags,
                actionLabel: commonUnsupported
                    ? null
                    : t.discovery.allTagsAction,
                onAction: commonUnsupported || !state.ready
                    ? null
                    : () => context.pushCommonTags<void>(
                        sourceId: state.sourceId,
                      ),
              ),
              const SizedBox(height: FrostGap.related),
              if (commonUnsupported)
                FrostEmptyState(
                  icon: const FrostIconData.glyph(BooruFlowIcons.tags),
                  title: t.discovery.noCommonTags,
                )
              else ...[
                if (state.common.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FrostGap.group),
                    child: FrostInlineBanner(
                      tone: FrostBannerTone.caution,
                      message: describeBooruError(
                        state.common.error,
                        includeDiagnostics: false,
                      ),
                      actionLabel: t.generic.retry,
                      onAction: () => logic.loadCommon(refresh: true),
                    ),
                  ),
                if (state.common.isLoading && common.isEmpty)
                  const AppLoadingContent.tags(
                    labels: ['landscape', 'scenery', 'blue_sky'],
                    dataColor: 0,
                  ),
                for (final category in _categories)
                  if (common.any((tag) => tag.category == category)) ...[
                    FrostText(
                      categoryLabel(category),
                      role: FrostTextRole.footnote,
                      tone: FrostTextTone.tertiary,
                    ),
                    const SizedBox(height: FrostGap.inline),
                    FrostWrap(
                      children: [
                        for (final tag in common.where(
                          (tag) => tag.category == category,
                        ))
                          _tag(
                            tag.value,
                            sourceId: state.sourceId,
                            label: tag.value,
                            detail: detailOf(tag),
                            dataColor: tag.category.colorIndex,
                          ),
                      ],
                    ),
                    const SizedBox(height: FrostGap.group),
                  ],
              ],
              const SizedBox(height: FrostGap.section),
            ],
          ),
        ),
      ],
    );
  }
}
