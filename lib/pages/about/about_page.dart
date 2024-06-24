import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/services/updater_service.dart';
import 'package:yande_gui/src/rust/api/rustc.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Widget buildItem({required String title, String? subtitle, Function()? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        onTap: onTap,
      ),
    );
  }

  void doUpdate() {
    EasyLoading.showToast('Check for update...');
    UpdaterService.checkForUpdate().then((result) {
      if (result == null) {
        EasyLoading.showToast('No new version found');
        return;
      }

      UpdaterService.selectDownloadUrl(result.$3).then((url) {
        if (url == null) {
          EasyLoading.showToast('Cannot find download url.\nPlease go to the project page to manually update or ask for help in the project issue page.');
          return;
        }

        launchUrlString(url, mode: LaunchMode.externalApplication);
      });
    }).catchError((e) {
      EasyLoading.showToast('Check for update failed. Please check your Internet connection.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      verticalOnlyTitleWidget: const Text('About'),
      builder: (context, horizontal) {
        return ListView(
          children: [
            buildItem(
              title: 'Project URL',
              subtitle: 'https://github.com/normalllll/yande_gui',
              onTap: () {
                launchUrlString('https://github.com/normalllll/yande_gui', mode: LaunchMode.externalApplication);
              },
            ),
            buildItem(
              title: 'Publish page',
              subtitle: 'https://github.com/normalllll/yande_gui/releases/latest',
              onTap: () {
                launchUrlString('https://github.com/normalllll/yande_gui/releases/latest', mode: LaunchMode.externalApplication);
              },
            ),
            buildItem(title: 'App Version', subtitle: '${Global.appVersion}+${Global.buildNumber}'),
            buildItem(
              title: 'Flutter Version',
              subtitle: Platform.version,
            ),
            buildItem(
              title: 'Rust Version',
              subtitle: rustcVersion(),
            ),
            buildItem(
              title: 'Download Update',
              subtitle: 'Download the latest version for your device in your browser',
              onTap: doUpdate,
            ),
          ],
        );
      },
    );
  }
}
