import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/locale_preferences.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

enum SettingsSection {
  sources('sources'),
  network('network'),
  general('general'),
  downloads('downloads');

  const SettingsSection(this.pathSegment);

  final String pathSegment;

  String get title => switch (this) {
    SettingsSection.sources => t.settings.sections.sourcesAndAccounts,
    SettingsSection.network => t.settings.sections.network,
    SettingsSection.general => t.settings.sections.general,
    SettingsSection.downloads => t.settings.sections.downloads,
  };

  static SettingsSection? fromPath(String? value) {
    for (final section in values) {
      if (section.pathSegment == value) return section;
    }
    return null;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.section});

  final SettingsSection? section;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _proxy = TextEditingController();
  bool _networkBusy = false;
  Future<RouteCacheStateDto>? _routes;

  BooruService get service => BooruService.instance;
  late String _accountSource;
  final _visitedSources = <String>{};

  @override
  void initState() {
    super.initState();
    _proxy.text = SettingsService.proxyUrl ?? '';
    _accountSource = service.selectedSource.value;
    _visitedSources.add(_accountSource);
    if (widget.section == SettingsSection.network) {
      _routes = service.engine.routeCacheState();
    }
  }

  @override
  void dispose() {
    _proxy.dispose();
    super.dispose();
  }

  Future<void> _open(SettingsSection section) async {
    await context.pushNamed<void>(
      AppRoute.settingsSection.name,
      pathParameters: {'section': section.pathSegment},
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    if (section != null) {
      return StatefulBuilder(
        builder: (_, refresh) => AutoScaffold(
          titleWidget: Text(section.title),
          builder: (_, _) => _sectionContent(section, refresh),
        ),
      );
    }
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(t.settings.title),
      builder: (_, _) => GroupedSettingsList(
        groups: [
          [
            _DropdownTile<String>(
              icon: CupertinoIcons.square_stack_3d_up,
              title: t.settings.source.defaultSource,
              value: SettingsService.defaultSourceId,
              values: service.sources.map((item) => item.sourceId).toList(),
              label: (id) => service.sourceById(id).displayName,
              onChanged: (id) =>
                  setState(() => SettingsService.defaultSourceId = id),
            ),
            _category(
              CupertinoIcons.photo_on_rectangle,
              t.settings.sections.sourcesAndAccounts,
              t.settings.account.manageAllSubtitle,
              () => _open(SettingsSection.sources),
            ),
            _category(
              Icons.sell_outlined,
              t.discovery.manageTags,
              t.discovery.displayName,
              () => context.pushUserTags<void>(),
            ),
          ],
          [
            _category(
              CupertinoIcons.globe,
              t.settings.sections.network,
              _networkMode(SettingsService.networkFallbackMode),
              () => _open(SettingsSection.network),
            ),
            _category(
              CupertinoIcons.paintbrush,
              t.settings.sections.general,
              '${_theme(SettingsService.themeMode)} · ${_language(SettingsService.language)}',
              () => _open(SettingsSection.general),
            ),
          ],
          if (AppPlatform.isDesktop)
            [
              _category(
                CupertinoIcons.arrow_down_to_line,
                t.settings.sections.downloads,
                t.settings.downloadsOverview,
                () => _open(SettingsSection.downloads),
              ),
            ],
        ],
      ),
    );
  }

  Widget _sectionContent(SettingsSection section, StateSetter refresh) =>
      switch (section) {
        SettingsSection.sources => _sourceAccountPage(refresh),
        SettingsSection.network => _networkPage(refresh),
        SettingsSection.general => _generalPage(refresh),
        SettingsSection.downloads => _downloadsPage(refresh),
      };

  Widget _category(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    onTap: onTap,
  );

  Widget _networkPage(StateSetter refresh) => GroupedSettingsList(
    groups: [
      [
        _DropdownTile<NetworkFallbackMode>(
          icon: CupertinoIcons.antenna_radiowaves_left_right,
          title: t.settings.network.connectionMode,
          value: SettingsService.networkFallbackMode,
          values: NetworkFallbackMode.values,
          label: _networkMode,
          onChanged: (value) {
            SettingsService.networkFallbackMode = value;
            refresh(() {});
          },
        ),
        ListTile(
          leading: const Icon(CupertinoIcons.arrow_2_circlepath),
          title: Text(t.settings.network.fallbackToSystemDns),
          trailing: AppSwitch(
            value: SettingsService.fallbackToSystemDns,
            semanticLabel: t.settings.network.fallbackToSystemDns,
            onChanged: (value) {
              SettingsService.fallbackToSystemDns = value;
              refresh(() {});
            },
          ),
        ),
      ],
      [
        _TextTile(
          icon: CupertinoIcons.link,
          title: t.settings.network.proxyUrl,
          hint: t.settings.network.proxyHint,
          controller: _proxy,
        ),
        ListTile(
          leading: const Icon(CupertinoIcons.bolt),
          title: Text(t.settings.network.applyAndRouteCache),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: t.settings.network.apply,
                      kind: AppButtonKind.primary,
                      loading: _networkBusy,
                      onPressed: _networkBusy
                          ? null
                          : () => _applyNetwork(refresh),
                    ),
                    AppButton(
                      label: t.settings.network.refreshRoutes,
                      onPressed: _networkBusy
                          ? null
                          : () => _refreshRoutes(refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                FutureBuilder<RouteCacheStateDto>(
                  future: _routes,
                  builder: (_, snapshot) {
                    final state = snapshot.data;
                    return Text(
                      state == null
                          ? t.settings.network.routeCacheUnavailable
                          : t.settings.network.routeCacheStatus(
                              hosts: state.routes.length,
                              revision: state.routeRevision,
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  Future<void> _applyNetwork(StateSetter refresh) async {
    if (_networkBusy) return;
    refresh(() => _networkBusy = true);
    try {
      SettingsService.proxyUrl = _proxy.text;
      await service.reconfigureNetwork();
      _routes = service.engine.routeCacheState();
      if (mounted) AppToast.success(t.settings.network.applied);
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.network.invalidSettings, error);
      }
    } finally {
      if (mounted) refresh(() => _networkBusy = false);
    }
  }

  Future<void> _refreshRoutes(StateSetter refresh) async {
    refresh(() {
      _networkBusy = true;
      _routes = service.engine.refreshRouteCache();
    });
    try {
      await _routes;
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.network.routeRefreshFailed, error);
      }
    } finally {
      if (mounted) refresh(() => _networkBusy = false);
    }
  }

  Widget _generalPage(StateSetter refresh) => GroupedSettingsList(
    groups: [
      [
        _DropdownTile<String>(
          icon: CupertinoIcons.circle_lefthalf_fill,
          title: t.settings.theme,
          value: SettingsService.themeMode?.toString() ?? 'system',
          values: const ['system', '0', '1'],
          label: (value) => switch (value) {
            'system' => t.settings.system,
            '0' => t.settings.light,
            _ => t.settings.dark,
          },
          onChanged: (value) {
            SettingsService.themeMode = value == 'system'
                ? null
                : int.parse(value);
            notifyAppSettingsChanged();
            refresh(() {});
          },
        ),
        _DropdownTile<String>(
          icon: CupertinoIcons.globe,
          title: t.settings.language,
          value: SettingsService.language?.toString() ?? 'system',
          values: const ['system', '0', '1', '2', '3'],
          label: (value) =>
              _language(value == 'system' ? null : int.parse(value)),
          onChanged: (value) {
            final language = value == 'system' ? null : int.parse(value);
            SettingsService.language = language;
            applyLanguagePreference(language);
            notifyAppSettingsChanged();
            refresh(() {});
          },
        ),
      ],
      [
        _DropdownTile<int>(
          icon: CupertinoIcons.rectangle_grid_2x2,
          title: t.settings.columnsPerRow,
          value: SettingsService.waterfallColumns ?? 0,
          values: List.generate(13, (index) => index),
          label: (value) => value == 0 ? t.settings.auto : '$value',
          onChanged: (value) {
            SettingsService.waterfallColumns = value == 0 ? null : value;
            refresh(() {});
          },
        ),
      ],
    ],
  );

  Widget _downloadsPage(StateSetter refresh) => GroupedSettingsList(
    groups: [
      [
        ListTile(
          leading: const Icon(CupertinoIcons.folder),
          title: Text(t.settings.downloadDirectory),
          subtitle: Text(
            SettingsService.downloadPath ?? t.settings.platformDefault,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (SettingsService.downloadPath != null)
                AppIconButton(
                  tooltip: t.settings.platformDefault,
                  onPressed: () {
                    SettingsService.downloadPath = null;
                    refresh(() {});
                  },
                  icon: const Icon(CupertinoIcons.clear, size: 18),
                ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => _pickDirectory(refresh),
        ),
      ],
      [
        _numberDropdown(
          CupertinoIcons.arrow_down_circle,
          t.settings.maxConcurrentDownloads,
          SettingsService.maxConcurrentDownloads,
          (value) => SettingsService.maxConcurrentDownloads = value,
          refresh,
        ),
        _numberDropdown(
          CupertinoIcons.square_split_2x1,
          t.settings.maxSegmentsPerTask,
          SettingsService.maxSegmentsPerTask,
          (value) => SettingsService.maxSegmentsPerTask = value,
          refresh,
        ),
      ],
    ],
  );

  Widget _numberDropdown(
    IconData icon,
    String title,
    int value,
    ValueChanged<int> update,
    StateSetter refresh,
  ) => _DropdownTile<int>(
    icon: icon,
    title: title,
    value: value,
    values: List.generate(8, (index) => index + 1),
    label: (item) => '$item',
    onChanged: (item) {
      update(item);
      refresh(() {});
    },
  );

  Future<void> _pickDirectory(StateSetter refresh) async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: t.settings.downloadDirectoryDialog.pickerTitle,
      initialDirectory: SettingsService.downloadPath,
      windowsOptions: const WindowsOptions(lockParentWindow: true),
      linuxOptions: const LinuxOptions(lockParentWindow: true),
    );
    if (selected == null || !mounted) return;
    if (!path.isAbsolute(selected)) {
      AppToast.error(
        t.settings.downloadDirectoryDialog.messages.pathNotAbsolute,
      );
      return;
    }
    try {
      await ensureWritableDirectory(Directory(selected));
      SettingsService.downloadPath = selected;
      refresh(() {});
    } catch (_) {
      AppToast.error(
        t.settings.downloadDirectoryDialog.messages.pathNotWritable,
      );
    }
  }

  Widget _sourceAccountPage(StateSetter refresh) {
    final sources = service.sources;
    final activeIndex = sources.indexWhere(
      (item) => item.sourceId == _accountSource,
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SafetyRatingTile(
                    ratings: SettingsService.configurableRatings,
                    selectedRatings: SettingsService.ratings,
                    onChanged: (rating) {
                      final next = [...SettingsService.ratings];
                      next.contains(rating)
                          ? next.remove(rating)
                          : next.add(rating);
                      SettingsService.ratings = next;
                      refresh(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DefaultTabController(
                length: sources.length,
                initialIndex: activeIndex < 0 ? 0 : activeIndex,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: [
                    for (final source in sources) Tab(text: source.displayName),
                  ],
                  onTap: (index) => setState(() {
                    _accountSource = sources[index].sourceId;
                    _visitedSources.add(_accountSource);
                  }),
                ),
              ),
              const SizedBox(height: 12),
              for (final source in sources)
                if (_visitedSources.contains(source.sourceId))
                  Offstage(
                    key: ValueKey('source-settings-${source.sourceId}'),
                    offstage: source.sourceId != _accountSource,
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: ListTileTheme.merge(
                        tileColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(CupertinoIcons.shield),
                              title: Text(t.settings.source.supportedRatings),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    for (final rating
                                        in source.capabilities.ratings)
                                      Text(rating.shortLabel),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            if (source.capabilities.authKind != AuthKind.none)
                              _AccountEditor(
                                key: ValueKey(source.sourceId),
                                service: service,
                                source: source,
                              )
                            else
                              ListTile(
                                leading: const Icon(
                                  CupertinoIcons.person_crop_circle,
                                ),
                                title: Text(
                                  t.settings.account.noAccountRequired,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyRatingTile extends StatelessWidget {
  const _SafetyRatingTile({
    required this.ratings,
    required this.selectedRatings,
    required this.onChanged,
  });

  final List<ContentRating> ratings;
  final List<ContentRating> selectedRatings;
  final ValueChanged<ContentRating> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        t.settings.source.safetyRating,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final rating in ratings)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: rating == ratings.last ? 0 : 8),
                child: AppChoiceToggle(
                  label: rating.shortLabel,
                  selected: selectedRatings.contains(rating),
                  onPressed: () => onChanged(rating),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({
    required this.service,
    required this.source,
    super.key,
  });

  final BooruService service;
  final BooruSourceDto source;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  final _auth = <AuthFieldKind, TextEditingController>{};
  final _cookie = TextEditingController();
  final _userAgent = TextEditingController();
  late Future<AuthSchemaDto> _schema;
  late Future<AuthStateDto> _authState;
  bool _busy = false;

  String get sourceId => widget.source.sourceId;

  @override
  void initState() {
    super.initState();
    for (final kind in AuthFieldKind.values) {
      _auth[kind] = TextEditingController();
    }
    _loadSavedValues();
    _loadRemoteState();
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
    final saved = widget.service.savedAuth(sourceId);
    for (final kind in AuthFieldKind.values) {
      _auth[kind]!.text = saved[kind.name] ?? '';
    }
    _cookie.text = saved['cookieHeader'] ?? '';
    _userAgent.text = saved['userAgent'] ?? '';
  }

  void _loadRemoteState() {
    _schema = widget.service.authSchema(sourceId);
    _authState = widget.service.authState(sourceId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthSchemaDto>(
    future: _schema,
    builder: (context, snapshot) {
      final items = <Widget>[_header()];
      final schema = snapshot.data;
      if (schema == null) {
        items.add(
          ListTile(
            leading: snapshot.hasError
                ? const Icon(CupertinoIcons.exclamationmark_triangle)
                : const CupertinoActivityIndicator(),
            title: Text(
              snapshot.hasError ? t.generic.loadFailed : t.generic.loading,
            ),
            trailing: snapshot.hasError
                ? AppButton(
                    label: t.generic.retry,
                    onPressed: () => setState(_loadRemoteState),
                  )
                : null,
          ),
        );
      } else {
        items.addAll(_fields(schema));
        items.add(_actions(schema));
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            items[index],
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
    },
  );

  Widget _header() => ListTile(
    leading: const Icon(CupertinoIcons.person_crop_circle),
    title: Text(widget.source.displayName),
    subtitle: FutureBuilder<AuthStateDto>(
      future: _authState,
      builder: (_, snapshot) => Text(
        t.settings.account.statusValue(
          status: snapshot.data == null
              ? t.generic.loading
              : _authStatusLabel(snapshot.data!.status),
        ),
      ),
    ),
  );

  List<Widget> _fields(AuthSchemaDto schema) {
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

  Widget _actions(AuthSchemaDto schema) => ListTile(
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

  Future<void> _save(AuthSchemaDto schema) async {
    setState(() => _busy = true);
    try {
      final state = schema.usesWebSession
          ? await widget.service.saveWebSession(
              sourceId,
              cookieHeader: _cookie.text,
              userAgent: _userAgent.text,
            )
          : await widget.service.saveCredentials(
              sourceId,
              SourceCredentialsDto(
                username: _value(AuthFieldKind.username),
                userId: _value(AuthFieldKind.userId),
                apiKey: _value(AuthFieldKind.apiKey),
              ),
            );
      if (!mounted) return;
      setState(() => _authState = Future.value(state));
      widget.service.revision.value++;
      AppToast.success(t.settings.account.saved);
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.saveFailed, error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final state = await widget.service.engine.verifyAuth(sourceId: sourceId);
      if (!mounted) return;
      setState(() => _authState = Future.value(state));
      AppToast.success(t.settings.account.verified);
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(t.settings.account.verificationFailed, error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    try {
      await widget.service.clearAuth(sourceId);
      _loadSavedValues();
      final state = await widget.service.authState(sourceId);
      if (!mounted) return;
      setState(() => _authState = Future.value(state));
      widget.service.revision.value++;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _value(AuthFieldKind kind) {
    final value = _auth[kind]!.text.trim();
    return value.isEmpty ? null : value;
  }
}

class _DropdownTile<T extends Object> extends StatelessWidget {
  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: AppSelect<T>(
      label: title,
      value: value,
      items: [
        for (final item in values)
          AppSelectItem<T>(value: item, label: label(item)),
      ],
      onChanged: onChanged,
    ),
  );
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

String _networkMode(NetworkFallbackMode value) => switch (value) {
  NetworkFallbackMode.off => t.settings.network.systemDns,
  NetworkFallbackMode.persistedIpOverride => t.settings.network.sniBypass,
  NetworkFallbackMode.legacyIpUrl => t.settings.network.legacyIpUrl,
};

String _theme(int? value) => switch (value) {
  null => t.settings.system,
  0 => t.settings.light,
  _ => t.settings.dark,
};

String _language(int? value) => switch (value) {
  null => t.settings.system,
  0 => 'English',
  1 => '日本語',
  2 => '繁體中文',
  _ => '简体中文',
};

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
