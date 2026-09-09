import 'dart:math' as math;

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart'
    show AutoScaffold, shouldUseDesktopShell;
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/shared/widgets/rounded_surface.dart';
import 'package:booruflow/shared/widgets/tag_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserTagsPage extends ConsumerStatefulWidget {
  const UserTagsPage({super.key, this.sourceId});
  final String? sourceId;
  @override
  ConsumerState<UserTagsPage> createState() => _UserTagsPageState();
}

class _UserTagsPageState extends ConsumerState<UserTagsPage> {
  void _add() => editUserTag(
    context,
    source: widget.sourceId ?? UserTagAlias.allSources,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userTagsProvider);
    final sources = ref.watch(booruSourcesProvider);
    return AutoScaffold(
      titleWidget: Text(t.discovery.manageTags),
      builder: (context, _) {
        if (state.hasError) {
          return Center(
            child: AppButton(
              label: t.generic.retry,
              onPressed: () => ref.invalidate(userTagsProvider),
            ),
          );
        }
        final aliases = state.value;
        if (aliases == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (aliases.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 48),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sell_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.discovery.noCustomTags,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.discovery.customTagsHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: t.discovery.addTag,
                        icon: Icons.add,
                        kind: AppButtonKind.primary,
                        onPressed: _add,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          children: [
            if (shouldUseDesktopShell(context))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppIconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                    ),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ...aliases.map(
              (alias) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppRoundedSurface(
                  key: ValueKey('custom-tag-${alias.id}'),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderColor: Theme.of(context).colorScheme.outlineVariant,
                  child: InkWell(
                    onTap: () => editUserTag(
                      context,
                      source: alias.sourceId,
                      locale: alias.locale,
                      existing: alias,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TagLabel(
                                  value: alias.value,
                                  translation: alias.displayName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  alias.sourceId == UserTagAlias.allSources
                                      ? t.discovery.allTagSources
                                      : sources
                                                .where(
                                                  (source) =>
                                                      source.sourceId ==
                                                      alias.sourceId,
                                                )
                                                .firstOrNull
                                                ?.displayName ??
                                            alias.sourceId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppIconButton(
                            tooltip: t.generic.clear,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(userTagsProvider.notifier)
                                .delete(alias.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (aliases.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: t.discovery.addTag,
                  icon: Icons.add,
                  onPressed: _add,
                ),
              ),
          ],
        );
      },
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
  final controller = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(userTagsProvider.notifier);
  final raw = TextEditingController(text: existing?.value ?? value);
  final display = TextEditingController(text: existing?.displayName ?? '');
  String? error;
  final result = await showDialog<UserTagAlias>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) {
        Future<void> submit() async {
          if (raw.text.trim().isEmpty ||
              raw.text.trim().contains(RegExp(r'\s'))) {
            update(() => error = t.discovery.invalidTag);
            return;
          }
          final alias = UserTagAlias(
            id:
                existing?.id ??
                DateTime.now().microsecondsSinceEpoch.toString(),
            value: raw.text.trim(),
            sourceId: source,
            locale: switch (existing) {
              null => locale,
              _ => existing.locale,
            },
            displayName: display.text.trim().isEmpty
                ? null
                : display.text.trim(),
          );
          try {
            await controller.save(alias);
            if (context.mounted) Navigator.pop(context, alias);
          } catch (_) {
            if (context.mounted) update(() => error = t.generic.loadFailed);
          }
        }

        return AlertDialog(
          title: Text(switch (existing) {
            null => t.discovery.addCustomTag,
            _ => t.discovery.editTag,
          }),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (source == UserTagAlias.allSources) ...[
                    Text(
                      t.discovery.tagSource,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      t.discovery.allTagSources,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppTextField(
                    controller: raw,
                    label: t.discovery.canonicalTag,
                    errorText: error,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: display,
                    label: t.discovery.displayName,
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            AppButton(
              label: t.generic.cancel,
              kind: AppButtonKind.ghost,
              onPressed: () => Navigator.pop(context),
            ),
            AppButton(label: t.generic.confirm, onPressed: submit),
          ],
        );
      },
    ),
  );
  // Dialog reverse transition may still own the fields for one frame.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  raw.dispose();
  display.dispose();
  return result;
}
