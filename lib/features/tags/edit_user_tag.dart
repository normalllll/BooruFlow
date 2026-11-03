import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/search/logic.dart';
import 'package:booruflow/features/search/services/tag_suggestion_repository.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

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
