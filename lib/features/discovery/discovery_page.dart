import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/discovery_logic.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/discovery/widgets/rating_filter.dart';
import 'package:booruflow/features/downloads/batch/batch_download_dialog.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:booruflow/features/search/query.dart';
import 'package:booruflow/features/search/user_tags_page.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key, this.tags, this.sourceId, this.loader});
  final CollectionLoader? loader;
  final List<String>? tags;
  final String? sourceId;
  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  BatchDownloadRequest? _batchRequest;
  final _collection = GlobalKey<PostCollectionViewState>();
  BooruService get service => ref.read(booruServiceProvider);
  String get sourceId => widget.tags == null
      ? ref.read(booruSessionProvider).sourceId
      : widget.sourceId ?? ref.read(booruSessionProvider).sourceId;
  BooruSource get source => service.sourceById(sourceId);
  FeedCollectionRequest get feed =>
      ref.read(feedSelectionProvider)[sourceId] ??
      const FeedCollectionRequest();
  PopularProbeKey get _probeKey =>
      (sourceId: sourceId, revision: ref.read(booruSessionProvider).revision);
  bool get popularAvailable =>
      source.capabilities.discovery.popular ==
          CapabilityAvailability.available ||
      (ref.read(popularProbeProvider(_probeKey)).value?.available ?? false);
  CollectionKey _key() => CollectionKey(
    sourceId: sourceId,
    request: widget.tags == null
        ? feed
        : TagSearchCollectionRequest(widget.tags!),
    ratings: ref.read(settingsProvider).ratings,
    revision: ref.read(booruSessionProvider).revision,
  );

  void _selectSource(String id) {
    if (widget.tags != null) {
      _edit(id);
      return;
    }
    if (feed.kind != FeedKind.latest &&
        service.sourceById(id).capabilities.discovery.popular ==
            CapabilityAvailability.unsupported) {
      FrostToast.info(t.discovery.latestFallback);
    }
    ref.read(booruSessionProvider.notifier).selectSource(id);
  }

  Future<void> _edit([String? target]) async {
    final result = await context.editSearch(
      widget.tags!,
      sourceId: target ?? sourceId,
    );
    if (!mounted || result == null) return;
    if (result.sourceId == sourceId &&
        setEquals(result.tags.toSet(), widget.tags!.toSet())) {
      return;
    }
    ref.read(booruSessionProvider.notifier).selectSource(result.sourceId);
    context.replaceTaggedPosts(result.tags, sourceId: result.sourceId);
  }

  Future<void> _filters() => showRatingFilterSheet(context);

  Future<void> _openBatchDownload() async {
    final request =
        _batchRequest ??
        BatchDownloadRequest(
          key: _key(),
          sourceName: source.displayName,
          loader: widget.loader,
        );
    setState(() => _batchRequest = request);
    final done = await showBatchDownloadDialog(context, request);
    if (!mounted) return;
    final state = ref.read(batchDownloadProvider(request));
    if (state.phase == BatchPhase.enqueueing ||
        (state.phase == BatchPhase.finished &&
            state.failed.isNotEmpty &&
            done != true)) {
      return;
    }
    ref.read(batchDownloadProvider(request).notifier).stopFetching();
    setState(() => _batchRequest = null);
  }

  void _selectMode(FeedKind kind) {
    final caps = source.capabilities.discovery;
    ref
        .read(feedSelectionProvider.notifier)
        .select(
          sourceId,
          FeedCollectionRequest(
            kind: kind,
            range: switch (kind) {
              FeedKind.recentPopular => caps.popularRanges.first,
              FeedKind.historicalPopular => caps.historicalRanges.first,
              _ => null,
            },
            date: switch (kind) {
              FeedKind.historicalPopular =>
                DateTime.now()
                    .toUtc()
                    .subtract(const Duration(days: 1))
                    .toIso8601String()
                    .substring(0, 10),
              _ => null,
            },
          ),
        );
  }

  Future<void> _chooseDate() async {
    final id = sourceId, current = feed;
    final today = DateTime.now().toUtc();
    var selected = DateTime.tryParse(current.date ?? '') ?? today;
    final ranges = source.capabilities.discovery.historicalRanges;
    var selectedRange = ranges.contains(current.range)
        ? current.range!
        : ranges.first;
    final chosen = await showFrostDialog<(DateTime, PopularRange)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => FrostDialog(
          title: t.discovery.historicalPopular,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ranges.length > 1) ...[
                FrostPicker<PopularRange>(
                  label: t.discovery.historicalPopular,
                  value: selectedRange,
                  options: [
                    for (final range in ranges)
                      FrostPickerOption(
                        value: range,
                        label: historicalRangeLabel(range),
                      ),
                  ],
                  onChanged: (range) => update(() => selectedRange = range),
                ),
                const SizedBox(height: FrostGap.group),
              ],
              FrostDatePicker(
                label: t.discovery.historicalPopular,
                value: selected,
                firstDate: DateTime(2000),
                lastDate: DateTime(today.year, today.month, today.day),
                onChanged: (date) {
                  if (date != null) update(() => selected = date);
                },
              ),
            ],
          ),
          actions: [
            FrostDialogAction<(DateTime, PopularRange)>(
              label: t.generic.cancel,
              role: FrostButtonRole.cancel,
            ),
            FrostDialogAction<(DateTime, PopularRange)>(
              label: t.generic.confirm,
              isDefault: true,
              value: (selected, selectedRange),
            ),
          ],
        ),
      ),
    );
    if (!mounted || chosen == null || sourceId != id) return;
    ref
        .read(feedSelectionProvider.notifier)
        .select(
          id,
          FeedCollectionRequest(
            kind: FeedKind.historicalPopular,
            range: chosen.$2,
            date: chosen.$1.toIso8601String().substring(0, 10),
          ),
        );
  }

  void _setRange(FeedKind kind, PopularRange range) {
    ref
        .read(feedSelectionProvider.notifier)
        .select(
          sourceId,
          FeedCollectionRequest(
            kind: kind,
            range: range,
            date: kind == FeedKind.historicalPopular
                ? feed.date ??
                      DateTime.now().toUtc().toIso8601String().substring(0, 10)
                : null,
          ),
        );
  }

  List<FrostMenuEntry> _ranges() {
    final caps = source.capabilities.discovery;
    return [
      FrostMenuSection(
        header: caps.timeBasis == PopularTimeBasis.calendarUploadPeriod
            ? t.discovery.calendarRanges
            : t.discovery.rollingRanges,
        entries: [
          for (final range in caps.popularRanges)
            FrostMenuAction(
              rangeLabel(range, caps.timeBasis),
              checked:
                  feed.kind == FeedKind.recentPopular && feed.range == range,
              onSelected: () => _setRange(FeedKind.recentPopular, range),
            ),
        ],
      ),
      if (caps.historicalRanges.isNotEmpty)
        FrostMenuAction(
          t.discovery.historicalPopular,
          icon: appIcons.calendar,
          onSelected: _chooseDate,
        ),
    ];
  }

  Future<void> _saveTag() async {
    final tags = widget.tags!;
    // Aliases name one canonical source tag; a multi-term result offers its
    // terms rather than storing an invalid space-separated alias.
    final tag = tags.length == 1
        ? tags.single
        : await showFrostSheet<String>(
            context: context,
            title: t.discovery.addCustomTag,
            detents: const [FrostSheetDetent.fitted],
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tag in tags)
                  FrostListRow(
                    title: tag,
                    onPressed: () => Navigator.of(context).pop(tag),
                  ),
              ],
            ),
          );
    if (!mounted || tag == null) return;
    await editUserTag(
      context,
      source: sourceId,
      locale: Localizations.localeOf(context).toLanguageTag(),
      value: QueryTerm.parse(tag).value,
    );
  }

  Future<void> _copyQueryLink() async {
    try {
      final key = _key();
      final ratings = ratingsForSource(key, source.capabilities.ratings);
      final url = await switch (key.request) {
        TagSearchCollectionRequest(:final tags) => service.engine.searchWebUrl(
          request: SearchRequest(
            sourceId: key.sourceId,
            queryText: tags.join(' '),
            ratings: ratings,
            pageSize: 40,
          ),
        ),
        FeedCollectionRequest(:final kind, :final range, :final date) =>
          service.engine.feedWebUrl(
            request: FeedRequest(
              sourceId: key.sourceId,
              kind: kind,
              range: range,
              date: date,
              ratings: ratings,
              pageSize: 40,
            ),
          ),
      };
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) FrostToast.copied(t.verificationPage.linkCopied);
    } catch (error) {
      if (mounted) {
        FrostToast.fromError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_batchRequest case final request?) {
      ref.watch(batchDownloadProvider(request));
    }
    ref.watch(booruSessionProvider);
    final settings = ref.watch(settingsProvider);
    ref.watch(feedSelectionProvider);
    final probe = ref.watch(popularProbeProvider(_probeKey));
    final caps = source.capabilities.discovery;
    final modes = [
      FeedKind.latest,
      if (popularAvailable) FeedKind.recentPopular,
      ...caps.additionalFeeds,
    ];
    final showsModes = modes.length > 1;
    final selectedMode = feed.kind == FeedKind.historicalPopular
        ? FeedKind.recentPopular
        : feed.kind;
    final range = feed.range;
    final rangeText = range == null
        ? null
        : [
            feed.kind == FeedKind.historicalPopular
                ? historicalRangeLabel(range)
                : rangeLabel(range, caps.timeBasis),
            if (feed.date != null) feed.date!,
          ].join(' · ');
    final more = <FrostMenuEntry>[
      if (probe.value?.failedAt != null)
        FrostMenuAction(
          t.generic.retry,
          icon: appIcons.refresh,
          onSelected: () =>
              ref.read(popularProbeProvider(_probeKey).notifier).refresh(),
        ),
      FrostMenuAction(
        t.frost.reload,
        icon: appIcons.refresh,
        onSelected: () => _collection.currentState?.refresh(),
      ),
      FrostMenuAction(
        t.discovery.copyQueryLink,
        icon: appIcons.link,
        onSelected: _copyQueryLink,
      ),
      if (widget.tags != null) ...[
        FrostMenuAction(
          t.discovery.addCustomTag,
          icon: appIcons.add,
          onSelected: _saveTag,
        ),
        FrostMenuAction(
          t.postSearch.title,
          icon: appIcons.edit,
          onSelected: _edit,
        ),
        FrostMenuSubmenu(
          t.discovery.tagSource,
          entries: [
            for (final source in ref.watch(booruSourcesProvider))
              FrostMenuAction(
                source.displayName,
                checked: source.sourceId == sourceId,
                onSelected: () => _selectSource(source.sourceId),
              ),
          ],
        ),
      ],
    ];
    final identity = (key: _key(), loader: widget.loader);
    final iconWidth = FrostDensity.of(context).targetHeight;
    final sourceMenu = FrostTitleMenu(
      title: source.displayName,
      entries: [
        for (final item in ref.watch(booruSourcesProvider))
          FrostMenuAction(
            item.displayName,
            checked: item.sourceId == sourceId,
            onSelected: () => _selectSource(item.sourceId),
          ),
      ],
    );
    return PostCollectionView(
      key: _collection,
      collection: identity,
      columns: settings.waterfallColumns,
      filterBarBuilder: (_) => const RatingConditions(),
      headerBuilder: (context, collection) => FrostPageHeader(
        leading: widget.tags == null ? [sourceMenu] : const [],
        title: widget.tags != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FrostText(
                    widget.tags!.join(' · '),
                    role: FrostTextRole.headline,
                  ),
                  FrostText(
                    source.displayName,
                    role: FrostTextRole.footnote,
                    tone: FrostTextTone.secondary,
                  ),
                ],
              )
            : null,
        controls: [
          if (widget.tags == null && showsModes)
            FrostToolbarItem.picker<FeedKind>(
              value: selectedMode,
              label: t.discovery.mode,
              priority: FrostToolbarPriority.normal,
              choices: [
                for (final mode in modes)
                  FrostPickerOption(value: mode, label: feedLabel(mode)),
              ],
              onChanged: _selectMode,
            ),
          if (widget.tags == null && rangeText != null)
            FrostToolbarItem.menu(
              label: t.discovery.timeRange,
              valueLabel: rangeText,
              entries: _ranges(),
              priority: FrostToolbarPriority.low,
            ),
        ],
        actions: [
          FrostToolbarItem.custom(
            minWidth: iconWidth,
            priority: FrostToolbarPriority.high,
            builder: (_) => const RatingFilterButton(),
            overflowEntry: FrostMenuAction(
              t.discovery.filters,
              icon: appIcons.filter,
              onSelected: _filters,
            ),
          ),
          FrostToolbarItem.action(
            icon: appIcons.download,
            label: t.batchDownload.title,
            onPressed:
                collection.lastError == null || collection.items.isNotEmpty
                ? _openBatchDownload
                : null,
          ),
          FrostToolbarItem.custom(
            minWidth: iconWidth,
            priority: FrostToolbarPriority.low,
            builder: (_) => FrostMenuAnchor(
              entries: more,
              builder: (context, focus, toggle) => Focus(
                focusNode: focus,
                child: FrostButton.icon(
                  label: t.frost.more,
                  icon: appIcons.more,
                  size: FrostControlSize.compact,
                  onPressed: toggle,
                ),
              ),
            ),
            overflowEntry: FrostMenuSection(entries: more),
          ),
        ],
      ),
    );
  }
}

