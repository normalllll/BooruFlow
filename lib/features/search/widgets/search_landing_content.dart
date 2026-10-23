import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/features/tags/tag_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// Search history and tag discovery, independent of the editing/focus lifecycle.
class SearchLandingContent extends ConsumerWidget {
  const SearchLandingContent({
    required this.state,
    required this.session,
    required this.invalidQuery,
    required this.onQuery,
    required this.onTag,
    required this.onMoreCommon,
    required this.onManageAliases,
    required this.onAddAlias,
    super.key,
  });
  final SearchState state;
  final SearchSession session;
  final bool invalidQuery;
  final ValueChanged<String> onQuery;
  final ValueChanged<TagSuggestion> onTag;
  final VoidCallback onMoreCommon, onManageAliases, onAddAlias;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logic = ref.read(searchProvider(session).notifier);
    final repository = logic.repository;
    final history = ref.watch(
      searchHistoryProvider(repository, state.sourceId),
    );
    final aliases = repository.aliases
        .where((alias) => alias.appliesTo(state.sourceId))
        .toList();
    final common = state.common.value;
    return TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (invalidQuery || state.invalidSource)
            FrostInlineBanner(
              tone: FrostBannerTone.caution,
              message: t.booruError.invalidRequest,
            ),
          FrostPresence(
            visible: state.initialization.hasError,
            effect: FrostPresenceEffect.expand,
            child: FrostInlineBanner(
              tone: FrostBannerTone.negative,
              message: describeBooruError(state.initialization.error),
              actionLabel: t.generic.retry,
              onAction: () => ref.invalidate(searchProvider(session)),
            ),
          ),
          if (history.hasError ||
              history.value == null ||
              history.value!.isNotEmpty) ...[
            FrostSectionHeader(
              title: t.discovery.recentSearches,
              actionLabel: t.discovery.clearHistory,
              onAction: history.value?.isNotEmpty == true
                  ? () => ref
                        .read(
                          searchHistoryProvider(
                            repository,
                            state.sourceId,
                          ).notifier,
                        )
                        .clearQueries()
                  : null,
            ),
            if (history.hasError)
              FrostInlineBanner(
                tone: FrostBannerTone.negative,
                message: describeBooruError(history.error),
                actionLabel: t.generic.retry,
                onAction: () => ref.invalidate(
                  searchHistoryProvider(repository, state.sourceId),
                ),
              )
            else if (history.value == null)
              AppLoadingContent.rows(
                labels: const ['000000000000', '00000000'],
                icon: appIcons.clock,
              )
            else
              for (final (index, query) in history.value!.indexed) ...[
                if (index > 0)
                  const FrostDivider(inset: FrostDividerInset.keyline),
                FrostSwipeActions(
                  key: ValueKey('history-$query'),
                  trailing: [
                    FrostSwipeAction(
                      label: t.frost.remove,
                      icon: appIcons.close,
                      tone: FrostSwipeTone.destructive,
                      onPressed: () => ref
                          .read(
                            searchHistoryProvider(
                              repository,
                              state.sourceId,
                            ).notifier,
                          )
                          .removeQuery(query),
                    ),
                  ],
                  child: FrostListRow(
                    title: query,
                    icon: appIcons.clock,
                    onPressed: () => onQuery('$query '),
                  ),
                ),
              ],
            const SizedBox(height: FrostGap.section),
          ],
          FrostSectionHeader(
            title: t.discovery.commonTags,
            actionLabel: t.discovery.moreTags,
            onAction: state.ready ? onMoreCommon : null,
          ),
          if (state.common.isLoading && common.isEmpty)
            const AppLoadingContent.tags(
              labels: ['landscape', 'scenery', 'blue_sky'],
              dataColor: 0,
            ),
          if (state.common.error != null)
            FrostInlineBanner(
              tone: FrostBannerTone.caution,
              message: describeBooruError(
                state.common.error,
                includeDiagnostics: false,
              ),
              actionLabel: t.generic.retry,
              onAction: () => logic.loadCommon(refresh: true),
            ),
          for (final category in [
            TagCategory.artist,
            TagCategory.character,
            TagCategory.copyright,
            TagCategory.general,
            TagCategory.meta,
          ])
            if (common.any((tag) => tag.category == category)) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: FrostGap.group,
                  bottom: FrostGap.inline,
                ),
                child: FrostText(
                  categoryLabel(category),
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.tertiary,
                ),
              ),
              Wrap(
                spacing: FrostGap.related,
                runSpacing: FrostGap.related,
                children: [
                  for (final tag in common.where(
                    (tag) => tag.category == category,
                  ))
                    FrostTag(
                      label: tag.value,
                      detail:
                          logic.displayName(tag.value, tag.displayName) ==
                              tag.value
                          ? null
                          : logic.displayName(tag.value, tag.displayName),
                      dataColor: tag.category.colorIndex,
                      onPressed: () => onTag(tag),
                    ),
                ],
              ),
            ],
          const SizedBox(height: FrostGap.section),
          FrostSectionHeader(
            title: t.discovery.myTags,
            actionLabel: aliases.isEmpty ? null : t.discovery.manageTagsAction,
            onAction: aliases.isEmpty ? null : onManageAliases,
          ),
          if (aliases.isEmpty)
            FrostGroupedSection(
              children: [
                FrostListRow(
                  title: t.discovery.noCustomTags,
                  subtitle: t.discovery.customTagsHint,
                  trailing: FrostButton(
                    label: t.discovery.addTag,
                    icon: appIcons.add,
                    size: FrostControlSize.compact,
                    onPressed: onAddAlias,
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: FrostGap.related,
              runSpacing: FrostGap.related,
              children: [
                for (final alias in aliases)
                  FrostTag(
                    label: alias.displayName ?? alias.value,
                    detail: alias.displayName == null ? null : alias.value,
                    onPressed: () => onTag(
                      TagSuggestion(
                        value: alias.value,
                        displayName: alias.displayName,
                        origin: SuggestionOrigin.userAlias,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: FrostGap.section),
        ],
      ),
    );
  }
}
