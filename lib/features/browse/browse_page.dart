import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/browse/browse_labels.dart';
import 'package:booruflow/features/browse/collection_actions.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/features/browse/discovery_logic.dart';
import 'package:booruflow/features/browse/widgets/post_waterfall.dart';
import 'package:booruflow/features/browse/widgets/rating_filter.dart';
import 'package:booruflow/features/search/inline_search.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// The first destination: the current source's feed as a waterfall, with the
/// source's sections (latest, popular and so on) as tabs in the page header.
class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});
  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage>
    with TickerProviderStateMixin, CollectionActions<BrowsePage> {
  final _search = FrostPageHeaderSearchController();
  TabController? _tabs;
  List<FeedKind> _tabModes = const [];

  // One list per section, created when the section is first shown and kept
  // until the source, the ratings or the section's own request change.
  final _sections = <FeedKind, _Section>{};
  // What each section last showed (a chosen range or date), so switching away
  // from it and back does not reset it.
  final _requests = <FeedKind, FeedCollectionRequest>{};
  String? _sectionsFor;
  int _generation = 0;

  @override
  String get sourceId => ref.read(booruSessionProvider).sourceId;
  FeedCollectionRequest get _feed =>
      ref.read(feedSelectionProvider)[sourceId] ??
      const FeedCollectionRequest();
  PopularProbeKey get _probeKey =>
      (sourceId: sourceId, revision: ref.read(booruSessionProvider).revision);
  bool get _popularAvailable =>
      source.capabilities.discovery.popular ==
          CapabilityAvailability.available ||
      (ref.read(popularProbeProvider(_probeKey)).value?.available ?? false);

  @override
  CollectionKey get collectionKey => CollectionKey(
    sourceId: sourceId,
    request: _feed,
    ratings: ref.read(settingsProvider).ratings,
    revision: ref.read(booruSessionProvider).revision,
  );

  @override
  void dispose() {
    _search.dispose();
    _tabs?.dispose();
    _disposeSections();
    super.dispose();
  }

  void _disposeSections() {
    for (final section in _sections.values) {
      section.source.dispose();
    }
    _sections.clear();
  }

  FeedKind get _selectedMode => _feed.kind == FeedKind.historicalPopular
      ? FeedKind.recentPopular
      : _feed.kind;

  FeedCollectionRequest _defaultRequest(FeedKind kind) {
    final caps = source.capabilities.discovery;
    return FeedCollectionRequest(
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
  }

  FeedCollectionRequest _requestFor(FeedKind mode) =>
      mode == _selectedMode ? _feed : _requests[mode] ?? _defaultRequest(mode);

  CollectionKey _keyFor(FeedKind mode) => CollectionKey(
    sourceId: sourceId,
    request: _requestFor(mode),
    ratings: ref.read(settingsProvider).ratings,
    revision: ref.read(booruSessionProvider).revision,
  );

  /// The list of [mode]'s section; a new one when its request changed.
  _Section _sectionFor(FeedKind mode) {
    final key = _keyFor(mode);
    final existing = _sections[mode];
    if (existing != null && existing.key == key) return existing;
    existing?.source.dispose();
    return _sections[mode] = _Section(
      key,
      PostListSource(key, loader: ref.read(collectionLoaderProvider)),
    );
  }

  void _selectSource(String id) {
    if (_feed.kind != FeedKind.latest &&
        service.sourceById(id).capabilities.discovery.popular ==
            CapabilityAvailability.unsupported) {
      FrostToast.info(t.discovery.latestFallback);
    }
    ref.read(booruSessionProvider.notifier).selectSource(id);
  }

  void _selectMode(FeedKind kind) => ref
      .read(feedSelectionProvider.notifier)
      .select(sourceId, _requests[kind] ?? _defaultRequest(kind));

  Future<void> _chooseDate() async {
    final id = sourceId, current = _feed;
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
                ? _feed.date ??
                      DateTime.now().toUtc().toIso8601String().substring(0, 10)
                : null,
          ),
        );
  }

  List<FrostMenuEntry> _ranges() {
    final caps = source.capabilities.discovery;
    final feed = _feed;
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
          leading: FrostGlyph.icon(appIcons.calendar),
          onSelected: _chooseDate,
        ),
    ];
  }

  /// One tab controller per set of sections; it follows the feed selection and
  /// selects the feed when a tab is chosen.
  TabController _syncTabs(List<FeedKind> modes, int selected) {
    final current = _tabs;
    if (current != null && listEquals(modes, _tabModes)) {
      if (current.index != selected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              identical(_tabs, current) &&
              current.index != selected) {
            current.index = selected;
          }
        });
      }
      return current;
    }
    // The old bar detaches in this frame; dispose once it has.
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    _tabModes = modes;
    final tabs = TabController(
      length: modes.length,
      vsync: this,
      initialIndex: selected,
    );
    tabs.addListener(() {
      final index = tabs.index;
      if (!identical(_tabs, tabs) || index >= _tabModes.length) return;
      final feed = _feed.kind == FeedKind.historicalPopular
          ? FeedKind.recentPopular
          : _feed.kind;
      if (_tabModes[index] != feed) _selectMode(_tabModes[index]);
    });
    return _tabs = tabs;
  }

  @override
  Widget build(BuildContext context) {
    watchBatch();
    ref.watch(booruSessionProvider);
    final ratings = ref.watch(settingsProvider.select((s) => s.ratings));
    ref.watch(feedSelectionProvider);
    final probe = ref.watch(popularProbeProvider(_probeKey));
    final feed = _feed;
    final caps = source.capabilities.discovery;
    final modes = [
      FeedKind.latest,
      if (_popularAvailable) FeedKind.recentPopular,
      ...caps.additionalFeeds,
    ];
    final selectedMode = _selectedMode;
    final identity = [
      sourceId,
      ref.read(booruSessionProvider).revision,
      ratings.join(','),
      modes.join(','),
    ].join('|');
    if (_sectionsFor != identity) {
      _disposeSections();
      _requests.clear();
      _sectionsFor = identity;
    }
    _requests[selectedMode] = feed;
    final range = feed.range;
    final popularSelected = selectedMode == FeedKind.recentPopular;
    final rangeText = range == null
        ? null
        : [
            feed.kind == FeedKind.historicalPopular
                ? historicalRangeLabel(range)
                : rangeLabel(range, caps.timeBasis),
            if (feed.date != null) feed.date!,
          ].join(' · ');
    final sources = ref.watch(booruSourcesProvider);
    final inlineSearch = !FrostShell.titleContentInCaptionOf(context);
    Widget header(PostListSource collection) => FrostPageHeader(
      title: FrostText(t.navigation.browse),
      middle: inlineSearch
          ? InlineSearch(sourceId: sourceId, controller: _search)
          : null,
      searchController: _search,
      leading: [
        FrostTitleMenu(
          title: source.displayName,
          entries: [
            for (final item in sources)
              FrostMenuAction(
                item.displayName,
                checked: item.sourceId == sourceId,
                onSelected: () => _selectSource(item.sourceId),
              ),
          ],
        ),
      ],
      actions: toolbar(
        collection,
        more: [
          if (probe.value?.failedAt != null)
            FrostMenuAction(
              t.generic.retry,
              leading: FrostGlyph.icon(appIcons.refresh),
              onSelected: () =>
                  ref.read(popularProbeProvider(_probeKey).notifier).refresh(),
            ),
        ],
      ),
    );
    if (modes.length == 1) {
      return PostWaterfall(
        collection: (key: collectionKey, loader: null),
        filterBar: const RatingConditions(),
        header: (context, collection) => header(collection),
      );
    }
    final tabs = _syncTabs(
      modes,
      modes.indexOf(selectedMode).clamp(0, modes.length - 1),
    );
    final current = _sectionFor(selectedMode);
    return CallbackShortcuts(
      bindings: {
        for (final activator in const [
          SingleActivator(LogicalKeyboardKey.f5),
          SingleActivator(LogicalKeyboardKey.keyR, control: true),
          SingleActivator(LogicalKeyboardKey.keyR, meta: true),
        ])
          activator: () => _sectionFor(_selectedMode).source.refresh(true),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        // Sections are built once; this scope tells them when the page changed
        // what they should show.
        child: _SectionScope(
          page: this,
          generation: _generation++,
          child: ListenableBuilder(
            listenable: current.source,
            builder: (context, _) => AppSectionPage(
              key: ValueKey(identity),
              header: header(current.source),
              controller: tabs,
              tabs: FrostTabBar(
                controller: tabs,
                scrollable: true,
                tabs: [
                  for (final mode in modes) FrostTab(label: feedLabel(mode)),
                ],
              ),
              trailing: popularSelected && rangeText != null
                  ? FrostMenuAnchor(
                      entries: _ranges(),
                      builder: (context, focus, toggle) => Focus(
                        focusNode: focus,
                        child: FrostButton.plain(
                          label: rangeText,
                          size: FrostControlSize.compact,
                          chevron: FrostButtonChevron.down,
                          onPressed: toggle,
                        ),
                      ),
                    )
                  : null,
              sectionBuilder: (context, index) {
                final mode = modes[index];
                return AppSection(
                  filterBar: const RatingConditions(),
                  onRefresh: () => _sectionFor(mode).source.refresh(),
                  slivers: [_SectionGrid(mode)],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Section {
  _Section(this.key, this.source);
  final CollectionKey key;
  final PostListSource source;
  final waterfall = FrostWaterfallController();
}

/// Rebuilds the sections' grids when the page's state changes.
class _SectionScope extends InheritedWidget {
  const _SectionScope({
    required this.page,
    required this.generation,
    required super.child,
  });
  final _BrowsePageState page;
  final int generation;

  static _BrowsePageState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SectionScope>()!.page;

  @override
  bool updateShouldNotify(_SectionScope oldWidget) => true;
}

/// One section's grid, on whichever list the page currently holds for it.
class _SectionGrid extends StatelessWidget {
  const _SectionGrid(this.mode);
  final FeedKind mode;

  @override
  Widget build(BuildContext context) {
    final section = _SectionScope.of(context)._sectionFor(mode);
    return PostGrid(
      key: ObjectKey(section.source),
      source: section.source,
      controller: section.waterfall,
      collection: section.key,
    );
  }
}
