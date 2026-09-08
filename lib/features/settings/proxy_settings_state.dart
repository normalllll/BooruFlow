import 'dart:async';

import 'package:booruflow/core/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'proxy_connection.dart';

class ProxySettingsState {
  const ProxySettingsState({
    this.protocol = 'http',
    this.host = '',
    this.port = '7890',
    this.userInfo = '',
    this.busy = false,
    this.probing = false,
    this.invalid = false,
    this.dirty = false,
    this.reachable,
  });
  factory ProxySettingsState.fromUrl(String? value) {
    final uri = Uri.tryParse(value ?? '');
    return ProxySettingsState(
      protocol: uri?.scheme.isNotEmpty == true ? uri!.scheme : 'http',
      host: uri?.host ?? '',
      port: uri?.hasPort == true ? '${uri!.port}' : '7890',
      userInfo: uri?.userInfo ?? '',
    );
  }
  final String protocol, host, port, userInfo;
  final bool busy, probing, invalid, dirty;
  final bool? reachable;
  String? get endpoint {
    final endpoint = proxyEndpoint(protocol, host, port);
    return switch (endpoint) {
      null => null,
      _ => Uri.parse(endpoint).replace(userInfo: userInfo).toString(),
    };
  }

  ProxySettingsState copyWith({
    String? protocol,
    String? host,
    String? port,
    bool? busy,
    bool? probing,
    bool? invalid,
    bool? dirty,
    bool? reachable,
    bool clearReachable = false,
  }) => ProxySettingsState(
    protocol: protocol ?? this.protocol,
    host: host ?? this.host,
    port: port ?? this.port,
    userInfo: userInfo,
    busy: busy ?? this.busy,
    probing: probing ?? this.probing,
    invalid: invalid ?? this.invalid,
    dirty: dirty ?? this.dirty,
    reachable: clearReachable ? null : reachable ?? this.reachable,
  );
}

final proxySettingsProvider =
    NotifierProvider<ProxySettingsController, ProxySettingsState>(
      ProxySettingsController.new,
    );

class ProxySettingsController extends Notifier<ProxySettingsState> {
  int _generation = 0;
  @override
  ProxySettingsState build() =>
      ProxySettingsState.fromUrl(SettingsService.proxyUrl);
  void edit({String? protocol, String? host, String? port}) {
    _generation++;
    state = state.copyWith(
      protocol: protocol,
      host: host,
      port: port,
      dirty: true,
      invalid: false,
      probing: false,
      clearReachable: true,
    );
  }

  Future<void> apply(
    Future<bool> Function(String?) apply,
    Future<bool> Function(String) check, {
    bool disable = false,
  }) async {
    if (state.busy) return;
    final value = disable ? null : state.endpoint;
    if (!disable && value == null) {
      state = state.copyWith(invalid: true);
      return;
    }
    state = state.copyWith(busy: true, invalid: false);
    try {
      if (await apply(value) && ref.mounted) {
        state = state.copyWith(dirty: false);
        if (!disable) unawaited(probe(check, restart: true));
      }
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  Future<void> probe(
    Future<bool> Function(String) check, {
    bool restart = false,
  }) async {
    if (state.probing && !restart) return;
    final endpoint = state.endpoint;
    if (endpoint == null) {
      state = state.copyWith(invalid: true);
      return;
    }
    final generation = ++_generation;
    state = state.copyWith(probing: true, clearReachable: true, invalid: false);
    bool reachable;
    try {
      reachable = await check(endpoint).timeout(const Duration(seconds: 6));
    } catch (_) {
      reachable = false;
    }
    if (ref.mounted && generation == _generation) {
      state = state.copyWith(probing: false, reachable: reachable);
    }
  }
}
