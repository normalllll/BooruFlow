import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/i18n.dart';
import 'package:yande_gui/services/updater_service.dart';
import 'package:yande_gui/src/rust/api/rustc.dart';
import 'package:yande_gui/widgets/auto_scaffold/auto_scaffold.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Widget buildItem({
    required String title,
    String? subtitle,
    Widget? leading,
    Function()? onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: leading,
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
    EasyLoading.showToast(i18n.update.checkUpdateStart);
    UpdaterService.checkForUpdate().then((result) {
      if (result == null) {
        EasyLoading.showToast(i18n.update.noNewVersionFound);
        return;
      }

      UpdaterService.selectDownloadUrl(result.$3).then((url) {
        if (url == null) {
          EasyLoading.showToast(i18n.update.selectDownloadUrlFailed);
          return;
        }

        launchUrlString(url, mode: LaunchMode.externalApplication);
      });
    }).catchError((e) {
      EasyLoading.showToast(i18n.update.checkUpdateFailed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      verticalOnlyTitleWidget: Text(i18n.about.title),
      builder: (context, horizontal) {
        return ListView(
          children: [
            buildItem(
              title: i18n.about.projectUrl,
              leading: const Icon(Icons.link_outlined),
              subtitle: 'https://github.com/normalllll/yande_gui',
              onTap: () {
                launchUrlString('https://github.com/normalllll/yande_gui', mode: LaunchMode.externalApplication);
              },
            ),
            buildItem(
              title: i18n.about.publishPage,
              leading: const Icon(Icons.new_releases_outlined),
              subtitle: 'https://github.com/normalllll/yande_gui/releases/latest',
              onTap: () {
                launchUrlString('https://github.com/normalllll/yande_gui/releases/latest', mode: LaunchMode.externalApplication);
              },
            ),
            buildItem(
              title: i18n.about.appVersion,
              leading: const Icon(Icons.tag_outlined),
              subtitle: '${Global.appVersion}+${Global.buildNumber}',
            ),
            buildItem(
              title: i18n.about.flutterVersion,
              leading: const Icon(Icons.verified_outlined),
              subtitle: Platform.version,
            ),
            buildItem(
              title: i18n.about.rustVersion,
              leading: const Icon(Icons.verified_outlined),
              subtitle: rustcVersion(),
            ),
            buildItem(
              title: i18n.about.discussion,
              leading: const Icon(Icons.telegram),
              subtitle: 'https://t.me/+ONtNV3HTQ0NhMzVh',
              onTap: () {
                launchUrlString('https://t.me/+ONtNV3HTQ0NhMzVh');
              },
            ),
            buildItem(
              title: i18n.about.downloadUpdate,
              leading: const Icon(Icons.save_alt_outlined),
              subtitle: i18n.about.downloadUpdateHint,
              onTap: doUpdate,
            ),
          ],
        );
      },
    );
  }
}
