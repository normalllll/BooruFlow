import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _proxy = TextEditingController();
  final _auth = <AuthFieldKind, TextEditingController>{};
  final _cookie = TextEditingController();
  final _userAgent = TextEditingController();
  bool _networkBusy = false;
  bool _authBusy = false;
  Future<AuthSchemaDto>? _schema;
  Future<AuthStateDto>? _authState;
  Future<RouteCacheStateDto>? _routes;

  BooruService get service => BooruService.instance;
  BooruSourceDto get source => service.currentSource;

  @override
  void initState() {
    super.initState();
    _proxy.text = SettingsService.proxyUrl ?? '';
    _loadAuth();
    _routes = service.engine.routeCacheState();
  }

  @override
  void dispose() {
    _proxy.dispose();
    _cookie.dispose();
    _userAgent.dispose();
    for (final controller in _auth.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadAuth() {
    final saved = service.savedAuth(service.selectedSource.value);
    for (final kind in AuthFieldKind.values) {
      _auth.putIfAbsent(kind, TextEditingController.new).text =
          saved[kind.name] ?? '';
    }
    _cookie.text = saved['cookieHeader'] ?? '';
    _userAgent.text = saved['userAgent'] ?? '';
    _schema = service.authSchema(service.selectedSource.value);
    _authState = service.authState(service.selectedSource.value);
  }

  void _selectSource(String id, StateSetter refresh) {
    service.selectSource(id);
    _loadAuth();
    refresh(() {});
    setState(() {});
  }

  Future<void> _open(
    String title,
    Widget Function(StateSetter refresh) content,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, refresh) => AutoScaffold(
            titleWidget: Text(title),
            builder: (_, _) => content(refresh),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => AutoScaffold(
    verticalOnlyTitleWidget: Text(t.settings.title),
    builder: (_, _) => GroupedSettingsList(
      groups: [
        [
          _category(
            CupertinoIcons.photo_on_rectangle,
            'Sources & content',
            '${source.displayName} · ${_policy(SettingsService.contentPolicy)}',
            () => _open('Sources & content', _sourceContentPage),
          ),
          _category(
            CupertinoIcons.person_crop_circle,
            'Account',
            source.displayName,
            () => _open('Account', _accountPage),
          ),
        ],
        [
          _category(
            CupertinoIcons.globe,
            'Network',
            _networkMode(SettingsService.networkFallbackMode),
            () => _open('Network', _networkPage),
          ),
          _category(
            CupertinoIcons.paintbrush,
            'Appearance',
            '${_theme(SettingsService.themeMode)} · ${_language(SettingsService.language)}',
            () => _open('Appearance', _appearancePage),
          ),
        ],
        if (AppPlatform.isDesktop)
          [
            _category(
              CupertinoIcons.arrow_down_to_line,
              'Downloads',
              'Desktop only · one subfolder per source',
              () => _open('Downloads', _downloadsPage),
            ),
          ],
      ],
    ),
  );

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

  Widget _sourceContentPage(StateSetter refresh) => GroupedSettingsList(
    groups: [
      [
        _DropdownTile<String>(
          icon: CupertinoIcons.square_stack_3d_up,
          title: 'Source',
          value: service.selectedSource.value,
          values: service.sources.map((item) => item.sourceId).toList(),
          label: (id) => service.sourceById(id).displayName,
          onChanged: (id) => _selectSource(id, refresh),
        ),
      ],
      [
        _DropdownTile<ContentPolicy>(
          icon: CupertinoIcons.slider_horizontal_3,
          title: 'Content policy',
          value: SettingsService.contentPolicy,
          values: ContentPolicy.values,
          label: _policy,
          onChanged: (value) {
            SettingsService.contentPolicy = value;
            service.revision.value++;
            refresh(() {});
          },
        ),
        ListTile(
          leading: const Icon(CupertinoIcons.shield),
          title: const Text('Safety rating'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 9, bottom: 3),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final rating in source.capabilities.ratings)
                  _RatingToggle(
                    label: rating.shortLabel,
                    selected: SettingsService.ratings.contains(rating),
                    onTap: () {
                      final next = [...SettingsService.ratings];
                      next.contains(rating)
                          ? next.remove(rating)
                          : next.add(rating);
                      SettingsService.ratings = next;
                      service.revision.value++;
                      refresh(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
      [
        const ListTile(
          leading: Icon(CupertinoIcons.info_circle),
          title: Text('No hidden default'),
          subtitle: Text(
            'Leave every rating unselected to show all posts, including explicit posts.',
          ),
        ),
      ],
    ],
  );

  Widget _networkPage(StateSetter refresh) => GroupedSettingsList(
    groups: [
      [
        _DropdownTile<NetworkFallbackMode>(
          icon: CupertinoIcons.antenna_radiowaves_left_right,
          title: 'Connection mode',
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
          title: const Text('Fall back to system DNS'),
          trailing: CupertinoSwitch(
            value: SettingsService.fallbackToSystemDns,
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
          title: 'Proxy URL',
          hint: 'Optional · for example http://127.0.0.1:7890',
          controller: _proxy,
        ),
        ListTile(
          leading: const Icon(CupertinoIcons.bolt),
          title: const Text('Apply and route cache'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Button(
                      label: _networkBusy ? 'Applying…' : 'Apply network',
                      onTap: _networkBusy ? null : () => _applyNetwork(refresh),
                    ),
                    _Button(
                      label: 'Refresh routes',
                      secondary: true,
                      onTap: _networkBusy
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
                          ? 'Route cache unavailable'
                          : '${state.routes.length} hosts · revision ${state.routeRevision}',
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
      _loadAuth();
      if (mounted) AppToast.success('Network settings applied');
    } catch (error) {
      if (mounted) AppToast.errorWithCause('Invalid network settings', error);
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
      if (mounted) AppToast.errorWithCause('Route refresh failed', error);
    } finally {
      if (mounted) refresh(() => _networkBusy = false);
    }
  }

  Widget _appearancePage(StateSetter refresh) => GroupedSettingsList(
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
          label: (value) => value == 0 ? 'Auto' : '$value',
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
                IconButton(
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
      [
        const ListTile(
          leading: Icon(CupertinoIcons.folder_badge_plus),
          title: Text('Source subfolders'),
          subtitle: Text(
            'Downloads are saved in a separate folder named after each source.',
          ),
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

  Widget _accountPage(StateSetter refresh) => FutureBuilder<AuthSchemaDto>(
    future: _schema,
    builder: (_, snapshot) {
      final schema = snapshot.data;
      if (schema == null) {
        return const Center(child: CupertinoActivityIndicator());
      }
      final fields = <Widget>[];
      if (source.capabilities.authKind == AuthKind.none) {
        fields.add(
          const ListTile(
            leading: Icon(CupertinoIcons.check_mark_circled),
            title: Text('No account required'),
            subtitle: Text('This source is available anonymously.'),
          ),
        );
      } else if (schema.usesWebSession) {
        fields.addAll([
          ListTile(
            leading: const Icon(CupertinoIcons.arrow_up_right_square),
            title: const Text('Open sign-in page'),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => launchUrlString(
              'https://anime-pictures.net/login/view',
              mode: LaunchMode.externalApplication,
            ),
          ),
          _TextTile(
            icon: CupertinoIcons.doc_on_clipboard,
            title: 'Cookie header',
            hint: 'Stored locally in Hive',
            controller: _cookie,
            minLines: 2,
            maxLines: 4,
          ),
          _TextTile(
            icon: CupertinoIcons.device_desktop,
            title: 'Browser User-Agent',
            hint: 'Use the same User-Agent as the signed-in browser',
            controller: _userAgent,
          ),
        ]);
      } else {
        for (final field in schema.fields) {
          fields.add(
            _TextTile(
              icon: field.secret ? CupertinoIcons.lock : CupertinoIcons.person,
              title: _authLabel(field.kind),
              hint: field.required_ ? 'Required' : 'Optional',
              controller: _auth[field.kind]!,
              obscureText: field.secret,
              helpUrl: field.helpUrl,
            ),
          );
        }
      }
      return GroupedSettingsList(
        groups: [
          [
            _DropdownTile<String>(
              icon: CupertinoIcons.square_stack_3d_up,
              title: 'Source',
              value: service.selectedSource.value,
              values: service.sources.map((item) => item.sourceId).toList(),
              label: (id) => service.sourceById(id).displayName,
              onChanged: (id) => _selectSource(id, refresh),
            ),
          ],
          fields,
          if (source.capabilities.authKind != AuthKind.none)
            [
              ListTile(
                leading: const Icon(CupertinoIcons.shield),
                title: FutureBuilder<AuthStateDto>(
                  future: _authState,
                  builder: (_, value) =>
                      Text('Status · ${value.data?.status.name ?? 'unknown'}'),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 3),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Button(
                        label: _authBusy ? 'Saving…' : 'Save',
                        onTap: _authBusy
                            ? null
                            : () => _saveAuth(schema, refresh),
                      ),
                      _Button(
                        label: 'Verify',
                        secondary: true,
                        onTap: _authBusy ? null : () => _verifyAuth(refresh),
                      ),
                      _Button(
                        label: 'Sign out',
                        secondary: true,
                        onTap: _authBusy ? null : () => _clearAuth(refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ],
      );
    },
  );

  Future<void> _saveAuth(AuthSchemaDto schema, StateSetter refresh) async {
    refresh(() => _authBusy = true);
    try {
      final id = source.sourceId;
      if (schema.usesWebSession) {
        _authState = Future.value(
          await service.saveWebSession(
            id,
            cookieHeader: _cookie.text,
            userAgent: _userAgent.text,
          ),
        );
      } else {
        String? value(AuthFieldKind kind) {
          final text = _auth[kind]?.text.trim() ?? '';
          return text.isEmpty ? null : text;
        }

        _authState = Future.value(
          await service.saveCredentials(
            id,
            SourceCredentialsDto(
              username: value(AuthFieldKind.username),
              userId: value(AuthFieldKind.userId),
              apiKey: value(AuthFieldKind.apiKey),
            ),
          ),
        );
      }
      service.revision.value++;
      if (mounted) AppToast.success('Account saved');
    } catch (error) {
      if (mounted) AppToast.errorWithCause('Could not save account', error);
    } finally {
      if (mounted) refresh(() => _authBusy = false);
    }
  }

  Future<void> _verifyAuth(StateSetter refresh) async {
    refresh(() => _authBusy = true);
    try {
      _authState = Future.value(
        await service.engine.verifyAuth(sourceId: source.sourceId),
      );
      if (mounted) AppToast.success('Account verified');
    } catch (error) {
      if (mounted) AppToast.errorWithCause('Verification failed', error);
    } finally {
      if (mounted) refresh(() => _authBusy = false);
    }
  }

  Future<void> _clearAuth(StateSetter refresh) async {
    refresh(() => _authBusy = true);
    try {
      await service.clearAuth(source.sourceId);
      _loadAuth();
      service.revision.value++;
    } finally {
      if (mounted) refresh(() => _authBusy = false);
    }
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
    title: Text(title),
    trailing: SizedBox(
      width: MediaQuery.sizeOf(context).width < 520 ? 132 : 210,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          alignment: AlignmentDirectional.centerEnd,
          items: [
            for (final item in values)
              DropdownMenuItem(
                value: item,
                child: Text(
                  label(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(hint),
          const SizedBox(height: 7),
          CupertinoTextField(
            controller: controller,
            obscureText: obscureText,
            minLines: minLines,
            maxLines: maxLines,
            padding: const EdgeInsets.all(11),
          ),
        ],
      ),
    ),
  );
}

class _RatingToggle extends StatelessWidget {
  const _RatingToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 38,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, this.onTap, this.secondary = false});
  final String label;
  final VoidCallback? onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: secondary ? colors.surfaceContainerHighest : colors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: secondary ? colors.onSurfaceVariant : colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String _policy(ContentPolicy value) => switch (value) {
  ContentPolicy.unfiltered => 'Unfiltered',
  ContentPolicy.animeFocused => 'Anime focused',
};

String _networkMode(NetworkFallbackMode value) => switch (value) {
  NetworkFallbackMode.off => 'System DNS',
  NetworkFallbackMode.persistedIpOverride => 'SNI bypass',
  NetworkFallbackMode.legacyIpUrl => 'Legacy IP URL',
};

String _theme(int? value) => switch (value) {
  null => t.settings.system,
  0 => t.settings.light,
  _ => t.settings.dark,
};

String _language(int? value) => switch (value) {
  null => 'System',
  0 => 'English',
  1 => '日本語',
  2 => '繁體中文',
  _ => '简体中文',
};

String _authLabel(AuthFieldKind kind) => switch (kind) {
  AuthFieldKind.username => 'Username',
  AuthFieldKind.userId => 'User ID',
  AuthFieldKind.apiKey => 'API key',
};
