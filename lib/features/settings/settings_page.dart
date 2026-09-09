import 'dart:io';

import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/network_settings_page.dart';
import 'package:booruflow/features/settings/widgets/account_editor.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/shared/widgets/settings_select_tile.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

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

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.section});

  final SettingsSection? section;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  BooruService get service => ref.read(booruServiceProvider);
  AppSettings get settings => ref.read(settingsProvider);
  Settings get settingsController => ref.read(settingsProvider.notifier);
  late String _accountSource;
  final _visitedSources = <String>{};

  @override
  void initState() {
    super.initState();

    _accountSource = ref.read(booruSessionProvider).sourceId;
    _visitedSources.add(_accountSource);
  }

  Future<void> _open(SettingsSection section) async {
    await context.pushNamed<void>(
      AppRoute.settingsSection.name,
      pathParameters: {'section': section.pathSegment},
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);
    ref.watch(booruSessionProvider);
    final section = widget.section;
    if (section != null) {
      return AutoScaffold(
        titleWidget: Text(section.title),
        builder: (_, _) => _sectionContent(section),
      );
    }
    return AutoScaffold(
      showAppBar: false,
      verticalOnlyTitleWidget: Text(t.settings.title),
      builder: (_, _) => GroupedSettingsList(
        groups: [
          [
            SettingsSelectTile<String>.values(
              icon: CupertinoIcons.square_stack_3d_up,
              title: t.settings.source.defaultSource,
              value: settings.defaultSourceId,
              values: service.sources.map((item) => item.sourceId).toList(),
              label: (id) => service.sourceById(id).displayName,
              onChanged: settingsController.setDefaultSource,
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
              _networkMode(ref.watch(networkConfigProvider).mode),
              () => _open(SettingsSection.network),
            ),
            _category(
              CupertinoIcons.paintbrush,
              t.settings.sections.general,
              '${_theme(settings.themeMode)} · ${_language(settings.language)}',
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

  Widget _sectionContent(SettingsSection section) => switch (section) {
    SettingsSection.sources => _sourceAccountPage(),
    SettingsSection.network => const NetworkSettingsPage(),
    SettingsSection.general => _generalPage(),
    SettingsSection.downloads => _downloadsPage(),
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

  Widget _generalPage() => GroupedSettingsList(
    groups: [
      [
        SettingsSelectTile<String>.values(
          icon: CupertinoIcons.circle_lefthalf_fill,
          title: t.settings.theme,
          value: settings.themeMode?.toString() ?? 'system',
          values: const ['system', '0', '1'],
          label: (value) => switch (value) {
            'system' => t.settings.system,
            '0' => t.settings.light,
            _ => t.settings.dark,
          },
          onChanged: (value) {
            settingsController.setThemeMode(
              value == 'system' ? null : int.parse(value),
            );
          },
        ),
        SettingsSelectTile<String>.values(
          icon: CupertinoIcons.globe,
          title: t.settings.language,
          value: settings.language?.toString() ?? 'system',
          values: const ['system', '0', '1', '2', '3'],
          label: (value) =>
              _language(value == 'system' ? null : int.parse(value)),
          onChanged: (value) {
            final language = value == 'system' ? null : int.parse(value);
            settingsController.setLanguage(language);
          },
        ),
      ],
      [
        SettingsSelectTile<int>.values(
          icon: CupertinoIcons.rectangle_grid_2x2,
          title: t.settings.columnsPerRow,
          value: settings.waterfallColumns ?? 0,
          values: List.generate(13, (index) => index),
          label: (value) => value == 0 ? t.settings.auto : '$value',
          onChanged: (value) {
            settingsController.setColumns(value == 0 ? null : value);
          },
        ),
      ],
    ],
  );

  Widget _downloadsPage() => GroupedSettingsList(
    groups: [
      [
        ListTile(
          leading: const Icon(CupertinoIcons.folder),
          title: Text(t.settings.downloadDirectory),
          subtitle: Text(
            settings.downloadPath ?? t.settings.platformDefault,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (settings.downloadPath != null)
                AppIconButton(
                  tooltip: t.settings.platformDefault,
                  onPressed: () {
                    settingsController.setDownloadPath(null);
                  },
                  icon: const Icon(CupertinoIcons.clear, size: 18),
                ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => _pickDirectory(),
        ),
      ],
      [
        _numberDropdown(
          CupertinoIcons.arrow_down_circle,
          t.settings.maxConcurrentDownloads,
          settings.maxConcurrentDownloads,
          settingsController.setConcurrency,
        ),
        _numberDropdown(
          CupertinoIcons.square_split_2x1,
          t.settings.maxSegmentsPerTask,
          settings.maxSegmentsPerTask,
          settingsController.setSegments,
        ),
      ],
    ],
  );

  Widget _numberDropdown(
    IconData icon,
    String title,
    int value,
    ValueChanged<int> update,
  ) => SettingsSelectTile<int>.values(
    icon: icon,
    title: title,
    value: value,
    values: List.generate(8, (index) => index + 1),
    label: (item) => '$item',
    onChanged: (item) {
      update(item);
    },
  );

  Future<void> _pickDirectory() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: t.settings.downloadDirectoryDialog.pickerTitle,
      initialDirectory: settings.downloadPath,
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
      settingsController.setDownloadPath(selected);
    } catch (_) {
      AppToast.error(
        t.settings.downloadDirectoryDialog.messages.pathNotWritable,
      );
    }
  }

  Widget _sourceAccountPage() {
    final sources = service.sources;
    final activeIndex = sources.indexWhere(
      (item) => item.sourceId == _accountSource,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0;
        final contentInset =
            (constraints.maxWidth - 760).clamp(0.0, double.infinity) / 2;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: contentInset + padding,
            vertical: padding,
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
                    selectedRatings: settings.ratings,
                    onChanged: (rating) {
                      final next = [...settings.ratings];
                      if (next.contains(rating)) {
                        next.remove(rating);
                      } else {
                        next.add(rating);
                      }
                      settingsController.setRatings(next);
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
                              AccountEditor(
                                key: ValueKey(source.sourceId),
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
        );
      },
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
