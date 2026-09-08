import 'dart:async';

import 'package:booruflow/core/settings_service.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/discovery/availability.dart';
import 'package:booruflow/features/discovery/logic.dart';
import 'package:booruflow/features/discovery/widgets/discovery_toolbar.dart';
import 'package:booruflow/features/discovery/widgets/home_header.dart';
import 'package:booruflow/features/discovery/widgets/post_collection_view.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/shared/widgets/auto_scaffold.dart';
import 'package:booruflow/shared/widgets/form_controls.dart';
import 'package:booruflow/shared/widgets/interaction_controls.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key, this.tags, this.sourceId, this.loader});
  final CollectionLoader? loader;
  final List<String>? tags;
  final String? sourceId;
  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  static final _feeds = <String, FeedCollectionRequest>{};
  final _probeSuccess = <String>{};
  final _probePending = <String>{};
  final _probeFailures = <String, DateTime>{};
  late PostCollectionController _controller;
  late final _query = TextEditingController(text: widget.tags?.join(' ') ?? '');
  BooruService get service => BooruService.instance;
  String get sourceId => switch (widget.tags) {
    null => service.selectedSource.value,
    _ => widget.sourceId ?? service.selectedSource.value,
  };
  BooruSource get source => service.sourceById(sourceId);
  FeedCollectionRequest get feed =>
      _feeds[sourceId] ?? const FeedCollectionRequest();
  String get _probeKey => '$sourceId:${service.revision.value}';
  bool get popularAvailable =>
      source.capabilities.discovery.popular ==
          CapabilityAvailability.available ||
      _probeSuccess.contains(_probeKey);

  @override
  void initState() {
    super.initState();
    _controller = _acquire(_key());
    service.selectedSource.addListener(_changed);
    service.revision.addListener(_changed);
    SettingsService.changes.addListener(_changed);
    _probe();
  }

  PostCollectionController _acquire(CollectionKey key) =>
      switch (widget.loader) {
        null => CollectionCache.instance.acquire(key),
        _ => PostCollectionController(key, loader: widget.loader),
      };
  void _release(PostCollectionController controller) {
    if (widget.loader == null) {
      CollectionCache.instance.release(controller.key);
    } else {
      controller.dispose();
    }
  }

  CollectionKey _key() => CollectionKey(
    sourceId: sourceId,
    request: switch (widget.tags) {
      null => feed,
      _ => TagSearchCollectionRequest(widget.tags!),
    },
    ratings: SettingsService.ratings,
    revision: service.revision.value,
  );
  void _changed() {
    if (!mounted) return;
    final key = _key();
    if (_controller.key != key) {
      final old = _controller;
      _controller = _acquire(key);
      _release(old);
    }
    setState(() {});
    _probe();
  }

  @override
  void didUpdateWidget(covariant DiscoveryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _query.text = widget.tags?.join(' ') ?? '';
    _changed();
  }

  @override
  void dispose() {
    service.selectedSource.removeListener(_changed);
    service.revision.removeListener(_changed);
    SettingsService.changes.removeListener(_changed);
    _release(_controller);
    _query.dispose();
    super.dispose();
  }

  Future<void> _probe({bool refresh = false}) async {
    if (source.capabilities.discovery.popular !=
        CapabilityAvailability.requiresProbe) {
      return;
    }
    final key = _probeKey;
    final lastFailure = _probeFailures[key];
    if (!refresh && _probeSuccess.contains(key) ||
        _probePending.contains(key) ||
        !refresh &&
            lastFailure != null &&
            DateTime.now().difference(lastFailure) <
                const Duration(minutes: 5)) {
      return;
    }
    _probePending.add(key);
    try {
      final availability = await DiscoveryAvailability.instance.popular(
        sourceId,
        refresh: refresh,
      );
      if (mounted) {
        setState(() {
          if (availability == CapabilityAvailability.available) {
            _probeSuccess.add(key);
            _probeFailures.remove(key);
          } else {
            _probeFailures[key] = DateTime.now();
          }
        });
      }
    } catch (_) {
      _probeFailures[key] = DateTime.now();
    } finally {
      _probePending.remove(key);
    }
  }

  void _selectSource(String id) {
    if (widget.tags != null) {
      _edit(id);
      return;
    }
    if (feed.kind != FeedKind.latest &&
        service.sourceById(id).capabilities.discovery.popular ==
            CapabilityAvailability.unsupported) {
      AppToast.show(t.discovery.latestFallback);
    }
    service.selectSource(id);
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
    service.selectSource(result.sourceId);
    context.replaceTaggedPosts(result.tags, sourceId: result.sourceId);
  }

  Future<void> _filters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.discovery.filters,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(t.discovery.defaultRatingsHint),
                const SizedBox(height: 16),
                AppButton(
                  label: t.discovery.allAvailable,
                  onPressed: () {
                    SettingsService.ratings = [];
                    update(() {});
                  },
                ),
                const SizedBox(height: 12),
                for (final rating in SettingsService.configurableRatings) ...[
                  if (rating != SettingsService.configurableRatings.first)
                    const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    title: Text(rating.shortLabel),
                    value: SettingsService.ratings.contains(rating),
                    onChanged: (selected) {
                      final ratings = SettingsService.ratings.toSet();
                      if (selected == true) {
                        ratings.add(rating);
                      } else {
                        ratings.remove(rating);
                      }
                      SettingsService.ratings = ratings.toList();
                      update(() {});
                    },
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: t.discovery.resetFilters,
                  kind: AppButtonKind.ghost,
                  onPressed: () {
                    _resetFilters();
                    update(() {});
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: t.generic.confirm,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    SettingsService.ratings = [];
  }

  void _selectMode(FeedKind kind) {
    final caps = source.capabilities.discovery;
    _feeds[sourceId] = FeedCollectionRequest(
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
    );
    _changed();
  }

  Future<void> _chooseDate() async {
    final id = sourceId;
    final current = feed;
    final today = DateTime.now().toUtc();
    final chosen = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current.date ?? '') ?? today,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (!mounted || chosen == null || sourceId != id) return;
    _feeds[id] = FeedCollectionRequest(
      kind: FeedKind.historicalPopular,
      range: current.range,
      date: chosen.toIso8601String().substring(0, 10),
    );
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final caps = source.capabilities.discovery;
    final showBack = widget.tags != null && !shouldUseDesktopShell(context);
    return PostCollectionView(
      key: ValueKey(_controller),
      controller: _controller,
      columns: SettingsService.waterfallColumns,
      onResetFilters: _resetFilters,
      headerSliver: SliverAppBar(
        floating: true,
        snap: false,
        automaticallyImplyLeading: false,
        toolbarHeight:
            appFieldHeight(context) +
            20 +
            (switch (widget.tags) {
              null => 0,
              _ => 48,
            }),
        flexibleSpace: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tags == null)
                HomeHeader(
                  sourceId: sourceId,
                  kind: feed.kind,
                  modes: [
                    FeedKind.latest,
                    if (popularAvailable) FeedKind.recentPopular,
                    if (popularAvailable && caps.historicalRanges.isNotEmpty)
                      FeedKind.historicalPopular,
                    ...caps.additionalFeeds,
                  ],
                  modeLabel: feedLabel,
                  onSource: _selectSource,
                  onMode: _selectMode,
                  onRetryProbe: _probeFailures.containsKey(_probeKey)
                      ? () => _probe(refresh: true)
                      : null,
                  details: switch (feed.range) {
                    null => null,
                    _ => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 180,
                          child: AppSelect<PopularRange>(
                            value: feed.range,
                            items: [
                              for (final range in switch (feed.kind) {
                                FeedKind.historicalPopular =>
                                  caps.historicalRanges,
                                _ => caps.popularRanges,
                              })
                                AppSelectItem(
                                  value: range,
                                  label: switch (feed.kind) {
                                    FeedKind.historicalPopular =>
                                      historicalRangeLabel(range),
                                    _ => rangeLabel(range, caps.timeBasis),
                                  },
                                ),
                            ],
                            onChanged: (range) {
                              _feeds[sourceId] = FeedCollectionRequest(
                                kind: feed.kind,
                                range: range,
                                date: feed.date,
                              );
                              _changed();
                            },
                          ),
                        ),
                        if (feed.kind == FeedKind.historicalPopular) ...[
                          const SizedBox(width: 8),
                          AppButton(
                            label: feed.date!,
                            compact: true,
                            onPressed: _chooseDate,
                          ),
                        ],
                      ],
                    ),
                  },
                )
              else ...[
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (showBack)
                        const BackButton()
                      else
                        const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.discovery.searchTermsTitle(
                            count: widget.tags!.length,
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                DiscoveryToolbar(
                  sourceId: sourceId,
                  onSource: _selectSource,
                  query: AppTextField(
                    key: const ValueKey('search-result-query'),
                    height: appFieldHeight(context),
                    controller: _query,
                    readOnly: true,
                    hintText: t.discovery.queryHint,
                    onTap: _edit,
                    trailing: AppIconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: const EdgeInsets.all(6),
                      tooltip: t.postSearch.title,
                      icon: const Icon(Icons.search),
                      onPressed: _edit,
                    ),
                  ),
                  action: AppIconButton(
                    tooltip: t.discovery.filters,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: const EdgeInsets.all(6),
                    selectedBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .10),
                    color: _controller.key.ratings.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    selected: _controller.key.ratings.isNotEmpty,
                    icon: const Icon(Icons.tune),
                    onPressed: _filters,
                  ),
                ),
              ],
            ],
          ),
        ),
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
