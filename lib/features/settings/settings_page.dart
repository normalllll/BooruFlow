import 'dart:io';
import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/app/icons.g.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/about/about_page.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/widgets/web_challenge_data_panel.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/settings/appearance_settings.dart';
import 'package:booruflow/features/settings/logic.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/network_settings_page.dart';
import 'package:booruflow/features/settings/widgets/account_editor.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

enum SettingsSection {
  appearance('appearance'),
  browsing('browsing'),
  sources('sources'),
  network('network'),
  downloads('downloads'),
  web('web'),
  general('general'),
  about('about');

  const SettingsSection(this.pathSegment);
  final String pathSegment;
  String get title => switch (this) {
    appearance => t.settingsV2.appearance,
    browsing => t.settingsV2.browsing,
    sources => t.settings.sections.sourcesAndAccounts,
    network => t.settings.sections.network,
    downloads => t.settings.sections.downloads,
    web => t.webChallenge.title,
    general => t.settings.sections.general,
    about => t.about.title,
  };
  static SettingsSection? fromPath(String? value) =>
      values.where((s) => s.pathSegment == value).firstOrNull;
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({this.section, this.sourceId, super.key});
  final SettingsSection? section;
  final String? sourceId;
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

String settingsLanguageLabel(int? value) => switch (value) {
  null => t.settings.system,
  0 => 'English',
  1 => '日本語',
  2 => '繁體中文',
  _ => '简体中文',
};

FrostIconData _sectionIcon(SettingsSection section) => switch (section) {
  SettingsSection.appearance => appIcons.eye,
  SettingsSection.browsing => appIcons.multiPage,
  SettingsSection.sources => appIcons.user,
  SettingsSection.network => const FrostIconData.glyph(BooruFlowIcons.activity),
  SettingsSection.downloads => appIcons.download,
  SettingsSection.web => appIcons.success,
  SettingsSection.general => appIcons.textFormat,
  SettingsSection.about => appIcons.info,
};

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late SettingsSection _selected = widget.section ?? SettingsSection.appearance;
  late String? _sourceId = widget.sourceId;
  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != oldWidget.section ||
        widget.sourceId != oldWidget.sourceId) {
      _selected = widget.section ?? SettingsSection.appearance;
      _sourceId = widget.sourceId;
    }
  }

  void _open(int index) => setState(() {
    _selected = SettingsSection.values[index];
    _sourceId = null;
  });

  void _navigate(int index) => context.pushNamed<void>(
    AppRoute.settingsSection.name,
    pathParameters: {'section': SettingsSection.values[index].pathSegment},
  );

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final source = ref
        .watch(booruSourcesProvider)
        .where((s) => s.sourceId == _sourceId)
        .firstOrNull;
    final title =
        source?.displayName ?? widget.section?.title ?? t.settings.title;
    final page = FrostWindowTitleContribution(
      path: widget.section == null
          ? AppRoute.settings.path
          : '/settings/${widget.section!.pathSegment}',
      page: FrostPageTitle(
        id: (SettingsPage, widget.section, widget.sourceId),
        title: title,
      ),
      child: FrostSettingsSections.builder(
        header: FrostPageHeader(
          title: FrostText(t.settings.title, role: FrostTextRole.headline),
        ),
        section: widget.section == null
            ? null
            : _SettingsScroll(
                section: widget.section!,
                source: source,
                title: title,
              ),
        labels: [for (final section in SettingsSection.values) section.title],
        icons: [
          for (final section in SettingsSection.values) _sectionIcon(section),
        ],
        selectedIndex: _selected.index,
        onSelected: _open,
        onNavigate: _navigate,
        compactNavigationBuilder: (_) =>
            _SettingsNavigation(onSelected: _navigate),
        sectionBuilder: (_, index) => _SettingsScroll(
          section: SettingsSection.values[index],
          source: index == SettingsSection.sources.index ? source : null,
          showsHeader: false,
          onSourceSelected: (source) =>
              setState(() => _sourceId = source.sourceId),
          onSourceBack: () => setState(() => _sourceId = null),
        ),
      ),
    );
    return page;
  }
}

