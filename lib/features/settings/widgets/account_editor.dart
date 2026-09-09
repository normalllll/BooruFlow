import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/settings/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountEditor extends ConsumerStatefulWidget {
  const AccountEditor({required this.source, super.key});

  final BooruSource source;

  @override
  ConsumerState<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<AccountEditor> {
  final _auth = <AuthFieldKind, TextEditingController>{};
  final _cookie = TextEditingController();
  final _userAgent = TextEditingController();
  bool get _busy {
    final snapshot = ref.read(accountProvider(sourceId));
    return snapshot.isLoading || (snapshot.value?.operation.isLoading ?? false);
  }

  String get sourceId => widget.source.sourceId;

  @override
  void initState() {
    super.initState();
    for (final kind in AuthFieldKind.values) {
      _auth[kind] = TextEditingController();
    }
    _loadSavedValues();
  }

  @override
  void dispose() {
    for (final controller in _auth.values) {
      controller.dispose();
    }
    _cookie.dispose();
    _userAgent.dispose();
    super.dispose();
  }

  void _loadSavedValues() {
    final saved = ref.read(booruServiceProvider).savedAuth(sourceId);
    for (final kind in AuthFieldKind.values) {
      _auth[kind]!.text = saved[kind.name] ?? '';
    }
    _cookie.text = saved['cookieHeader'] ?? '';
    _userAgent.text = saved['userAgent'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(accountProvider(sourceId));
    final data = snapshot.hasValue ? snapshot.requireValue : null;
    final items = <Widget>[
      ListTile(
        leading: const Icon(CupertinoIcons.person_crop_circle),
        title: Text(widget.source.displayName),
        subtitle: Text(
          t.settings.account.statusValue(
            status: switch (data) {
              null => t.generic.loading,
              AccountData(:final auth) => _authStatusLabel(auth.status),
            },
          ),
        ),
      ),
      if (snapshot.hasError || (data?.operation.hasError ?? false))
        ListTile(
          leading: const Icon(CupertinoIcons.exclamationmark_triangle),
          title: Text(t.generic.loadFailed),
          trailing: AppButton(
            label: t.generic.retry,
            onPressed: () => ref.invalidate(accountProvider(sourceId)),
          ),
        ),
      if (data != null) ...[
        ..._fields(data.schema),
        _actions(data.schema),
      ] else if (snapshot.isLoading)
        const Center(child: CupertinoActivityIndicator()),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, item) in items.indexed) ...[
          item,
          if (index < items.length - 1)
            Divider(
              height: 9,
              thickness: 1,
              indent: 56,
              endIndent: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }

  List<Widget> _fields(AuthSchema schema) {
    if (schema.usesWebSession) {
      return [
        ListTile(
          leading: const Icon(CupertinoIcons.arrow_up_right_square),
          title: Text(t.settings.account.openSignInPage),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => launchUrlString(
            _signInUrl(sourceId),
            mode: LaunchMode.externalApplication,
          ),
        ),
        _TextTile(
          icon: CupertinoIcons.doc_on_clipboard,
          title: t.settings.account.cookieHeader,
          hint: t.settings.account.storedLocally,
          controller: _cookie,
          minLines: 2,
          maxLines: 4,
        ),
        _TextTile(
          icon: CupertinoIcons.device_desktop,
          title: t.settings.account.browserUserAgent,
          hint: t.settings.account.browserUserAgentHint,
          controller: _userAgent,
        ),
      ];
    }
    return [
      for (final field in schema.fields)
        _TextTile(
          icon: field.secret ? CupertinoIcons.lock : CupertinoIcons.person,
          title: _authLabel(field.kind),
          hint: field.required_
              ? t.settings.account.required
              : t.settings.account.optional,
          controller: _auth[field.kind]!,
          obscureText: field.secret,
          helpUrl: field.helpUrl,
        ),
    ];
  }

  Widget _actions(AuthSchema schema) => ListTile(
    leading: const Icon(CupertinoIcons.shield),
    title: Text(t.settings.account.actions),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 3),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppButton(
            label: t.settings.account.save,
            kind: AppButtonKind.primary,
            loading: _busy,
            onPressed: _busy ? null : () => _save(schema),
          ),
          AppButton(
            label: t.settings.account.verify,
            onPressed: _busy ? null : _verify,
          ),
          AppButton(
            label: t.settings.account.signOut,
            kind: AppButtonKind.danger,
            onPressed: _busy ? null : _clear,
          ),
        ],
      ),
    ),
  );

  Future<void> _save(AuthSchema schema) async {
    try {
      final saved = await ref
          .read(accountProvider(sourceId).notifier)
          .save(
            webSession: schema.usesWebSession,
            cookieHeader: _cookie.text,
            userAgent: _userAgent.text,
            credentials: SourceCredentials(
              username: _value(AuthFieldKind.username),
              userId: _value(AuthFieldKind.userId),
              apiKey: _value(AuthFieldKind.apiKey),
            ),
          );
      if (mounted && saved) AppToast.success(t.settings.account.saved);
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.saveFailed, error);
      }
    }
  }

  Future<void> _verify() async {
    try {
      final verified = await ref
          .read(accountProvider(sourceId).notifier)
          .verify();
      if (mounted && verified) AppToast.success(t.settings.account.verified);
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.verificationFailed, error);
      }
    }
  }

  Future<void> _clear() async {
    try {
      final cleared = await ref
          .read(accountProvider(sourceId).notifier)
          .clear();
      if (mounted && cleared) _loadSavedValues();
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.saveFailed, error);
      }
    }
  }

  String? _value(AuthFieldKind kind) {
    final value = _auth[kind]!.text.trim();
    return value.isEmpty ? null : value;
  }
}

class _TextTile extends StatelessWidget {
  const _TextTile({
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.helpUrl,
  });
  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final int minLines;
  final int maxLines;
  final String? helpUrl;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Row(
      children: [
        Expanded(child: Text(title)),
        if (helpUrl != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(32),
            onPressed: () => launchUrlString(helpUrl!),
            child: const Icon(CupertinoIcons.question_circle, size: 18),
          ),
      ],
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 7, bottom: 3),
      child: AppTextField(
        controller: controller,
        hintText: hint,
        obscureText: obscureText,
        minLines: minLines,
        maxLines: maxLines,
      ),
    ),
  );
}

String _authLabel(AuthFieldKind kind) => switch (kind) {
  AuthFieldKind.username => t.settings.account.username,
  AuthFieldKind.userId => t.settings.account.userId,
  AuthFieldKind.apiKey => t.settings.account.apiKey,
};

String _authStatusLabel(AuthStatus status) => switch (status) {
  AuthStatus.notConfigured => t.settings.account.statuses.notConfigured,
  AuthStatus.configuredUnverified =>
    t.settings.account.statuses.configuredUnverified,
  AuthStatus.verified => t.settings.account.statuses.verified,
  AuthStatus.rejected => t.settings.account.statuses.rejected,
};

String _signInUrl(String sourceId) => switch (sourceId) {
  'anime_pictures' => 'https://anime-pictures.net/login/view',
  _ => throw UnsupportedError('No web sign-in URL for $sourceId'),
};
