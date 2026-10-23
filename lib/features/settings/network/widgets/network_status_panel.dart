import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/settings/network/network_logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:intl/intl.dart';

class NetworkStatusPanel extends ConsumerStatefulWidget {
  const NetworkStatusPanel({super.key});
  @override
  ConsumerState<NetworkStatusPanel> createState() => _NetworkStatusPanelState();
}

class _NetworkStatusPanelState extends ConsumerState<NetworkStatusPanel> {
  late final NetworkStatus _controller;
  bool _checking = false, _refreshing = false;
  String? _checkingSource;
  List<BooruSource> get _sources =>
      ref.read(networkProbeBackendProvider).sources;
  NetworkStatusState get _status => ref.read(networkStatusProvider);
  bool get _enabled => !_status.busy && !ref.read(networkConfigProvider).busy;
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

  Future<bool> _check(List<BooruSource> sources, {String? sourceId}) async {
    if (!_enabled) return false;
    setState(() {
      _checking = true;
      _checkingSource = sourceId;
    });
    try {
      await _controller.checkSources(sources);
      return mounted &&
          _status.error == null &&
          (sourceId == null || _status.errors[sourceId] == null);
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
          _checkingSource = null;
        });
      }
    }
  }

  Future<bool> _refresh() async {
    if (!_enabled) return false;
    setState(() => _refreshing = true);
    try {
      await _controller.refreshRoutes();
      return mounted && _status.error == null;
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _label(String id) => switch (_status.checks[id]) {
    SourceCheckStatus.available => t.settingsDetails.apiAndImages,
    SourceCheckStatus.partial => t.settingsDetails.apiOnly,
    SourceCheckStatus.failed => t.settings.network.sourceUnavailable,
    SourceCheckStatus.checking => t.settings.network.checkingCompact,
    _ => t.settings.network.uncheckedCompact,
  };
  FrostStatusTone _tone(String id) => switch (_status.checks[id]) {
    SourceCheckStatus.available => FrostStatusTone.positive,
    SourceCheckStatus.partial => FrostStatusTone.caution,
    SourceCheckStatus.failed => FrostStatusTone.negative,
    SourceCheckStatus.checking => FrostStatusTone.accent,
    _ => FrostStatusTone.neutral,
  };
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    ref.watch(networkStatusProvider);
    ref.watch(networkConfigProvider);
    final n = t.settings.network;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: FrostGap.of(context).rowInset,
          ),
          child: Row(
            children: [
              Expanded(
                child: FrostText(
                  t.settingsDetails.sourceStatus,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                ),
              ),
              FrostButton.quiet(
                label: n.checkAllSources,
                tooltip: n.checkAllSources,
                size: FrostControlSize.compact,
                onPressedAsync: _enabled || _checking && _checkingSource == null
                    ? () => _check(_sources)
                    : null,
              ),
            ],
          ),
        ),
        FrostGroupedSection(
          children: [
            for (final source in _sources)
              FrostListRow(
                key: ValueKey('source-details-${source.sourceId}'),
                title: source.displayName,
                trailing:
                    _status.checks[source.sourceId] ==
                        SourceCheckStatus.checking
                    ? FrostActivityIndicator(semanticLabel: n.checkingCompact)
                    : FrostStatusDot(
                        key: ValueKey('source-status-${source.sourceId}'),
                        tone: _tone(source.sourceId),
                      ),
                subtitle: _label(source.sourceId),
                onPressed: () => _showDetails(source),
              ),
          ],
        ),
      ],
    );
  }

  Widget _metric(String label, bool? value) => FrostStatusDot(
    label: label,
    tone: switch (value) {
      true => FrostStatusTone.positive,
      false => FrostStatusTone.negative,
      null => FrostStatusTone.neutral,
    },
  );
  Future<void> _showDetails(BooruSource source) => showFrostDialog<void>(
    context: context,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        ref.watch(networkStatusProvider);
        ref.watch(networkConfigProvider);
        final n = t.settings.network, id = source.sourceId;
        final result = _status.details[id];
        final reports =
            _status.routes?.diagnostics
                .where((r) => r.sourceIds.contains(id))
                .toList() ??
            const <RouteDiagnostic>[];
        return FrostDialog(
          title: source.displayName,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostStatusDot(label: _label(id), tone: _tone(id)),
              const SizedBox(height: FrostGap.related),
              Wrap(
                spacing: FrostGap.group,
                runSpacing: FrostGap.inline,
                children: [
                  _metric(n.apiShort, result?.apiAvailable),
                  _metric(
                    n.imagesShort,
                    result?.apiAvailable == true
                        ? result?.mediaAvailable
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: FrostGap.related),
              Wrap(
                spacing: FrostGap.related,
                runSpacing: FrostGap.related,
                children: [
                  FrostButton(
                    label: n.checkCompact,
                    icon: appIcons.refresh,
                    onPressedAsync:
                        _enabled ||
                            _checking && _checkingSource == source.sourceId
                        ? () => _check([source], sourceId: source.sourceId)
                        : null,
                  ),
                  FrostButton(
                    label: n.refreshRoutes,
                    icon: appIcons.refresh,
                    onPressedAsync: _enabled || _refreshing ? _refresh : null,
                  ),
                ],
              ),
              if (_status.errors[id] case final error?)
                FrostErrorDetails(details: error, initiallyExpanded: true),
              if (_status.error case final error?)
                FrostErrorDetails(details: error, initiallyExpanded: true),
              for (final report in reports) ...[
                const SizedBox(height: FrostGap.group),
                _host(report),
              ],
              if (reports.isEmpty)
                FrostText(
                  n.dnsPending,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                ),
            ],
          ),
        );
      },
    ),
  );
  Widget _host(RouteDiagnostic report) {
    final n = t.settings.network;
    final status = switch (report.status) {
      'resolving' => n.dnsResolving,
      'resolved' => n.dnsResolved,
      'cached' => n.dnsCached,
      'failed' => n.dnsFailed,
      _ => _status.routes?.refreshing == true ? n.dnsQueued : n.dnsPending,
    };
    final time = DateTime.tryParse(report.updatedAtIso8601 ?? '')?.toLocal();
    final saved =
        _status.routes?.refreshing != true &&
        (report.status == 'resolved' || report.status == 'cached');
    return FrostGroupedSection(
      children: [
        FrostListRow(
          title: report.logicalHost,
          subtitle:
              '$status${report.elapsedMs == null ? '' : ' · ${report.elapsedMs} ms'}',
        ),
        if (report.candidates.isNotEmpty)
          Padding(
            padding: EdgeInsets.all(FrostGap.of(context).rowInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostCodeBlock(text: report.candidates.join('\n')),
                FrostText(
                  saved && time != null
                      ? n.ipCachedAt(
                          time: DateFormat.yMd(
                            LocaleSettings.currentLocale.languageCode,
                          ).add_Hms().format(time),
                        )
                      : n.ipNotCached,
                  role: FrostTextRole.footnote,
                  tone: FrostTextTone.secondary,
                ),
              ],
            ),
          ),
        if (report.error case final error?)
          FrostErrorDetails(details: error, initiallyExpanded: true),
      ],
    );
  }
}
