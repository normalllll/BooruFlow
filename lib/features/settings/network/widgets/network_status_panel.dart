import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStatusPanel extends ConsumerStatefulWidget {
  const NetworkStatusPanel({super.key});
  @override
  ConsumerState<NetworkStatusPanel> createState() => _NetworkStatusPanelState();
}

class _NetworkStatusPanelState extends ConsumerState<NetworkStatusPanel> {
  late final NetworkStatus _controller;
  List<BooruSource> get _sources =>
      ref.read(networkProbeBackendProvider).sources;
  NetworkStatusState get _status => ref.read(networkStatusProvider);
  RouteCacheState? get _state => _status.routes;
  Map<String, SourceCheckStatus> get _checks => _status.checks;
  Map<String, SourceConnectionCheck> get _details => _status.details;
  Map<String, String> get _errors => _status.errors;
  bool get _busy => _status.busy;
  String? get _error => _status.error;
  bool get _enabled => !ref.read(networkConfigProvider).busy;
  @override
  void initState() {
    super.initState();
    _controller = ref.read(networkStatusProvider.notifier);
    _controller.attach();
  }

  @override
  void dispose() {
    _controller.detach();
    super.dispose();
  }

  Future<void> _checkAll() => _controller.checkSources(_sources);
  Future<void> _checkSources(List<BooruSource> sources) =>
      _controller.checkSources(sources);
  Future<void> _refresh() => _controller.refreshRoutes();
  String _label(String id) => switch (_checks[id]) {
    SourceCheckStatus.available => t.settings.network.sourceAvailable,
    SourceCheckStatus.partial => t.settings.network.sourcePartial,
    SourceCheckStatus.failed => t.settings.network.sourceUnavailable,
    SourceCheckStatus.checking => t.settings.network.checkingCompact,
    _ => t.settings.network.uncheckedCompact,
  };
  Color _color(String id) => switch (_checks[id]) {
    SourceCheckStatus.available => Colors.greenAccent.shade400,
    SourceCheckStatus.partial => Colors.amber,
    SourceCheckStatus.failed => Colors.redAccent,
    SourceCheckStatus.checking => Colors.blue,
    _ => Colors.grey,
  };
  @override
  Widget build(BuildContext context) {
    ref.watch(networkStatusProvider);
    ref.watch(networkConfigProvider);
    final n = t.settings.network;
    if (_sources.isEmpty) return const SizedBox();
    final available = _checks.values
        .where((s) => s == SourceCheckStatus.available)
        .length;
    final issues = _checks.values
        .where(
          (s) =>
              s == SourceCheckStatus.partial || s == SourceCheckStatus.failed,
        )
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final list = Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (final source in _sources) _sourceRow(source)],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.servicesTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          n.sourceSummary(available: available, issues: issues),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: n.checkCompact,
                    tooltip: n.checkAllSources,
                    icon: Icons.refresh_rounded,
                    kind: AppButtonKind.ghost,
                    compact: true,
                    loading: _busy,
                    onPressed: _busy || !_enabled ? null : _checkAll,
                  ),
                ],
              ),
            ),
            list,
          ],
        );
      },
    );
  }

  Widget _sourceRow(BooruSource source) {
    final n = t.settings.network;
    final result = _details[source.sourceId];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 540 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final metrics = Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              _label(source.sourceId),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _metric(n.apiShort, result?.apiAvailable),
            _metric(
              n.imagesShort,
              result?.apiAvailable == true ? result?.mediaAvailable : null,
            ),
          ],
        );
        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('source-details-${source.sourceId}'),
            onTap: () => _showDetails(source),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: _label(source.sourceId),
                      child: Icon(
                        Icons.circle,
                        key: ValueKey('source-status-${source.sourceId}'),
                        size: 8,
                        color: _color(source.sourceId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            message: source.displayName,
                            child: Text(
                              source.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (!columns)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: metrics,
                            ),
                        ],
                      ),
                    ),
                    if (columns) ...[
                      SizedBox(
                        width: 100,
                        child: Text(
                          _label(source.sourceId),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: _metric(n.apiShort, result?.apiAvailable),
                      ),
                      SizedBox(
                        width: 82,
                        child: _metric(
                          n.imagesShort,
                          result?.apiAvailable == true
                              ? result?.mediaAvailable
                              : null,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metric(String label, bool? available) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        switch (available) {
          null => Icons.remove_rounded,
          true => Icons.check_circle_outline,
          false => Icons.error_outline,
        },
        size: 16,
        color: switch (available) {
          null => Colors.grey,
          true => Colors.green,
          false => Colors.redAccent,
        },
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  void _showDetails(BooruSource source) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Consumer(
            builder: (_, ref, _) {
              ref.watch(networkStatusProvider);
              ref.watch(networkConfigProvider);
              return SingleChildScrollView(
                child: _detailContent(
                  source,
                  () => Navigator.pop(sheetContext),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detailContent(BooruSource source, VoidCallback close) {
    final n = t.settings.network;
    final result = _details[source.sourceId];
    final reports =
        _state?.diagnostics
            .where((r) => r.sourceIds.contains(source.sourceId))
            .toList() ??
        const <RouteDiagnostic>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  source.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: close,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          Text(
            _label(source.sourceId),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _metric(n.apiShort, result?.apiAvailable),
              _metric(
                n.imagesShort,
                result?.apiAvailable == true ? result?.mediaAvailable : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: n.checkCompact,
              icon: Icons.refresh_rounded,
              compact: true,
              kind: AppButtonKind.ghost,
              loading: _checks[source.sourceId] == SourceCheckStatus.checking,
              onPressed: _busy || !_enabled
                  ? null
                  : () => _checkSources([source]),
            ),
          ),
          if (_errors[source.sourceId] case final error?) SelectableText(error),
          if (_error != null) SelectableText(_error!),
          for (final report in reports)
            _host(context, report, _state?.refreshing ?? false),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(n.dnsPending),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: n.refreshRoutes,
              compact: true,
              kind: AppButtonKind.ghost,
              icon: Icons.refresh_rounded,
              onPressed: _busy || !_enabled ? null : _refresh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _host(BuildContext context, RouteDiagnostic report, bool refreshing) {
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
            '$status${switch (report.elapsedMs) {
              null => '',
              _ => ' · ${report.elapsedMs} ms',
            }}',
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
