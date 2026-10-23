import 'dart:async';
import 'package:booruflow/features/settings/network/proxy_logic.dart';
import 'package:booruflow/features/settings/network/services/proxy_connection.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
export 'package:booruflow/features/settings/network/services/proxy_connection.dart'
    show proxyEndpoint, probeProxyConnectivity, ProxyConnectivityResult;

// A five-digit port fits without stealing the host field's flexible width.
const _proxyPortWidth = 96.0;

Future<void> showProxySettingsDialog({
  required BuildContext context,
  required String? appliedUrl,
  required Future<bool> Function(String?) onApply,
  ProxyConnectivityProbe probe = probeProxyConnectivity,
}) async {
  final key = GlobalKey<_ProxySettingsPanelState>();
  var open = true;
  var active = appliedUrl;
  try {
    await showFrostFormDialog(
      context: context,
      title: t.settings.network.proxyTitle,
      showsCloseButton: true,
      leadingAction: FrostDialogAction(
        label: t.settings.network.proxyDisable,
        role: FrostButtonRole.destructive,
        enabled: appliedUrl != null,
        onPressed: () =>
            key.currentState?._submit(disable: true) ?? Future.value(false),
      ),
      sections: [
        StatefulBuilder(
          builder: (context, update) => ProxySettingsPanel(
            key: key,
            appliedUrl: active,
            probe: probe,
            onApply: (value) async {
              final accepted = await onApply(value);
              if (accepted && open && context.mounted) {
                update(() => active = value);
              }
              return accepted;
            },
          ),
        ),
      ],
      submitLabel: t.settings.network.proxyApply,
      onSubmit: () => key.currentState?._submit() ?? Future.value(false),
    );
  } finally {
    open = false;
  }
}

class ProxySettingsPanel extends ConsumerStatefulWidget {
  const ProxySettingsPanel({
    super.key,
    required this.appliedUrl,
    required this.onApply,
    this.probe = probeProxyConnectivity,
    this.enabled = true,
  });
  final String? appliedUrl;
  final Future<bool> Function(String?) onApply;
  final ProxyConnectivityProbe probe;
  final bool enabled;
  @override
  ConsumerState<ProxySettingsPanel> createState() => _ProxySettingsPanelState();
}

class _ProxySettingsPanelState extends ConsumerState<ProxySettingsPanel> {
  late final TextEditingController _host, _port;
  bool _manualProbe = false;
  ProxySettingsState get _form => ref.read(proxySettingsProvider);
  ProxySettings get _controller => ref.read(proxySettingsProvider.notifier);
  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: _form.host);
    _port = TextEditingController(text: _form.port);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _form.endpoint != null) {
        unawaited(_controller.probe(widget.probe));
      }
    });
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _edited() => _controller.edit(host: _host.text, port: _port.text);
  Future<bool> _submit({bool disable = false}) async {
    if (!widget.enabled) return false;
    var accepted = false;
    await _controller.apply(
      (value) async {
        accepted = await widget.onApply(value);
        return accepted;
      },
      widget.probe,
      disable: disable,
    );
    return accepted;
  }

  Future<bool> _probe() async {
    setState(() => _manualProbe = true);
    try {
      await _controller.probe(widget.probe);
      return mounted && _form.reachable == true;
    } finally {
      if (mounted) setState(() => _manualProbe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final form = ref.watch(proxySettingsProvider), n = t.settings.network;
    final enabled = widget.enabled && !form.busy;
    final host = FrostTextField(
      key: const ValueKey('proxy-host'),
      label: n.proxyHost,
      controller: _host,
      enabled: enabled,
      error: form.invalid ? n.proxyInvalid : null,
      onChanged: (_) => _edited(),
    );
    final port = FrostTextField(
      key: const ValueKey('proxy-port'),
      label: n.proxyPort,
      controller: _port,
      enabled: enabled,
      keyboardType: TextInputType.number,
      onChanged: (_) => _edited(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostText(
          n.proxyProtocol,
          role: FrostTextRole.footnote,
          tone: FrostTextTone.secondary,
        ),
        const SizedBox(height: FrostGap.inline),
        FrostPicker<String>.segmented(
          key: const ValueKey('proxy-protocol'),
          label: n.proxyProtocol,
          value: form.protocol,
          options: const [
            FrostPickerOption(value: 'http', label: 'HTTP'),
            FrostPickerOption(value: 'https', label: 'HTTPS'),
            FrostPickerOption(value: 'socks5', label: 'SOCKS5'),
            FrostPickerOption(value: 'socks5h', label: 'SOCKS5h'),
          ],
          onChanged: enabled
              ? (value) => _controller.edit(protocol: value)
              : null,
        ),
        const SizedBox(height: FrostGap.group),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth < 280 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    host,
                    const SizedBox(height: FrostGap.group),
                    port,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: host),
                    const SizedBox(width: FrostGap.group),
                    SizedBox(width: _proxyPortWidth, child: port),
                  ],
                ),
        ),
        const SizedBox(height: FrostGap.group),
        Wrap(
          spacing: FrostGap.group,
          runSpacing: FrostGap.related,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FrostButton(
              label: n.checkCompact,
              tooltip: n.proxyProbe,
              size: FrostControlSize.compact,
              onPressedAsync: enabled && (!form.probing || _manualProbe)
                  ? _probe
                  : null,
            ),
            if (form.probing)
              FrostActivityIndicator(semanticLabel: n.checkingCompact)
            else
              FrostStatusDot(
                label: switch (form.reachable) {
                  null => n.uncheckedCompact,
                  true => [
                    n.proxyReachable,
                    if ((form.latencyMs ?? 0) > 0) '${form.latencyMs} ms',
                  ].join(' · '),
                  false => n.proxyUnreachable,
                },
                tone: switch (form.reachable) {
                  null => FrostStatusTone.neutral,
                  true => FrostStatusTone.positive,
                  false => FrostStatusTone.negative,
                },
              ),
          ],
        ),
        const SizedBox(height: FrostGap.group),
        FrostText(
          t.settingsDetails.proxyApplies,
          role: FrostTextRole.footnote,
          tone: FrostTextTone.secondary,
        ),
      ],
    );
  }
}