class _SettingsNavigation extends ConsumerWidget {
  const _SettingsNavigation({required this.onSelected});
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final settings = ref.watch(settingsProvider);
    final config = ref.watch(networkConfigProvider);
    final sources = ref.watch(booruSourcesProvider);
    final update = ref.watch(updateCheckProvider).result;
    String? value(SettingsSection section) => switch (section) {
      SettingsSection.appearance => switch (settings.appearance.mode) {
        ThemeMode.light => t.settings.light,
        ThemeMode.dark => t.settings.dark,
        ThemeMode.system => t.settings.system,
      },
      SettingsSection.browsing =>
        sources
            .where((s) => s.sourceId == settings.defaultSourceId)
            .firstOrNull
            ?.displayName,
      SettingsSection.network =>
        config.proxy != null
            ? t.settings.network.proxyCompact
            : config.mode == NetworkFallbackMode.off
            ? t.settingsDetails.systemDnsShort
            : t.settings.network.sniBypass,
      SettingsSection.general => settingsLanguageLabel(settings.language),
      _ => null,
    };
    Widget row(SettingsSection section) => FrostListRow(
      title: section == SettingsSection.general
          ? t.settings.language
          : section.title,
      icon: _sectionIcon(section),
      value: value(section),
      trailing: section == SettingsSection.about && update != null
          ? const FrostCountBadge(count: 1)
          : null,
      accessory: FrostRowAccessory.chevron,
      onPressed: () => onSelected(section.index),
    );
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.symmetric(vertical: FrostGap.inline),
      child: FrostContentColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FrostGroupedSection(
              children: [
                row(SettingsSection.appearance),
                row(SettingsSection.browsing),
              ],
            ),
            const SizedBox(height: FrostGap.section),
            FrostGroupedSection(
              children: [
                for (final section in [
                  SettingsSection.sources,
                  SettingsSection.network,
                  SettingsSection.downloads,
                  SettingsSection.web,
                ])
                  row(section),
              ],
            ),
            const SizedBox(height: FrostGap.section),
            FrostGroupedSection(
              children: [
                row(SettingsSection.general),
                row(SettingsSection.about),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsScroll extends ConsumerWidget {
  const _SettingsScroll({
    required this.section,
    this.source,
    this.title,
    this.showsHeader = true,
    this.onSourceSelected,
    this.onSourceBack,
  });
  final SettingsSection section;
  final BooruSource? source;
  final String? title;
  final bool showsHeader;
  final ValueChanged<BooruSource>? onSourceSelected;
  final VoidCallback? onSourceBack;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!showsHeader) ...[
          if (source != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FrostButton(
                label: SettingsSection.sources.title,
                edgeAlignment: FrostButtonEdgeAlignment.start,
                icon: appIcons.chevronLeft,
                variant: FrostButtonVariant.plain,
                size: FrostControlSize.compact,
                onPressed: onSourceBack,
              ),
            ),
          if (section != SettingsSection.about || source != null) ...[
            FrostText(
              source?.displayName ?? section.title,
              role: FrostTextRole.title2,
            ),
            const SizedBox(height: FrostGap.rowInset),
          ],
        ],
        switch (section) {
          SettingsSection.appearance => const AppearanceSettings(),
          SettingsSection.browsing => const _BrowsingSettings(),
          SettingsSection.sources =>
            source == null
                ? _SourcesSettings(onSelected: onSourceSelected)
                : source!.capabilities.authKind == AuthKind.none
                ? FrostGroupedSection(
                    children: [
                      FrostListRow(title: t.settings.account.noAccountRequired),
                      FrostListRow(
                        title: t.settings.source.supportedRatings,
                        value: source!.capabilities.ratings
                            .map((r) => r.displayLabel)
                            .join(t.discovery.ratingSeparator),
                      ),
                    ],
                  )
                : AccountEditor(source: source!),
          SettingsSection.network => const NetworkSettingsPage(),
          SettingsSection.downloads => const _DownloadSettings(),
          SettingsSection.web => WebChallengeDataPanel(
            sources: ref.watch(booruSourcesProvider),
            savedOnly: true,
          ),
          SettingsSection.general => const _GeneralSettings(),
          SettingsSection.about => const AboutPage(),
        },
      ],
    );
    if (!showsHeader) {
      return SingleChildScrollView(
        primary: false,
        // The pane passes a keyline budget; consume it inside this viewport.
        // Preserve edge-button feedback in that margin during scrolling.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(bottom: FrostGap.section),
        child: FrostContentColumn(child: content),
      );
    }
    return FrostCollectionLayout(
      header: FrostPageHeader(
        title: FrostText(title ?? section.title, role: FrostTextRole.headline),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostGap.inline),
            child: content,
          ),
        ),
      ],
    );
  }
}