String historicalRangeLabel(PopularRange range) => switch (range) {
  PopularRange.day => t.discovery.calendarDay,
  PopularRange.week => t.discovery.calendarWeek,
  PopularRange.month => t.discovery.calendarMonth,
  _ => rangeLabel(range, PopularTimeBasis.calendarUploadPeriod),
};

String rangeLabel(PopularRange range, PopularTimeBasis basis) {
  if (basis == PopularTimeBasis.calendarUploadPeriod) {
    return switch (range) {
      PopularRange.day => t.discovery.today,
      PopularRange.week => t.discovery.thisWeek,
      _ => t.discovery.thisMonth,
    };
  }
  return switch (range) {
    PopularRange.day => t.discovery.lastDay,
    PopularRange.threeDays => t.discovery.lastThreeDays,
    PopularRange.week => t.discovery.lastWeek,
    PopularRange.month => t.discovery.lastMonth,
    PopularRange.threeMonths => t.discovery.lastThreeMonths,
    PopularRange.sixMonths => t.discovery.lastSixMonths,
    PopularRange.year => t.discovery.lastYear,
  };
}

String feedLabel(FeedKind kind) => switch (kind) {
  FeedKind.historicalPopular => t.discovery.historicalPopular,
  FeedKind.random => t.discovery.random,
  FeedKind.lifetimeViews => t.discovery.lifetimeViews,
  FeedKind.lifetimeFavorites => t.discovery.lifetimeFavorites,
  FeedKind.latest => t.discovery.latest,
  _ => t.discovery.popular,
};
