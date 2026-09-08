import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/grouped_settings_list.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'network_settings_state.dart';
import 'network_status_panel.dart';
import 'proxy_settings_panel.dart';
import 'web_challenge_data_panel.dart';

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

    Widget select<T>({
      required String title,
      required T value,
      required List<AppSelectItem<T>> items,
      required ValueChanged<T> onChanged,
      required IconData icon,
      bool enabled = true,
    }) => ListTile(
      leading: Icon(
        icon,
        color: enabled ? null : Theme.of(context).disabledColor,
      ),
      title: ExcludeFocus(
        excluding: !enabled,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1 : 0.38,
            child: AppSelect<T>(
              label: title,
              value: value,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    return GroupedSettingsList(
      groups: [
        [
          ProxySettingsPanel(
            appliedUrl: config.proxy,
            enabled: !busy,
            onApply: (proxy) => apply(proxy: proxy, updateProxy: true),
          ),
          select<NetworkFallbackMode>(
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
              select<RouteProvider>(
                title: n.dnsProvider,
                value: config.dns,
                icon: Icons.dns_outlined,
                enabled: !busy,
                items: [
                  for (final value in RouteProvider.values)
                    AppSelectItem(
                      value: value,
                      label: value == RouteProvider.uncensoredDns
                          ? 'UncensoredDNS'
                          : 'doh.sb',
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
