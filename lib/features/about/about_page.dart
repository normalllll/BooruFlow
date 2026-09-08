import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/features/update/updater_service.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';

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
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  void doUpdate() {
    AppToast.show(t.update.checkUpdateStart);
    UpdaterService.checkForUpdate()
        .then((result) {
          if (result == null) {
            AppToast.show(t.update.noNewVersionFound);
            return;
          }

          UpdaterService.selectDownloadUrl(result.$3).then((url) {
            if (url == null) {
              AppToast.error(t.update.selectDownloadUrlFailed);
              return;
            }

            launchUrlString(url, mode: LaunchMode.externalApplication);
          });
        })
        .catchError((e) {
          AppToast.error(t.update.checkUpdateFailed);
        });
  }

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      showAppBar: false,
      verticalOnlyTitleWidget: Text(t.about.title),
      builder: (context, horizontal) {
        return GroupedSettingsList(
          groups: [
            [
              buildItem(
                title: t.about.projectUrl,
                leading: const Icon(Icons.link_outlined),
                subtitle: 'https://github.com/normalllll/BooruFlow',
                onTap: () {
                  launchUrlString(
                    'https://github.com/normalllll/BooruFlow',
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              buildItem(
                title: t.about.publishPage,
                leading: const Icon(Icons.new_releases_outlined),
                subtitle:
                    'https://github.com/normalllll/BooruFlow/releases/latest',
                onTap: () {
                  launchUrlString(
                    'https://github.com/normalllll/BooruFlow/releases/latest',
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
            [
              buildItem(
                title: t.about.appVersion,
                leading: const Icon(Icons.tag_outlined),
                subtitle: '${AppInfo.version}+${AppInfo.buildNumber}',
              ),
            ],
            [
              buildItem(
                title: t.about.discussion,
                leading: const Icon(Icons.telegram),
                subtitle: 'https://t.me/+ONtNV3HTQ0NhMzVh',
                onTap: () {
                  launchUrlString('https://t.me/+ONtNV3HTQ0NhMzVh');
                },
              ),
              buildItem(
                title: t.about.discussion,
                leading: const Icon(Icons.discord),
                subtitle: 'https://discord.gg/jQatz6965H',
                onTap: () {
                  launchUrlString('https://discord.gg/jQatz6965H');
                },
              ),
            ],
            [
              buildItem(
                title: t.about.downloadUpdate,
                leading: const Icon(Icons.save_alt_outlined),
                subtitle: t.about.downloadUpdateHint,
                onTap: doUpdate,
              ),
            ],
            [
              buildItem(
                title: t.about.freepivPromotionTitle,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'assets/images/freepiv-icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                subtitle: t.about.freepivPromotionSubtitle,
                onTap: () {
                  launchUrlString(
                    'https://github.com/normalllll/freepiv',
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
