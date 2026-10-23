import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/settings/network/widgets/network_status_panel.dart';
import 'package:booruflow/features/settings/network/widgets/proxy_settings_panel.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

class NetworkSettingsPage extends ConsumerStatefulWidget {
  const NetworkSettingsPage({super.key});
  @override
  ConsumerState<NetworkSettingsPage> createState() =>
      _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends ConsumerState<NetworkSettingsPage> {
  bool _refreshing = false;
  Future<bool> _refresh() async {
    if (ref.read(networkStatusProvider).busy ||
        ref.read(networkConfigProvider).busy) {
      return false;
    }
    setState(() => _refreshing = true);
    try {
      await ref.read(networkStatusProvider.notifier).refreshRoutes();
      return mounted && ref.read(networkStatusProvider).error == null;
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String? _cacheDescription() {
    final routes = ref.watch(networkStatusProvider).routes;
    if (routes == null) return null;
    final time = DateTime.tryParse(routes.fetchedAtIso8601 ?? '')?.toLocal();
    return [
      t.settingsDetails.hostCount(count: routes.routes.length),
      if (time != null)
        t.settingsDetails.updatedAt(
          time: DateFormat.Hm(
            LocaleSettings.currentLocale.languageCode,
          ).format(time),
        ),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostGroupedSection(
          children: [
            FrostSettingsSelectTile<NetworkFallbackMode>(
              title: n.connectionMode,
              value: config.mode,
              enabled: config.proxy == null && !busy,
              items: [
                FrostPickerOption(
                  value: NetworkFallbackMode.off,
                  label: n.systemDns,
                ),
                FrostPickerOption(
                  value: NetworkFallbackMode.persistedIpOverride,
                  label: n.sniBypass,
                ),
              ],
              onChanged: (mode) => apply(mode: mode),
            ),
            FrostSettingsSelectTile<RouteProvider>(
              title: n.dnsProvider,
              value: config.dns,
              enabled: !busy,
              items: [
                for (final value in RouteProvider.values)
                  FrostPickerOption(value: value, label: value.displayName),
              ],
              onChanged: (dns) => apply(dns: dns),
            ),
            FrostListRow(
              title: n.proxyCompact,
              value: config.proxy ?? n.proxyInactive,
              accessory: FrostRowAccessory.chevron,
              enabled: !busy,
              onPressed: () => showProxySettingsDialog(
                context: context,
                appliedUrl: config.proxy,
                probe: ref.read(proxyConnectivityProbeProvider),
                onApply: (proxy) => apply(proxy: proxy, updateProxy: true),
              ),
            ),
            FrostListRow(
              title: t.settingsDetails.routeCache,
              subtitle: _cacheDescription(),
              trailing: FrostButton(
                label: t.settingsDetails.refresh,
                icon: appIcons.refresh,
                size: FrostControlSize.compact,
                onPressedAsync: busy && !_refreshing ? null : _refresh,
              ),
            ),
          ],
        ),
        const SizedBox(height: FrostGap.section),
        const NetworkStatusPanel(),
      ],
    );
  }
}
