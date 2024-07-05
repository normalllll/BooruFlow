import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/services/settings_service.dart';
import 'package:yande_gui/src/rust/api/file_util.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';
import 'package:path/path.dart' as path;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Widget buildItem({required Widget title, Widget? subtitle, Function()? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }

  String themeModeToText(int themeMode) {
    switch (themeMode) {
      case 0:
        return 'System';
      case 1:
        return 'Light';
      case 2:
        return 'Dark';
    }
    return 'Unknown';
  }

  void _themeModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<int>(
                title: const Text('System'),
                value: 0,
                groupValue: SettingsService.themeMode,
                onChanged: (value) {
                  SettingsService.themeMode = value!;
                  rootUpdateController.add(null);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<int>(
                title: const Text('Light'),
                value: 1,
                groupValue: SettingsService.themeMode,
                onChanged: (value) {
                  SettingsService.themeMode = value!;
                  rootUpdateController.add(null);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<int>(
                title: const Text('Dark'),
                value: 2,
                groupValue: SettingsService.themeMode,
                onChanged: (value) {
                  SettingsService.themeMode = value!;
                  rootUpdateController.add(null);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _downloadPathDialog() {
    final textController = TextEditingController(text: SettingsService.downloadPath);
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
                          FilePicker.platform.getDirectoryPath(dialogTitle: 'Select a directory').then((value) {
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
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              onPressed: () {
                final dir = textController.text;

                if (dir.isEmpty) {
                  SettingsService.downloadPath= null;
                  EasyLoading.showInfo('Download path set to platform default');
                  setState(() {});
                  Navigator.of(context).pop();
                  return;
                }
                if (path.isRelative(dir)) {
                  EasyLoading.showError('Path must be absolute');
                  return;
                }

                try {
                  final (_, writable) = getFilePermissions(path: dir);

                  if (!writable) {
                    EasyLoading.showError('Path is not writable');
                    return;
                  }
                } catch (e) {
                  EasyLoading.showError(e.toString());
                  return;
                }

                SettingsService.downloadPath = textController.text;
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      verticalOnlyTitleWidget: const Text('Settings'),
      builder: (context, horizontal) {
        return ListView(
          children: [
            buildItem(
              title: const Text('Theme'),
              subtitle: Text(themeModeToText(SettingsService.themeMode)),
              onTap: () {
                _themeModeDialog();
              },
            ),
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              buildItem(
                title: const Text('Download path'),
                subtitle: Text(SettingsService.downloadPath ?? 'Platform Default'),
                onTap: () {
                  _downloadPathDialog();
                },
              ),
          ],
        );
      },
    );
  }
}
