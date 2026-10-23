import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/widgets/web_challenge_data_panel.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/settings/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_action_group.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

String authStatusLabel(AuthStatus status) => switch (status) {
  AuthStatus.notConfigured => t.settings.account.statuses.notConfigured,
  AuthStatus.configuredUnverified =>
    t.settings.account.statuses.configuredUnverified,
  AuthStatus.verified => t.settings.account.statuses.verified,
  AuthStatus.rejected => t.settings.account.statuses.rejected,
};
FrostStatusTone authStatusTone(AuthStatus status) => switch (status) {
  AuthStatus.verified => FrostStatusTone.positive,
  AuthStatus.rejected => FrostStatusTone.negative,
  AuthStatus.configuredUnverified => FrostStatusTone.caution,
  AuthStatus.notConfigured => FrostStatusTone.neutral,
};

class AccountEditor extends ConsumerStatefulWidget {
  const AccountEditor({required this.source, super.key});
  final BooruSource source;
  @override
  ConsumerState<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<AccountEditor> {
  bool _verifying = false;
  String get sourceId => widget.source.sourceId;
  Future<bool> _verify() async {
    setState(() => _verifying = true);
    try {
      final verified = await ref
          .read(accountProvider(sourceId).notifier)
          .verify();
      if (mounted && verified) AppToast.success(t.settings.account.verified);
      return verified;
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.verificationFailed, error);
      }
      return false;
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<bool> _clear() async {
    if (!await showFrostConfirm(
          context: context,
          title: t.verificationPage.signOut(source: widget.source.displayName),
          message: t.verificationPage.signOutHelp,
          confirmLabel: t.settings.account.signOut,
        ) ||
        !mounted) {
      return false;
    }
    try {
      return await ref.read(accountProvider(sourceId).notifier).clear();
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.saveFailed, error);
      }
      return false;
    }
  }

  Future<void> _edit(AuthSchema schema) async {
    final key = GlobalKey<_AccountCredentialsFormState>();
    final summary = FrostFormDialogController();
    try {
      await showFrostFormDialog(
        context: context,
        title: t.settingsDetails.editSourceAccount(
          source: widget.source.displayName,
        ),
        showsCloseButton: true,
        controller: summary,
        submitLabel: t.settings.account.save,
        sections: [
          _AccountCredentialsForm(
            key: key,
            sourceId: sourceId,
            schema: schema,
            summary: summary,
          ),
        ],
        onSubmit: () => key.currentState?.submit() ?? Future.value(false),
      );
    } finally {
      summary.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final snapshot = ref.watch(accountProvider(sourceId));
    final data = snapshot.value;
    if (data == null) {
      return snapshot.hasError
          ? FrostErrorContent(
              message: describeBooruError(snapshot.error),
              onRetry: () => ref.invalidate(accountProvider(sourceId)),
            )
          : Column(
              children: [
                FrostListRow.skeleton(
                  title: widget.source.displayName,
                  icon: true,
                  subtitle: t.generic.loading,
                  value: null,
                ),
              ],
            ).frostSkeleton(true);
    }
    final busy = data.operation.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostGroupedSection(
          header: t.settings.sections.accounts,
          children: [
            FrostListRow(
              title: t.settingsDetails.status,
              trailing: FrostStatusDot(
                label: authStatusLabel(data.auth.status),
                tone: authStatusTone(data.auth.status),
              ),
            ),
            if (data.auth.username case final username?)
              FrostListRow(title: t.settings.account.username, value: username),
            for (final field in data.schema.fields)
              if (field.kind != AuthFieldKind.username &&
                  data.credentialHints[field.kind] != null)
                FrostListRow(
                  title: _authLabel(field.kind),
                  value: data.credentialHints[field.kind],
                ),
            FrostListRow(
              title: t.settingsV2.editAccount,
              accessory: FrostRowAccessory.chevron,
              onPressed: busy ? null : () => _edit(data.schema),
            ),
          ],
        ),
        const SizedBox(height: FrostGap.related),
        AppActionGroup(
          children: [
            FrostButton(
              label: t.settings.account.verify,
              icon: appIcons.refresh,
              onPressedAsync: busy && !_verifying ? null : _verify,
            ),
            FrostButton(
              label: t.settings.account.signOut,
              role: FrostButtonRole.destructive,
              variant: FrostButtonVariant.plain,
              onPressed: busy ? null : _clear,
            ),
          ],
        ),
        const SizedBox(height: FrostGap.section),
        FrostGroupedSection(
          header: t.settingsDetails.content,
          children: [
            FrostListRow(
              title: t.settings.source.supportedRatings,
              value: widget.source.capabilities.ratings
                  .map((r) => r.displayLabel)
                  .join(t.discovery.ratingSeparator),
            ),
          ],
        ),
        const SizedBox(height: FrostGap.section),
        WebChallengeDataPanel(sources: [widget.source]),
        if (data.operation.error case final error?)
          FrostErrorDetails(details: describeBooruError(error)),
      ],
    );
  }
}

