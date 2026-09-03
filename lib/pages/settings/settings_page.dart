import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/intl/locale_preferences.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/services/app_toast.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/services/yande_network_policy.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';
import 'package:yande_gui/widgets/grouped_settings_list/grouped_settings_list.dart';
import 'package:path/path.dart' as path;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _refreshSettings() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget buildItem({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  String themeModeToText(int? themeMode) {
    switch (themeMode) {
      case null:
        return t.settings.system;
      case 0:
        return t.settings.light;
      case 1:
        return t.settings.dark;
    }
    return 'Unknown';
  }

  String languageToText(int? language) {
    return switch (language) {
      null => t.settings.system,
      0 => 'English',
      1 => '日本語',
      2 => '繁體中文',
      3 => '简体中文',
      _ => 'Unknown',
    };
  }

  String waterfallColumns(int? columns) {
    return switch (columns) {
      null => 'Auto',
      final value => value.toString(),
    };
  }

  String maxActiveDownloadTasks(int max) {
    return max.toString();
  }

  String maxParallelSegmentsPerDownloadTask(int max) {
    return max.toString();
  }

  Widget _dialogListTileMaterial(BuildContext context, Widget child) {
    return Material(
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      child: child,
    );
  }

  void _themeModeDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(t.settings.themeModeDialog.title),
          content: _dialogListTileMaterial(
            context,
            RadioGroup<int?>(
              groupValue: SettingsService.themeMode,
              onChanged: (value) {
                SettingsService.themeMode = value;
                rootUpdateController.add(null);
                Navigator.of(context).pop();
                _refreshSettings();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int?>(
                    title: Text(t.settings.system),
                    value: null,
                  ),
                  SizedBox(height: 5),
                  RadioListTile<int?>(title: Text(t.settings.light), value: 0),
                  SizedBox(height: 5),
                  RadioListTile<int?>(title: Text(t.settings.dark), value: 1),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(t.generic.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _languageDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(t.settings.languageDialog.title),
          content: _dialogListTileMaterial(
            context,
            RadioGroup<int?>(
              groupValue: SettingsService.language,
              onChanged: (value) {
                SettingsService.language = value;
                applyLanguagePreference(value);
                rootUpdateController.add(null);
                Navigator.of(context).pop();
                _refreshSettings();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<int?>(
                    title: Text(t.settings.system),
                    value: null,
                  ),
                  SizedBox(height: 5),
                  RadioListTile<int?>(title: const Text('English'), value: 0),
                  SizedBox(height: 5),
                  RadioListTile<int?>(title: const Text('日本語'), value: 1),
                  SizedBox(height: 5),
                  RadioListTile<int?>(title: const Text('繁體中文'), value: 2),
                  SizedBox(height: 5),
                  RadioListTile<int?>(title: const Text('简体中文'), value: 3),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(t.generic.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(t.generic.confirm),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _bypassSniDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(t.settings.bypassSniDialog.title),
          content: _dialogListTileMaterial(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: SettingsService.bypassSni,
                  title: Text(t.generic.enabled),
                  onChanged: (v) async {
                    SettingsService.bypassSni = v ?? false;
                    rootUpdateController.add(null);
                    Navigator.of(context).pop();
                    _refreshSettings();
                    await applyYandeNetworkSettings(force: true);
                  },
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(t.generic.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _downloadPathDialog() {
    final textController = TextEditingController(
      text: SettingsService.downloadPath,
    );
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Select Download Path'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'Platform Default',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          FilePicker.getDirectoryPath(
                            dialogTitle: 'Select a directory',
                          ).then((value) {
                            if (value != null) {
                              textController.text = value;
                            }
                          });
                        },
                        child: const Text('Pick'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          textController.clear();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(t.generic.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(t.generic.confirm),
              onPressed: () {
                final dir = textController.text;

                if (dir.isEmpty) {
                  SettingsService.downloadPath = null;
                  AppToast.info('Download path set to platform default');
                  Navigator.of(context).pop();
                  _refreshSettings();
                  return;
                }
                if (path.isRelative(dir)) {
                  AppToast.error('Path must be absolute');
                  return;
                }

                try {
                  final mode = Directory(dir).statSync().mode;

                  final hasWritePermission = (mode & 0x80) != 0;

                  if (!hasWritePermission) {
                    AppToast.error('Path is not writable');
                    return;
                  }
                } catch (e) {
                  AppToast.error(e);
                  return;
                }

                SettingsService.downloadPath = textController.text;
                Navigator.of(context).pop();
                _refreshSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _columnsPerRowDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        double currentSliderValue = ((SettingsService.waterfallColumns ?? 0))
            .toDouble();

        if (currentSliderValue != 0) {
          currentSliderValue -= 1;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text(t.settings.columnsPerRowDialog.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: currentSliderValue,
                    min: 0,
                    max: 9,
                    divisions: 9,
                    label: switch (currentSliderValue) {
                      0 => 'Auto',
                      final value => (value.toInt() + 1).toString(),
                    },
                    onChanged: (double value) {
                      setState(() {
                        currentSliderValue = value;
                      });
                    },
                  ),
                  Text(switch (currentSliderValue) {
                    0 => 'Auto',
                    final value => (value.toInt() + 1).toString(),
                  }),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text(t.generic.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text(t.generic.confirm),
                  onPressed: () {
                    SettingsService.waterfallColumns = currentSliderValue == 0
                        ? null
                        : currentSliderValue.toInt() + 1;
                    rootUpdateController.add(null);
                    Navigator.of(context).pop();
                    _refreshSettings();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _maxConcurrentDownloadsDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        int currentSliderValue = SettingsService.maxConcurrentDownloads;

        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text(t.settings.maxConcurrentDownloadsDialog.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: currentSliderValue.toDouble(),
                    min: 1,
                    max: 4,
                    divisions: 3,
                    label: currentSliderValue.toString(),
                    onChanged: (double value) {
                      setState(() {
                        currentSliderValue = value.toInt();
                      });
                    },
                  ),
                  Text(currentSliderValue.toString()),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text(t.generic.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text(t.generic.confirm),
                  onPressed: () {
                    SettingsService.maxConcurrentDownloads = currentSliderValue
                        .toInt();
                    rootUpdateController.add(null);
                    Navigator.of(context).pop();
                    _refreshSettings();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _maxSegmentsPerTaskDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        int currentSliderValue = SettingsService.maxSegmentsPerTask;

        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text(t.settings.maxSegmentsPerTaskDialog.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: currentSliderValue.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    label: currentSliderValue.toString(),
                    onChanged: (double value) {
                      setState(() {
                        currentSliderValue = value.toInt();
                      });
                    },
                  ),
                  Text(currentSliderValue.toString()),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text(t.generic.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text(t.generic.confirm),
                  onPressed: () {
                    SettingsService.maxSegmentsPerTask = currentSliderValue
                        .toInt();
                    rootUpdateController.add(null);
                    Navigator.of(context).pop();
                    _refreshSettings();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(t.settings.title),
      builder: (context, horizontal) {
        return GroupedSettingsList(
          groups: [
            [
              buildItem(
                title: Text(t.settings.language),
                leading: const Icon(Icons.language),
                subtitle: Text(languageToText(SettingsService.language)),
                onTap: _languageDialog,
              ),
              buildItem(
                title: Text(t.settings.theme),
                leading: switch (Theme.of(context).brightness) {
                  Brightness.dark => const Icon(Icons.dark_mode_outlined),
                  Brightness.light => const Icon(Icons.light_mode_outlined),
                },
                subtitle: Text(themeModeToText(SettingsService.themeMode)),
                onTap: _themeModeDialog,
              ),
              buildItem(
                title: Text(t.settings.columnsPerRow),
                leading: const Icon(Icons.view_column_outlined),
                subtitle: Text(
                  waterfallColumns(SettingsService.waterfallColumns),
                ),
                onTap: _columnsPerRowDialog,
              ),
            ],
            [
              buildItem(
                title: Text(t.settings.bypassSni),
                leading: const Icon(Icons.network_check_outlined),
                subtitle: Text(
                  SettingsService.bypassSni
                      ? t.generic.enabled
                      : t.generic.disabled,
                ),
                onTap: _bypassSniDialog,
              ),
            ],
            [
              buildItem(
                title: Text(t.settings.maxConcurrentDownloads),
                leading: const Icon(Icons.grading_outlined),
                subtitle: Text(
                  maxActiveDownloadTasks(
                    SettingsService.maxConcurrentDownloads,
                  ),
                ),
                onTap: _maxConcurrentDownloadsDialog,
              ),
              buildItem(
                title: Text(t.settings.maxSegmentsPerTask),
                leading: const Icon(Icons.segment_outlined),
                subtitle: Text(
                  maxParallelSegmentsPerDownloadTask(
                    SettingsService.maxSegmentsPerTask,
                  ),
                ),
                onTap: _maxSegmentsPerTaskDialog,
              ),
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                buildItem(
                  title: Text(t.settings.downloadDirectory),
                  leading: const Icon(Icons.save_alt_outlined),
                  subtitle: Text(
                    SettingsService.downloadPath ?? t.settings.platformDefault,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: _downloadPathDialog,
                ),
            ],
          ],
        );
      },
    );
  }
}
