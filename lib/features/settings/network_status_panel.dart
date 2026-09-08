import 'dart:async';

import 'package:flutter/material.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

class NetworkStatusPanel extends StatefulWidget {
  const NetworkStatusPanel({
    super.key,
    required this.sources,
    required this.readState,
    required this.refreshRoutes,
    required this.checkSource,
    required this.onBusyChanged,
    this.enabled = true,
  });

  final List<BooruSourceDto> sources;
  final Future<RouteCacheStateDto> Function() readState;
  final Future<RouteCacheStateDto> Function() refreshRoutes;
  final Future<void> Function(String) checkSource;
  final ValueChanged<bool> onBusyChanged;
  final bool enabled;

  @override
  State<NetworkStatusPanel> createState() => _NetworkStatusPanelState();
}

class _NetworkStatusPanelState extends State<NetworkStatusPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  RouteCacheStateDto? _state;
  final _checks = <String, String>{};
  final _errors = <String, String>{};
  bool _busy = false;
  bool _reading = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
    // This reads local diagnostics only; it never performs network requests.
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) => _read());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _read() async {
    if (_reading) return;
    _reading = true;
    try {
      final state = await widget.readState();
      if (mounted && state != _state) setState(() => _state = state);
    } catch (error) {
      if (mounted) {
        setState(() => _error = describeBooruError(error));
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _checks.clear();
      _errors.clear();
    });
    widget.onBusyChanged(true);
    try {
      final state = await widget.refreshRoutes();
      if (!mounted) return;
      setState(() => _state = state);
      // Each source has a bounded API check, independent of the DNS result.
      await Future.wait(
        widget.sources.map((source) async {
          if (!mounted) return;
          setState(() => _checks[source.sourceId] = 'checking');
          try {
            await widget.checkSource(source.sourceId);
            if (mounted) {
              setState(() => _checks[source.sourceId] = 'available');
            }
          } catch (error) {
            if (mounted) {
              setState(() {
                _checks[source.sourceId] = 'failed';
                _errors[source.sourceId] = describeBooruError(error);
              });
            }
          }
        }),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = describeBooruError(error));
      }
    } finally {
      await _read();
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final n = t.settings.network;
    final reports = _state?.diagnostics ?? const <RouteDiagnosticDto>[];
    final finished = reports
        .where(
          (r) =>
              r.status == 'resolved' ||
              r.status == 'failed' ||
              r.status == 'cached',
        )
        .length;
    final active = _busy || (_state?.refreshing ?? false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                n.servicesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppButton(
                label: n.refreshRoutes,
                onPressed: active || !widget.enabled ? null : _refresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(n.servicesHint),
          if (_state?.provider case final provider?) ...[
            const SizedBox(height: 8),
            Text(
              '${n.dnsProvider}: ${provider == RouteProvider.uncensoredDns ? 'UncensoredDNS' : 'doh.sb'}',
            ),
          ],
          const SizedBox(height: 8),
          if (active) ...[
            Text(
              n.checkProgress(
                done: finished,
                total: reports.length,
                checked: _checks.values.where((s) => s != 'checking').length,
                sources: widget.sources.length,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: reports.isEmpty
                  ? 0
                  : (finished +
                            _checks.values
                                .where((s) => s != 'checking')
                                .length) /
                        (reports.length + widget.sources.length),
            ),
          ] else
            Text(
              _state == null
                  ? n.loadingStatus
                  : n.checkSummary(
                      available: _checks.values
                          .where((s) => s == 'available')
                          .length,
                      total: widget.sources.length,
                      failed: reports.where((r) => r.status == 'failed').length,
                    ),
            ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SelectableText(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          for (final source in widget.sources) ...[
            const Divider(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  source.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  switch (_checks[source.sourceId]) {
                    'checking' => n.apiChecking,
                    'available' => n.apiAvailable,
                    'failed' => n.apiFailed,
                    _ => n.apiUnchecked,
                  },
                  style: TextStyle(
                    color: _checks[source.sourceId] == 'failed'
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_errors[source.sourceId] case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            for (final report in reports.where(
              (r) => r.sourceIds.contains(source.sourceId),
            ))
              _host(context, report, _state?.refreshing ?? false),
            if (!reports.any((r) => r.sourceIds.contains(source.sourceId)))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(n.dnsPending),
              ),
          ],
        ],
      ),
    );
  }

  Widget _host(
    BuildContext context,
    RouteDiagnosticDto report,
    bool refreshing,
  ) {
    final n = t.settings.network;
    final status = switch (report.status) {
      'resolving' => n.dnsResolving,
      'resolved' => n.dnsResolved,
      'cached' => n.dnsCached,
      'failed' => n.dnsFailed,
      _ => refreshing ? n.dnsQueued : n.dnsPending,
    };
    final saved =
        !refreshing &&
        (report.status == 'resolved' || report.status == 'cached');
    final time = DateTime.tryParse(report.updatedAtIso8601 ?? '')?.toLocal();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            report.logicalHost,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '$status${report.elapsedMs == null ? '' : ' · ${report.elapsedMs} ms'}',
            style: TextStyle(
              color: report.status == 'failed'
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
          if (report.candidates.isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(report.candidates.join('\n')),
            const SizedBox(height: 6),
            Text(
              saved && time != null
                  ? n.ipCachedAt(time: _formatTime(time))
                  : n.ipNotCached,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (report.error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
