import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'proxy_settings_state.dart';
import 'proxy_connection.dart';
export 'proxy_connection.dart' show proxyEndpoint, probeProxyConnectivity;
import 'package:flutter/material.dart';

import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';

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
  final Future<bool> Function(String) probe;
  final bool enabled;
  @override
  ConsumerState<ProxySettingsPanel> createState() => _ProxySettingsPanelState();
}

class _ProxySettingsPanelState extends ConsumerState<ProxySettingsPanel> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  ProxySettingsState get _form => ref.read(proxySettingsProvider);
  ProxySettingsController get _controller =>
      ref.read(proxySettingsProvider.notifier);
  String get _protocol => _form.protocol;
  bool get _busy => _form.busy;
  bool get _probing => _form.probing;
  bool get _invalid => _form.invalid;
  bool get _dirty => _form.dirty;
  bool? get _reachable => _form.reachable;
  String? get _draft => _form.endpoint;
  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: _form.host);
    _port = TextEditingController(text: _form.port);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _draft != null) unawaited(_probe());
    });
  }

  void _edited() => _controller.edit(host: _host.text, port: _port.text);
  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _apply({bool disable = false}) async {
    if (!widget.enabled) return;
    await _controller.apply(widget.onApply, widget.probe, disable: disable);
  }

  Future<void> _probe() => _controller.probe(widget.probe);
  @override
  Widget build(BuildContext context) {
    ref.watch(proxySettingsProvider);
    final n = t.settings.network;
    final controlsEnabled = widget.enabled && !_busy;
    final active = widget.appliedUrl != null;
    final changed = _dirty && _draft != widget.appliedUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.public_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  n.proxyCompact,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Switch.adaptive(
                key: const ValueKey('proxy-switch'),
                value: active,
                onChanged: controlsEnabled
                    ? (value) => _apply(disable: !value)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final protocol = Tooltip(
                message: n.proxyProtocol,
                child: IgnorePointer(
                  ignoring: !controlsEnabled,
                  child: AppSelect<String>(
                    key: const ValueKey('proxy-protocol'),
                    value: _protocol,
                    items: const [
                      AppSelectItem(value: 'http', label: 'HTTP'),
                      AppSelectItem(value: 'https', label: 'HTTPS'),
                      AppSelectItem(value: 'socks5', label: 'SOCKS5'),
                      AppSelectItem(value: 'socks5h', label: 'SOCKS5h'),
                    ],
                    onChanged: (value) {
                      _controller.edit(protocol: value);
                      _edited();
                    },
                  ),
                ),
              );
              final host = Semantics(
                label: n.proxyHost,
                child: AppTextField(
                  key: const ValueKey('proxy-host'),
                  height: appFieldHeight(context),
                  controller: _host,
                  hintText: '127.0.0.1',
                  enabled: controlsEnabled,
                  onChanged: (_) => _edited(),
                  onSubmitted: (_) {
                    if (active) _apply();
                  },
                ),
              );
              final port = Semantics(
                label: n.proxyPort,
                child: AppTextField(
                  key: const ValueKey('proxy-port'),
                  height: appFieldHeight(context),
                  controller: _port,
                  hintText: '7890',
                  keyboardType: TextInputType.number,
                  enabled: controlsEnabled,
                  onChanged: (_) => _edited(),
                  onSubmitted: (_) {
                    if (active) _apply();
                  },
                ),
              );
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
              if (largeText && constraints.maxWidth < 440) {
                return Column(
                  children: [
                    host,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: protocol),
                        const SizedBox(width: 8),
                        Expanded(child: port),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 100, child: protocol),
                  const SizedBox(width: 6),
                  Expanded(child: host),
                  const SizedBox(width: 6),
                  SizedBox(width: 64, child: port),
                ],
              );
            },
          ),
          if (_invalid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                n.proxyInvalid,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _probing
                          ? Colors.blue
                          : _reachable == null
                          ? Theme.of(context).colorScheme.outline
                          : _reachable!
                          ? Colors.greenAccent.shade400
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _probing
                            ? n.checkingCompact
                            : _reachable == null
                            ? n.uncheckedCompact
                            : _reachable!
                            ? n.proxyReachable
                            : n.proxyUnreachable,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (changed && active)
                IconButton(
                  key: const ValueKey('proxy-save'),
                  tooltip: n.saveCompact,
                  onPressed: controlsEnabled ? _apply : null,
                  icon: const Icon(Icons.check_rounded, size: 20),
                ),
              AppButton(
                label: n.checkCompact,
                tooltip: n.proxyProbe,
                kind: AppButtonKind.ghost,
                compact: true,
                icon: Icons.network_check,
                loading: _probing,
                onPressed: !_probing && !_busy ? _probe : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
