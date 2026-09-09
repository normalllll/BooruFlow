import 'package:booruflow/features/booru/widgets/web_challenge_data_panel.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/widgets/network_status_panel.dart';
import 'package:booruflow/features/settings/network/widgets/proxy_settings_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';
import 'package:booruflow/shared/widgets/settings_select_tile.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkSettingsPage extends ConsumerWidget {
  const NetworkSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(networkConfigProvider);
    final busy =
        config.busy || ref.watch(networkStatusProvider.select((s) => s.busy));
    final n = t.settings.network;
    Future<bool> apply({
      NetworkFallbackMode? mode,
      RouteProvider? dns,
      String? proxy,
      bool updateProxy = false,
    }) async {
      try {
        final applied = await ref
            .read(networkConfigProvider.notifier)
            .apply(
              mode: mode,
              dns: dns,
              proxy: proxy,
              updateProxy: updateProxy,
            );
        if (context.mounted && applied) AppToast.success(n.applied);
        return applied;
      } catch (error) {
        if (context.mounted) AppToast.errorWithCause(n.invalidSettings, error);
        return false;
      }
    }

    return GroupedSettingsList(
      groups: [
        [
          ProxySettingsPanel(
            appliedUrl: config.proxy,
            enabled: !busy,
            onApply: (proxy) => apply(proxy: proxy, updateProxy: true),
          ),
          SettingsSelectTile<NetworkFallbackMode>(
            title: n.connectionMode,
            value: config.mode,
            icon: Icons.cell_tower,
            enabled: config.proxy == null && !busy,
            items: [
              AppSelectItem(value: NetworkFallbackMode.off, label: n.systemDns),
              AppSelectItem(
                value: NetworkFallbackMode.persistedIpOverride,
                label: n.sniBypass,
              ),
            ],
            onChanged: (mode) => apply(mode: mode),
          ),
        ],
        [const NetworkStatusPanel()],
        [
          ExpansionTile(
            title: Text(n.advancedCompact),
            leading: const Icon(Icons.tune_rounded),
            children: [
              SettingsSelectTile<RouteProvider>(
                title: n.dnsProvider,
                value: config.dns,
                icon: Icons.dns_outlined,
                enabled: !busy,
                items: [
                  for (final value in RouteProvider.values)
                    AppSelectItem(
                      value: value,
                      label: switch (value) {
                        RouteProvider.uncensoredDns => 'UncensoredDNS',
                        _ => 'doh.sb',
                      },
                    ),
                ],
                onChanged: (dns) => apply(dns: dns),
              ),
              WebChallengeDataPanel(
                sources: ref.watch(networkProbeBackendProvider).sources,
                compact: true,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
