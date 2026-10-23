import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/features/search/widgets/search_tag_widgets.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

class UserTagsPage extends ConsumerWidget {
  const UserTagsPage({super.key, this.sourceId});
  final String? sourceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userTagsProvider);
    final sources = ref.watch(booruSourcesProvider);
    void add() => editUserTag(
      context,
      source: sourceId ?? UserTagAlias.allSources,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    final text = TextPainter(
      text: TextSpan(
        text: t.discovery.addTagAction,
        style: FrostTypography.of(context).style(FrostTextRole.callout),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final addWidth =
        text.width +
        FrostControlSize.compact.iconSize +
        FrostGap.related +
        2 * FrostGap.group;
    text.dispose();
    final aliases = state.value;
    return FrostWindowTitleContribution(
      path: AppRoute.userTags.path,
      page: FrostPageTitle(id: UserTagsPage, title: t.discovery.manageTags),
      child: FrostPinnedChrome(
        chrome: FrostContentColumn(
          maxWidth: double.infinity,
          child: FrostPageHeader(
            title: FrostText(
              t.discovery.manageTags,
              role: FrostTextRole.headline,
            ),
            actions: [
              FrostToolbarItem.custom(
                minWidth: addWidth,
                priority: FrostToolbarPriority.high,
                overflowEntry: FrostMenuAction(
                  t.discovery.addTagAction,
                  icon: appIcons.add,
                  onSelected: add,
                ),
                builder: (_) => FrostButton(
                  label: t.discovery.addTagAction,
                  icon: appIcons.add,
                  variant: FrostButtonVariant.prominent,
                  size: FrostControlSize.compact,
                  onPressed: add,
                ),
              ),
            ],
          ),
        ),
        body: CustomScrollView(
          key: const PageStorageKey('user-tags'),
          slivers: [
            const FrostChromeSpacer(),
            FrostSliverContentColumn(
              maxWidth: searchContentMaxWidth,
              sliver: SliverMainAxisGroup(
                slivers: [
                  if (state.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: FrostEmptyState(
                        icon: appIcons.error,
                        title: t.generic.loadFailed,
                        message: describeBooruError(state.error),
                        actionLabel: t.generic.retry,
                        onAction: () => ref.invalidate(userTagsProvider),
                      ),
                    )
                  else if (aliases == null)
                    SliverLayoutBuilder(
                      builder: (context, constraints) => SliverList.builder(
                        itemCount:
                            (constraints.viewportMainAxisExtent /
                                    FrostControlSize.regular.height(context))
                                .ceil(),
                        itemBuilder: (_, _) => FrostListRow.skeleton(
                          title: t.discovery.manageTags,
                          icon: false,
                          subtitle: t.discovery.allTagSources,
                          value: null,
                        ),
                      ),
                    )
                  else if (aliases.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: FrostEmptyState(
                        icon: appIcons.edit,
                        title: t.discovery.noCustomTags,
                        message: t.discovery.customTagsHint,
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
                            : sources
                                      .where(
                                        (s) => s.sourceId == alias.sourceId,
                                      )
                                      .firstOrNull
                                      ?.displayName ??
                                  alias.sourceId;
                        void edit() => editUserTag(
                          context,
                          source: alias.sourceId,
                          locale: alias.locale,
                          existing: alias,
                        );
                        Future<void> remove() async {
                          try {
                            await ref
                                .read(userTagsProvider.notifier)
                                .delete(alias.id);
                          } catch (error) {
                            if (context.mounted) {
                              FrostToast.fromError(context, error);
                            }
                          }
                        }

                        final actions = <FrostMenuEntry>[
                          FrostMenuAction(
                            t.discovery.editTag,
                            icon: appIcons.edit,
                            onSelected: edit,
                          ),
                          FrostMenuAction(
                            t.discovery.deleteTag,
                            icon: appIcons.delete,
                            destructive: true,
                            onSelected: remove,
                          ),
                        ];
                        return FrostListRow(
                          key: ValueKey('custom-tag-${alias.id}'),
                          title: alias.displayName ?? alias.value,
                          subtitle: alias.displayName == null
                              ? null
                              : alias.value,
                          value: source,
                          onPressed: edit,
                          contextMenu: actions,
                          accessory: FrostRowAccessory.chevron,
                        );
                      },
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: FrostGap.section),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<UserTagAlias?> editUserTag(
  BuildContext context, {
  required String source,
  required String locale,
  String value = '',
  UserTagAlias? existing,
}) async {
  final form = GlobalKey<_AliasFieldsState>();
  UserTagAlias? result;
  await showFrostFormDialog(
    context: context,
    title: existing == null ? t.discovery.addCustomTag : t.discovery.editTag,
    showsCloseButton: true,
    sections: [
      _AliasFields(
        key: form,
        source: source,
        locale: locale,
        value: value,
        existing: existing,
      ),
    ],
    submitLabel: t.settings.account.save,
    leadingAction: existing == null
        ? null
        : FrostDialogAction<bool>(
            label: t.discovery.deleteTag,
            role: FrostButtonRole.destructive,
            value: false,
            onPressed: () async => await form.currentState?.remove() ?? false,
          ),
    onSubmit: () async {
      result = await form.currentState?.save();
      return result != null;
    },
  );
  return result;
}

// Controllers belong to the mounted dialog fields, including its reverse
// transition. No arbitrary delay is needed to keep editing resources alive.
class _AliasFields extends ConsumerStatefulWidget {
  const _AliasFields({
    required this.source,
    required this.locale,
    required this.value,
    required this.existing,
    super.key,
  });
  final String source, locale, value;
  final UserTagAlias? existing;
  @override
  ConsumerState<_AliasFields> createState() => _AliasFieldsState();
}

class _AliasFieldsState extends ConsumerState<_AliasFields> {
  late final _raw = TextEditingController(
    text: widget.existing?.value ?? widget.value,
  );
  late final _display = TextEditingController(
    text: widget.existing?.displayName ?? '',
  );
  late String _source = widget.existing?.sourceId ?? widget.source;
  String? _error;
  Future<UserTagAlias?> save() async {
    if (_raw.text.trim().isEmpty || _raw.text.trim().contains(RegExp(r'\s'))) {
      setState(() => _error = t.discovery.invalidTag);
      return null;
    }
    final alias = UserTagAlias(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      value: _raw.text.trim(),
      sourceId: _source,
      locale: widget.existing?.locale ?? widget.locale,
      displayName: _display.text.trim().isEmpty ? null : _display.text.trim(),
    );
    try {
      await ref.read(userTagsProvider.notifier).save(alias);
      return mounted ? alias : null;
    } catch (error) {
      if (mounted) setState(() => _error = describeBooruError(error));
      return null;
    }
  }

  Future<bool> remove() async {
    final alias = widget.existing;
    if (alias == null) return false;
    try {
      await ref.read(userTagsProvider.notifier).delete(alias.id);
      return mounted;
    } catch (error) {
      if (mounted) setState(() => _error = describeBooruError(error));
      return false;
    }
  }

  @override
  void dispose() {
    _raw.dispose();
    _display.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(booruSourcesProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostTextField(
          controller: _raw,
          label: t.discovery.canonicalTag,
          error: _error,
          autofocus: true,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: FrostGap.group),
        FrostTextField(controller: _display, label: t.discovery.displayName),
        const SizedBox(height: FrostGap.group),
        FrostPicker<String>.menu(
          label: t.discovery.tagSource,
          value: _source,
          onChanged: (value) => setState(() => _source = value),
          options: [
            FrostPickerOption(
              value: UserTagAlias.allSources,
              label: t.discovery.allTagSources,
            ),
            for (final source in sources)
              FrostPickerOption(
                value: source.sourceId,
                label: source.displayName,
              ),
          ],
        ),
      ],
    );
  }
}
