import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/features/update/logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/loading_content.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});
  Future<bool> _check(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(updateCheckProvider.notifier).check();
      if (!context.mounted) return false;
      if (result == null) {
        AppToast.show(t.update.noNewVersionFound);
      } else if (result.download == null) {
        AppToast.error(t.update.selectDownloadUrlFailed);
      } else {
        AppToast.show(t.update.newVersionFound(version: result.version));
      }
      return true;
    } catch (error) {
      if (context.mounted) {
        AppToast.errorWithCause(t.update.checkUpdateFailed, error);
      }
      return false;
    }
  }

  Widget _link(String title, String url) => FrostListRow(
    title: title,
    accessory: FrostRowAccessory.external,
    onPressed: () => launchUrlString(url, mode: LaunchMode.externalApplication),
  );
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(updateCheckProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: FrostGap.related,
            bottom: FrostGap.section,
          ),
          child: FrostFormRow(label: _appIcon(64), control: _identity()),
        ),
        if (check.result case final result?)
          FrostInlineBanner(
            tone: FrostBannerTone.info,
            message: t.settingsDetails.updateAvailable(version: result.version),
            actionLabel: result.download != null
                ? t.about.downloadUpdate
                : null,
            onAction: result.download == null
                ? null
                : () => launchUrlString(
                    result.download.toString(),
                    mode: LaunchMode.externalApplication,
                  ),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostButton(
              label: t.settingsV2.checkUpdates,
              icon: appIcons.refresh,
              onPressedAsync: () => _check(context, ref),
            ),
          ),
        const SizedBox(height: FrostGap.section),
        FrostGroupedSection(
          children: [
            _link(
              t.about.projectUrl,
              'https://github.com/normalllll/BooruFlow',
            ),
            _link(
              t.about.publishPage,
              'https://github.com/normalllll/BooruFlow/releases/latest',
            ),
            _link(
              t.settingsDetails.communityTelegram,
              'https://t.me/+ONtNV3HTQ0NhMzVh',
            ),
            _link(
              t.settingsDetails.communityDiscord,
              'https://discord.gg/jQatz6965H',
            ),
          ],
        ),
        const SizedBox(height: FrostGap.section),
        FrostLinkCard(
          title: t.about.freepivPromotionTitle,
          description: t.about.freepivPromotionSubtitle,
          url: Uri.parse('https://github.com/normalllll/freepiv'),
          image: const AssetImage('assets/images/freepiv-icon.png'),
          onPressed: () => launchUrlString(
            'https://github.com/normalllll/freepiv',
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: FrostGap.section),
        FrostGroupedSection(
          children: [
            FrostListRow(
              title: t.settingsV2.licenses,
              accessory: FrostRowAccessory.chevron,
              onPressed: () => _licenses(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _appIcon(double size) => Image.asset(
    'assets/images/app-icon.png',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
  Widget _identity() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const FrostText(AppInfo.name, role: FrostTextRole.title1),
      FrostText(
        t.settingsDetails.version(
          version: AppInfo.version,
          build: AppInfo.buildNumber,
        ),
        role: FrostTextRole.subheadline,
        tone: FrostTextTone.secondary,
        numeric: true,
      ),
    ],
  );

  Future<void> _licenses(BuildContext context) {
    final entries = LicenseRegistry.licenses.toList();
    return showFrostDialog<void>(
      context: context,
      builder: (_) => FrostDialog(
        title: t.settingsV2.licenses,
        scrollable: false,
        content: FutureBuilder<List<LicenseEntry>>(
          future: entries,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return FrostEmptyState(
                icon: appIcons.error,
                title: t.generic.loadFailed,
              );
            }
            if (!snapshot.hasData) {
              return const AppLoadingContent.rows(
                labels: ['000000000000', '000000000000000000', '0000000000'],
              );
            }
            final data = snapshot.requireData;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, index) => FrostDisclosure(
                title: data[index].packages.join(', '),
                child: FrostText(
                  data[index].paragraphs.map((p) => p.text).join('\n\n'),
                  role: FrostTextRole.footnote,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