class _BrowsingSettings extends ConsumerWidget {
  const _BrowsingSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final settings = ref.watch(settingsProvider),
        update = ref.read(settingsProvider.notifier);
    final sources = ref.watch(booruSourcesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostGroupedSection(
          children: [
            FrostSettingsSelectTile<String>.values(
              title: t.settings.source.defaultSource,
              value: settings.defaultSourceId,
              values: sources.map((s) => s.sourceId).toList(),
              label: (v) =>
                  sources
                      .where((s) => s.sourceId == v)
                      .firstOrNull
                      ?.displayName ??
                  v,
              onChanged: update.setDefaultSource,
            ),
            FrostSettingsSelectTile<int>.values(
              title: t.settings.columnsPerRow,
              value: settings.waterfallColumns ?? 0,
              values: const [0, 2, 3, 4, 5, 6, 7, 8],
              label: (v) => v == 0 ? t.settings.auto : '$v',
              onChanged: (v) => update.setColumns(v == 0 ? null : v),
            ),
          ],
        ),
        const SizedBox(height: FrostGap.section),
        FrostGroupedSection(
          header: t.settings.source.safetyRating,
          footer: t.discovery.defaultRatingsHint,
          children: [
            for (final rating in SettingsService.configurableRatings)
              FrostCheckboxRow(
                title: switch (rating) {
                  ContentRating.general => t.postDetail.ratingGeneral,
                  ContentRating.sensitive => t.postDetail.ratingSensitive,
                  ContentRating.questionable => t.postDetail.ratingQuestionable,
                  ContentRating.explicit => t.postDetail.ratingExplicit,
                  ContentRating.unknown => t.postDetail.ratingUnknown,
                },
                value: settings.ratings.contains(rating),
                onChanged: (value) {
                  final next = [...settings.ratings];
                  if (value == true) {
                    if (!next.contains(rating)) next.add(rating);
                  } else {
                    next.remove(rating);
                  }
                  update.setRatings(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SourcesSettings extends ConsumerWidget {
  const _SourcesSettings({this.onSelected});
  final ValueChanged<BooruSource>? onSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    return FrostGroupedSection(
      children: [
        for (final source in ref.watch(booruSourcesProvider))
          Consumer(
            key: ValueKey(source.sourceId),
            builder: (context, ref, _) {
              final auth = source.capabilities.authKind == AuthKind.none
                  ? null
                  : ref.watch(accountProvider(source.sourceId));
              final state = auth?.value?.auth;
              final label = source.capabilities.authKind == AuthKind.none
                  ? t.settings.account.noAccountRequired
                  : auth?.hasError == true
                  ? t.generic.loadFailed
                  : state == null
                  ? t.generic.loading
                  : authStatusLabel(state.status);
              return FrostListRow(
                title: source.displayName,
                subtitle:
                    state?.status == AuthStatus.verified &&
                        state?.username?.trim().isNotEmpty == true
                    ? [label, state!.username!].join(' · ')
                    : label,
                subtitleStatus: switch (state?.status) {
                  AuthStatus.verified => FrostStatusTone.positive,
                  AuthStatus.configuredUnverified => FrostStatusTone.caution,
                  _ => null,
                },
                accessory: FrostRowAccessory.chevron,
                onPressed: () => onSelected != null
                    ? onSelected!(source)
                    : context.pushNamed<void>(
                        AppRoute.settingsSection.name,
                        pathParameters: {
                          'section': SettingsSection.sources.pathSegment,
                        },
                        queryParameters: {'source': source.sourceId},
                      ),
              );
            },
          ),
      ],
    );
  }
}

class _GeneralSettings extends ConsumerWidget {
  const _GeneralSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final settings = ref.watch(settingsProvider);
    return FrostGroupedSection(
      children: [
        FrostSettingsSelectTile<int>.values(
          title: t.settings.language,
          value: settings.language ?? -1,
          values: const [-1, 0, 1, 3, 2],
          label: (v) => settingsLanguageLabel(v < 0 ? null : v),
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setLanguage(v < 0 ? null : v),
        ),
      ],
    );
  }
}

class _DownloadSettings extends ConsumerStatefulWidget {
  const _DownloadSettings();
  @override
  ConsumerState<_DownloadSettings> createState() => _DownloadSettingsState();
}

class _DownloadSettingsState extends ConsumerState<_DownloadSettings> {
  Future<void> _choose() async {
    if (!ref.read(downloadPlatformProvider).canChooseDirectory) return;
    final settings = ref.read(settingsProvider);
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
      if (mounted) {
        ref.read(settingsProvider.notifier).setDownloadPath(selected);
      }
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(
          t.settings.downloadDirectoryDialog.messages.pathNotWritable,
          error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final settings = ref.watch(settingsProvider),
        update = ref.read(settingsProvider.notifier);
    final platform = ref.watch(downloadPlatformProvider);
    Widget stepper(String title, int value, ValueChanged<int> onChanged) =>
        FrostListRow(
          title: title,
          value: '$value',
          trailing: FrostStepper(
            value: value,
            min: 1,
            max: 8,
            semanticLabel: title,
            onChanged: (v) => onChanged(v.toInt()),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostGroupedSection(
          children: [
            if (!platform.canChooseDirectory)
              FrostListRow(
                title: platform == DownloadPlatform.android
                    ? t.ugoira.androidDestination
                    : t.ugoira.iosDestination,
                subtitle: platform == DownloadPlatform.android
                    ? DownloadPlatform.androidDirectories
                    : t.ugoira.iosFilesDestination,
              )
            else
              FrostListRow(
                title: t.settings.downloadDirectory,
                subtitleKind: settings.downloadPath == null
                    ? FrostRowSubtitleKind.text
                    : FrostRowSubtitleKind.path,
                subtitle: settings.downloadPath == null
                    ? t.settings.platformDefault
                    : settings.downloadPath!,
                onPressed: _choose,
                contextMenu: [
                  if (settings.downloadPath != null) ...[
                    FrostMenuAction(
                      t.frost.showInFolder,
                      icon: appIcons.folder,
                      onSelected: () => revealDownloadPath(
                        settings.downloadPath!,
                        directory: true,
                        revealer: ref.read(downloadPathRevealerProvider),
                      ),
                    ),
                    FrostMenuAction(
                      t.settings.platformDefault,
                      onSelected: () => update.setDownloadPath(null),
                    ),
                  ],
                ],
                trailing: FrostButton(
                  label: t.settingsDetails.change,
                  size: FrostControlSize.compact,
                  onPressed: _choose,
                ),
              ),
          ],
        ),
        const SizedBox(height: FrostGap.section),
        FrostGroupedSection(
          children: [
            FrostSettingsSelectTile<UgoiraExport>(
              title: t.ugoira.format,
              subtitle: platform == DownloadPlatform.ios
                  ? t.ugoira.iosFormatHelp
                  : null,
              value: settings.ugoiraExport,
              items: [
                FrostPickerOption(
                  value: UgoiraExport.losslessWebp,
                  label: t.ugoira.losslessWebp,
                ),
                FrostPickerOption(
                  value: UgoiraExport.originalZip,
                  label: t.ugoira.originalZip,
                ),
              ],
              onChanged: update.setUgoiraExport,
            ),
            stepper(
              t.settings.maxConcurrentDownloads,
              settings.maxConcurrentDownloads,
              update.setConcurrency,
            ),
            stepper(
              t.settings.maxSegmentsPerTask,
              settings.maxSegmentsPerTask,
              update.setSegments,
            ),
          ],
        ),
      ],
    );
  }
}