String _authLabel(AuthFieldKind kind) => switch (kind) {
  AuthFieldKind.username => t.settings.account.username,
  AuthFieldKind.userId => t.settings.account.userId,
  AuthFieldKind.apiKey => t.settings.account.apiKey,
};
String _signInUrl(String id) => switch (id) {
  'anime_pictures' => 'https://anime-pictures.net/login/view',
  _ => throw UnsupportedError('No web sign-in URL for $id'),
};

// Field controllers live until the closing route actually unmounts, rather than
// until its pop Future resolves while the reverse animation is still visible.
class _AccountCredentialsForm extends ConsumerStatefulWidget {
  const _AccountCredentialsForm({
    required this.sourceId,
    required this.schema,
    required this.summary,
    super.key,
  });
  final String sourceId;
  final AuthSchema schema;
  final FrostFormDialogController summary;
  @override
  ConsumerState<_AccountCredentialsForm> createState() =>
      _AccountCredentialsFormState();
}

class _AccountCredentialsFormState
    extends ConsumerState<_AccountCredentialsForm> {
  late final Map<AuthFieldKind, TextEditingController> _fields;
  late final TextEditingController _cookie, _userAgent;
  var _errors = <AuthFieldKind, String>{};
  bool get _open => mounted && ModalRoute.of(context)?.isCurrent != false;
  @override
  void initState() {
    super.initState();
    final saved = ref.read(booruServiceProvider).savedAuth(widget.sourceId);
    _fields = {
      for (final field in widget.schema.fields)
        field.kind: TextEditingController(text: saved[field.kind.name] ?? ''),
    };
    _cookie = TextEditingController(text: saved['cookieHeader'] ?? '');
    _userAgent = TextEditingController(text: saved['userAgent'] ?? '');
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _cookie.dispose();
    _userAgent.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    if (!_open) return false;
    final nextErrors = {
      if (!widget.schema.usesWebSession)
        for (final field in widget.schema.fields)
          if (field.required_ && _fields[field.kind]!.text.trim().isEmpty)
            field.kind: t.settings.account.required,
    };
    setState(() => _errors = nextErrors);
    if (nextErrors.isNotEmpty) return false;
    widget.summary.errorSummary = null;
    String? value(AuthFieldKind kind) {
      final text = _fields[kind]?.text.trim() ?? '';
      return text.isEmpty ? null : text;
    }

    final credentials = SourceCredentials(
      username: value(AuthFieldKind.username),
      userId: value(AuthFieldKind.userId),
      apiKey: value(AuthFieldKind.apiKey),
    );
    try {
      final accepted = await ref
          .read(accountProvider(widget.sourceId).notifier)
          .save(
            webSession: widget.schema.usesWebSession,
            cookieHeader: _cookie.text,
            userAgent: _userAgent.text,
            credentials: credentials,
          );
      if (_open && accepted) {
        AppToast.success(t.settings.account.saved);
      }
      return accepted;
    } catch (error) {
      if (_open) {
        widget.summary.errorSummary = describeBooruError(
          error,
          includeDiagnostics: false,
        );
      }
      return false;
    }
  }

  Future<void> _openSignIn() async {
    try {
      final help = widget.schema.fields
          .map((field) => field.helpUrl)
          .whereType<String>()
          .firstOrNull;
      final url =
          help ??
          (widget.schema.usesWebSession
              ? _signInUrl(widget.sourceId)
              : Uri.parse(
                  await ref
                      .read(booruServiceProvider)
                      .engine
                      .feedWebUrl(
                        request: FeedRequest(
                          sourceId: widget.sourceId,
                          kind: FeedKind.latest,
                          ratings: const [],
                          pageSize: 1,
                        ),
                      ),
                ).resolve('/session/new').toString());
      if (_open) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (error) {
      if (_open) AppToast.errorWithCause(t.generic.loadFailed, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.schema.usesWebSession) ...[
          FrostListRow(
            title: t.settings.account.openSignInPage,
            icon: appIcons.externalLink,
            accessory: FrostRowAccessory.external,
            onPressed: () => launchUrlString(
              _signInUrl(widget.sourceId),
              mode: LaunchMode.externalApplication,
            ),
          ),
          FrostTextField(
            label: t.settings.account.cookieHeader,
            help: t.settings.account.storedLocally,
            controller: _cookie,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: FrostGap.related),
          FrostTextField(
            label: t.settings.account.browserUserAgent,
            help: t.settings.account.browserUserAgentHint,
            controller: _userAgent,
          ),
        ] else
          for (final field in widget.schema.fields) ...[
            if (field.secret)
              FrostTextField.secure(
                label: _authLabel(field.kind),
                controller: _fields[field.kind],
                error: _errors[field.kind],
                help: t.settings.account.storedLocally,
              )
            else
              FrostTextField(
                label: _authLabel(field.kind),
                controller: _fields[field.kind],
                error: _errors[field.kind],
              ),
            const SizedBox(height: FrostGap.group),
          ],
        if (!widget.schema.usesWebSession)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostButton(
              label: t.settings.account.openSignInPage,
              icon: appIcons.externalLink,
              variant: FrostButtonVariant.plain,
              size: FrostControlSize.compact,
              onPressed: _openSignIn,
            ),
          ),
      ],
    );
  }
}
