import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/tags/edit_user_tag.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The saved tag aliases, optionally only those that apply to [sourceId].
class MyTagsPage extends ConsumerStatefulWidget {
  const MyTagsPage({this.sourceId, super.key});
  final String? sourceId;

  @override
  ConsumerState<MyTagsPage> createState() => _MyTagsPageState();
}

class _MyTagsPageState extends ConsumerState<MyTagsPage> {
  late String? _source = widget.sourceId;

  void _add() => editUserTag(
    context,
    source: _source ?? UserTagAlias.allSources,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  Future<void> _remove(UserTagAlias alias) async {
    if (!await showFrostConfirm(
          context: context,
          title: t.discovery.deleteTagConfirm(
            name: alias.displayName ?? alias.value,
          ),
          confirmLabel: t.discovery.deleteTag,
        ) ||
        !mounted) {
      return;
    }
    try {
      await ref.read(userTagsProvider.notifier).delete(alias.id);
    } catch (error) {
      if (mounted) FrostToast.fromError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userTagsProvider);
    final sources = ref.watch(booruSourcesProvider);
    String sourceName(String id) =>
        sources.where((s) => s.sourceId == id).firstOrNull?.displayName ?? id;
    final aliases = [
      for (final alias in state.value ?? <UserTagAlias>[])
        if (_source == null || alias.appliesTo(_source!)) alias,
    ];
    final empty = state.hasValue && aliases.isEmpty;
    return AppPage(
      isEmpty: empty,
      empty: FrostEmptyState(
        icon: const FrostIconData.glyph(BooruFlowIcons.tags),
        title: t.discovery.noCustomTags,
        message: t.discovery.customTagsHint,
        actionLabel: t.discovery.addTag,
        onAction: _add,
      ),
      header: FrostPageHeader(
        title: FrostText(t.discovery.manageTags),
        actions: [
          FrostToolbarItem.menu(
            label: t.discovery.tagSource,
            valueLabel: _source == null
                ? t.discovery.allTagSources
                : sourceName(_source!),
            entries: [
              FrostMenuAction(
                t.discovery.allTagSources,
                checked: _source == null,
                onSelected: () => setState(() => _source = null),
              ),
              for (final source in sources)
                FrostMenuAction(
                  source.displayName,
                  checked: source.sourceId == _source,
                  onSelected: () => setState(() => _source = source.sourceId),
                ),
            ],
          ),
          FrostToolbarItem.action(
            icon: appIcons.add,
            label: t.discovery.addTagAction,
            onPressed: _add,
          ),
        ],
      ),
      slivers: [
        if (state.hasError && !state.hasValue)
          SliverFillRemaining(
            hasScrollBody: false,
            child: FrostErrorContent.fromError(
              error: state.error!,
              onRetry: () => ref.invalidate(userTagsProvider),
            ),
          )
        else if (!state.hasValue)
          SliverList.builder(
            itemCount: 6,
            itemBuilder: (_, _) => FrostListRow.skeleton(
              title: t.discovery.manageTags,
              icon: false,
              subtitle: t.discovery.allTagSources,
              value: null,
            ),
          )
        else
          SliverList.separated(
            itemCount: aliases.length,
            separatorBuilder: (_, _) =>
                const FrostDivider(inset: FrostDividerInset.keyline),
            itemBuilder: (context, index) {
              final alias = aliases[index];
              final source = alias.sourceId == UserTagAlias.allSources
                  ? t.discovery.allTagSources
                  : sourceName(alias.sourceId);
              void edit() => editUserTag(
                context,
                source: alias.sourceId,
                locale: alias.locale,
                existing: alias,
              );
              return FrostSwipeActions(
                key: ValueKey('custom-tag-${alias.id}'),
                trailing: [
                  FrostSwipeAction(
                    label: t.discovery.editTagAction,
                    icon: appIcons.edit,
                    onPressed: edit,
                  ),
                  FrostSwipeAction(
                    label: t.discovery.deleteTag,
                    icon: appIcons.delete,
                    tone: FrostSwipeTone.destructive,
                    onPressed: () => _remove(alias),
                  ),
                ],
                child: FrostListRow(
                  title: alias.displayName ?? alias.value,
                  subtitle: FrostRowSubtitle(
                    alias.displayName == null
                        ? source
                        : '${alias.value} · $source',
                  ),
                  onPressed: () => context.pushTaggedPosts(
                    [alias.value],
                    sourceId: alias.sourceId == UserTagAlias.allSources
                        ? ref.read(booruSessionProvider).sourceId
                        : alias.sourceId,
                  ),
                  contextMenu: [
                    FrostMenuAction(
                      t.discovery.editTag,
                      leading: FrostGlyph.icon(appIcons.edit),
                      onSelected: edit,
                    ),
                    FrostMenuAction(
                      t.discovery.deleteTag,
                      leading: FrostGlyph.icon(appIcons.delete),
                      destructive: true,
                      onSelected: () => _remove(alias),
                    ),
                  ],
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: FrostGap.section)),
      ],
    );
  }
}
