import 'dart:async';
import 'dart:math' as math;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/downloads/download_actions.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/downloads/widgets/download_transfer_summary.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_page.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/rendering.dart'
    show MatrixUtils, RenderAbstractViewport;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

part 'widgets/download_task_sliver.dart';

const _completionHold = Duration(milliseconds: 600);
// Confirmed batch hierarchy; shared row and thumbnail geometry stays unchanged.
const _batchTaskInset = 40.0;
// The two parts of the data: tasks in flight and the ones that are done.
const _activeSection = 0, _completedSection = 1;
// The tabs: everything, then each part on its own.
const _allTab = 0, _activeTab = 1, _completedTab = 2;

class _EntryKey extends ValueKey<String> {
  const _EntryKey(super.value);
}

sealed class _Entry {
  const _Entry();
  String get key;
}

class _TaskEntry extends _Entry {
  const _TaskEntry(
    this.item, {
    required this.section,
    this.nested = false,
    this.previousId,
  });
  final String section;
  String get location => '$section:${item.snapshot.id}';
  final BooruDownloadItem item;
  final bool nested;
  final String? previousId;
  @override
  String get key => 'task:${item.snapshot.id}';
}

class _BatchEntry extends _Entry {
  const _BatchEntry(this.id, this.items, this.section);
  final String id, section;
  final List<BooruDownloadItem> items;
  @override
  String get key => 'batch:$section:$id';
  (String, String) get identity => (section, id);
}

/// The caption of a part of the Active section: its failed tasks, or the rest
/// once failures lead.
class _CaptionEntry extends _Entry {
  const _CaptionEntry(this.id, this.label);
  final String id, label;
  @override
  String get key => 'caption:$id';
}

class _DateEntry extends _Entry {
  const _DateEntry(this.id, this.label);
  final String id, label;
  @override
  String get key => 'date:$id';
}

/// The downloads destination: tasks in flight (failed ones first) and
/// completed ones, each section with its own list. A row expands in place.
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({this.taskId, this.revealRequest, super.key});
  final String? taskId, revealRequest;
  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage>
    with SingleTickerProviderStateMixin {
  final _sliverCache = <String, (List<Object?>, Widget)>{};
  // A key in each section's scroll view, to find its scroll position by.
  final _anchors = [GlobalKey(), GlobalKey(), GlobalKey()];
  final _revealKeys = <String, GlobalKey>{};
  int _revealGeneration = 0, _generation = 0;
  String? _revealedTask;
  // A batch can have visible groups on several dates or in several statuses.
  final _collapsed = <(String, String)>{};
  final _completionTimers = <String, Timer>{};
  final _held = <String, BooruDownloadItem>{};
  late List<BooruDownloadItem> _items;
  late final TabController _tabs;
  final _entries = <List<_Entry>>[[], []];
  String? _expandedId;
  bool _busy = false;

  bool _isActive(DownloadTaskSnapshot task) =>
      downloadActive(task) ||
      downloadFailed(task) ||
      task.status == DownloadStatus.cancelled ||
      _held.containsKey(task.id);
  int _sectionOf(DownloadTaskSnapshot task) =>
      _isActive(task) ? _activeSection : _completedSection;

  @override
  void initState() {
    super.initState();
    _items = ref.read(downloadItemsProvider);
    _expandedId = widget.taskId;
    // All is where the page opens, and where a linked task is revealed.
    _tabs = TabController(length: 3, vsync: this, initialIndex: _allTab)
      ..addListener(() => setState(() {}));
    _sync();
    _scheduleReveal();
    ref.listenManual(downloadItemsProvider, (previous, next) {
      final before = {
        for (final item in previous ?? <BooruDownloadItem>[])
          item.snapshot.id: item,
      };
      for (final item in next) {
        final old = before[item.snapshot.id];
        if (old != null &&
            _isActive(old.snapshot) &&
            !_isActive(item.snapshot) &&
            downloadTaskStatus(item.snapshot) == FrostTaskStatus.completed) {
          _held[item.snapshot.id] = item;
          _completionTimers.remove(item.snapshot.id)?.cancel();
          _completionTimers[item.snapshot.id] = Timer(_completionHold, () {
            _completionTimers.remove(item.snapshot.id);
            if (mounted) {
              setState(() {
                _held.remove(item.snapshot.id);
                _sync();
              });
            }
          });
        }
      }
      if (!mounted) return;
      setState(() {
        _items = next;
        _sync();
      });
      if (widget.taskId != null && widget.taskId == _expandedId) {
        _scheduleReveal();
      }
    });
  }

  @override
  void didUpdateWidget(DownloadsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taskId != null &&
        (widget.taskId != oldWidget.taskId ||
            widget.revealRequest != oldWidget.revealRequest)) {
      _expandedId = widget.taskId;
      _revealedTask = null;
      _sync();
      for (final group in _entries.expand((list) => list)) {
        if (group is _BatchEntry &&
            group.items.any((item) => item.snapshot.id == _expandedId)) {
          _collapsed.remove(group.identity);
        }
      }
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    final id = widget.taskId;
    if (id == null || id == _revealedTask) return;
    final generation = ++_revealGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _revealGeneration) {
        unawaited(_revealTask(id, generation));
      }
    });
  }

  Future<void> _revealTask(String id, int generation) async {
    // Walk actual laid-out viewports for a lazy, variable-height list. No row
    // heights or global screen coordinates are guessed; target geometry wins.
    final item = _items.where((item) => item.snapshot.id == id).firstOrNull;
    if (item == null) return;
    if (_tabs.index != _allTab) _tabs.index = _allTab;
    var jumped = false;
    for (
      var step = 0;
      step <= _entries.expand((list) => list).length + 8;
      step++
    ) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _revealGeneration) return;
      final current = _entries
          .expand((list) => list)
          .whereType<_TaskEntry>()
          .where((entry) => entry.item.snapshot.id == id)
          .firstOrNull;
      final target =
          _revealKeys[_revealKey(_allTab, current?.location)]?.currentContext;
      if (target != null && target.mounted) {
        _revealedTask = id;
        await Scrollable.ensureVisible(target, alignment: .25);
        return;
      }
      final anchor = _anchors[_allTab].currentContext;
      final position = anchor != null && anchor.mounted
          ? Scrollable.maybeOf(anchor)?.position
          : null;
      // The tab is built a frame after it is selected.
      if (position == null) continue;
      if (!jumped) {
        position.jumpTo(0);
        jumped = true;
        continue;
      }
      final next = (position.pixels + position.viewportDimension * .8).clamp(
        0.0,
        position.maxScrollExtent,
      );
      if (next == position.pixels) return;
      position.jumpTo(next);
    }
  }

  @override
  void dispose() {
    _revealGeneration++;
    _tabs.dispose();
    for (final timer in _completionTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  List<_Entry> _describe(int section) {
    final visible = [
      for (final item in _items)
        if (_sectionOf(item.snapshot) == section) item,
    ];
    final buckets = <String, List<BooruDownloadItem>>{};
    if (section == _activeSection) {
      // Failed tasks lead and cancelled ones close; the rest keep their order.
      // Cancelled tasks transfer nothing, so they are not listed as active.
      bool cancelled(BooruDownloadItem item) =>
          item.snapshot.status == DownloadStatus.cancelled &&
          !downloadFailed(item.snapshot);
      buckets['failed'] = [
        for (final item in visible)
          if (downloadFailed(item.snapshot)) item,
      ];
      buckets['active'] = [
        ...visible.where(
          (item) => !downloadFailed(item.snapshot) && !cancelled(item),
        ),
      ];
      buckets['cancelled'] = [...visible.where(cancelled)];
    } else {
      for (final item in visible) {
        final local = item.snapshot.updatedAt.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        (buckets[day.toIso8601String()] ??= []).add(item);
      }
    }
    final dates = section == _activeSection
        ? ['failed', 'active', 'cancelled']
        : (buckets.keys.toList()..sort((a, b) => b.compareTo(a)));
    // The groups are told apart only while there is more than one of them.
    final captioned =
        section == _activeSection &&
        dates.where((bucket) => buckets[bucket]!.isNotEmpty).length > 1;
    final result = <_Entry>[];
    for (final bucket in dates) {
      final items = buckets[bucket]!;
      if (items.isEmpty) continue;
      if (captioned) {
        final count = formatCount(items.length);
        result.add(
          _CaptionEntry(bucket, switch (bucket) {
            'failed' => t.downloads.failedTasks(n: items.length, count: count),
            'cancelled' => t.downloads.cancelledTasks(
              n: items.length,
              count: count,
            ),
            _ => t.downloads.active,
          }),
        );
      }
      if (section == _completedSection) {
        result.add(_DateEntry(bucket, downloadDay(DateTime.parse(bucket))));
      }
      final batches = <String, List<BooruDownloadItem>>{};
      for (final item in items) {
        (batches[item.snapshot.batchId ?? 'single:${item.snapshot.id}'] ??= [])
            .add(item);
      }
      String? previous;
      for (final group in batches.entries) {
        final batch = group.value.first.snapshot.batchId;
        if (batch != null) {
          result.add(_BatchEntry(batch, group.value, bucket));
          previous = null;
        }
        for (final item in group.value) {
          result.add(
            _TaskEntry(
              item,
              section: bucket,
              nested: batch != null,
              previousId: previous,
            ),
          );
          previous = item.snapshot.id;
        }
      }
    }
    return result;
  }

  void _sync() {
    for (final section in [_activeSection, _completedSection]) {
      final previous = {
        for (final entry in _entries[section]) entry.key: entry,
      };
      _entries[section] = _describe(section).map((entry) {
        final old = previous[entry.key];
        return switch ((old, entry)) {
          (_TaskEntry a, _TaskEntry b)
              when identical(a.item, b.item) &&
                  a.nested == b.nested &&
                  a.section == b.section &&
                  a.previousId == b.previousId =>
            old!,
          (_DateEntry a, _DateEntry b) when a.label == b.label => old!,
          (_CaptionEntry a, _CaptionEntry b) when a.label == b.label => old!,
          (_BatchEntry a, _BatchEntry b)
              when a.items.length == b.items.length &&
                  List.generate(
                    a.items.length,
                    (i) => identical(a.items[i], b.items[i]),
                  ).every((same) => same) =>
            old!,
          _ => entry,
        };
      }).toList();
    }
  }

  String _revealKey(int tab, String? location) => '$tab/$location';

  /// The slivers of one tab, from the page's current state. All holds the
  /// active part and then the completed part, each as it shows in its own tab.
  List<Widget> _slivers(int tab) {
    final sections = switch (tab) {
      _allTab => const [_activeSection, _completedSection],
      _activeTab => const [_activeSection],
      _ => const [_completedSection],
    };
    final used = <String>{};
    Widget cached(
      String key,
      List<Object?> signature,
      Widget Function() build,
    ) {
      key = '$tab/$key';
      used.add(key);
      signature = [Translations.of(context), ...signature];
      final old = _sliverCache[key];
      if (old != null &&
          old.$1.length == signature.length &&
          List.generate(
            signature.length,
            (i) => old.$1[i] == signature[i],
          ).every((same) => same)) {
        return old.$2;
      }
      final child = build();
      _sliverCache[key] = (signature, child);
      return child;
    }

    final result = <Widget>[
      SliverToBoxAdapter(child: SizedBox.shrink(key: _anchors[tab])),
    ];
    if (sections.every((section) => _entries[section].isEmpty)) {
      final active = tab != _completedTab;
      result.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: FrostEmptyState(
            icon: active ? appIcons.check : appIcons.download,
            title: active ? t.downloads.noActive : t.downloads.noCompleted,
            message: active ? null : t.downloads.noTasksMessage,
          ),
        ),
      );
      return result;
    }
    for (final section in sections) {
      if (_entries[section].isEmpty) continue;
      if (section == _activeSection) {
        result.add(
          SliverToBoxAdapter(child: DownloadTransferSummary(items: _items)),
        );
      }
      _addSection(tab, section, result, cached);
    }
    result.add(
      const SliverToBoxAdapter(child: SizedBox(height: FrostGap.section)),
    );
    _sliverCache.removeWhere(
      (key, _) => key.startsWith('$tab/') && !used.contains(key),
    );
    return result;
  }

  /// Adds the slivers of one part of the data to [result], for [tab].
  void _addSection(
    int tab,
    int section,
    List<Widget> result,
    Widget Function(String, List<Object?>, Widget Function()) cached,
  ) {
    final entries = _entries[section];
    for (var i = 0; i < entries.length;) {
      final entry = entries[i++];
      if (entry is _TaskEntry) {
        final tasks = [entry];
        while (i < entries.length && entries[i] is _TaskEntry) {
          tasks.add(entries[i++] as _TaskEntry);
        }
        result.add(
          cached(
            'single:${entry.key}',
            [
              ...tasks,
              tasks.any((e) => e.item.snapshot.id == _expandedId)
                  ? _expandedId
                  : null,
            ],
            () => _DownloadTaskSliver(
              key: ValueKey('single:$section:${entry.key}'),
              entries: tasks,
              builder: (entry) => _entry(entry, tab),
            ),
          ),
        );
      } else {
        result.add(
          cached(
            entry.key,
            [
              entry,
              if (entry is _BatchEntry) _collapsed.contains(entry.identity),
            ],
            () => SliverToBoxAdapter(
              key: ValueKey(entry.key),
              child: _entry(entry, tab),
            ),
          ),
        );
        if (entry is _BatchEntry) {
          final tasks = <_TaskEntry>[];
          while (i < entries.length) {
            final next = entries[i];
            if (next is! _TaskEntry || next.item.snapshot.batchId != entry.id) {
              break;
            }
            tasks.add(next);
            i++;
          }
          final list = cached(
            'tasks:${entry.key}',
            [
              ...tasks,
              tasks.any((e) => e.item.snapshot.id == _expandedId)
                  ? _expandedId
                  : null,
            ],
            () => _DownloadTaskSliver(
              key: ValueKey('tasks:${entry.key}'),
              entries: tasks,
              builder: (entry) => _entry(entry, tab),
            ),
          );
          result.add(
            FrostSliverExpand(
              key: ValueKey('expand:${entry.key}'),
              expanded: !_collapsed.contains(entry.identity),
              sliver: list,
            ),
          );
        }
      }
    }
  }

  void _toggleBatch(_BatchEntry entry) => setState(() {
    // The reveal owns only visible geometry; do not jump to the header first.
    // ScrollPosition performs any necessary end-of-content boundary correction.
    if (!_collapsed.add(entry.identity)) _collapsed.remove(entry.identity);
  });

  void _toggleTask(BooruDownloadItem item) => setState(
    () =>
        _expandedId = _expandedId == item.snapshot.id ? null : item.snapshot.id,
  );

  Future<void> _run(
    Future<void> Function(DownloadManager manager) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(downloadManagerProvider));
    } catch (error) {
      if (mounted) AppToast.errorWithCause(t.downloads.actionFailed, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _each(
    bool Function(DownloadTaskSnapshot) matches,
    Future<void> Function(DownloadManager, DownloadTaskSnapshot) action,
  ) => _run((manager) => eachDownload(manager, _items, matches, action));

  bool _running(DownloadTaskSnapshot task) =>
      task.status == DownloadStatus.running ||
      task.status == DownloadStatus.queued;

  Future<void> _pauseAll() =>
      _each(_running, (manager, task) => manager.pause(task.id));
  Future<void> _resumeAll() => _each(
    (task) => task.status == DownloadStatus.paused,
    (manager, task) => manager.resume(task.id),
  );
  Future<void> _retryFailed() =>
      _run((manager) => retryFailedDownloads(manager, _items));
  Future<void> _clearCompleted() =>
      _run((manager) => clearCompletedDownloads(manager, _items));

  Widget _entry(_Entry entry, int tab) => switch (entry) {
    _CaptionEntry(:final id, :final label) => Padding(
      padding: EdgeInsets.only(
        top: id == 'failed' ? FrostGap.group : FrostGap.section,
        bottom: FrostGap.inline,
      ),
      child: FrostText(
        label,
        role: FrostTextRole.footnote,
        tone: FrostTextTone.secondary,
      ),
    ),
    _DateEntry(:final id) => Padding(
      padding: EdgeInsets.only(
        // The first day leads the page, unless tasks in flight come first.
        top:
            _entries[_completedSection].first == entry &&
                (tab == _completedTab || _entries[_activeSection].isEmpty)
            ? FrostGap.group
            : FrostGap.section,
        bottom: FrostGap.inline,
      ),
      child: FrostText(
        downloadDay(DateTime.parse(id)),
        role: FrostTextRole.footnote,
        tone: FrostTextTone.secondary,
      ),
    ),
    _TaskEntry(
      :final item,
      :final nested,
      :final previousId,
      :final location,
    ) =>
      Padding(
        padding: EdgeInsetsDirectional.only(
          start: nested ? _batchTaskInset : 0,
        ),
        child: Column(
          key: _revealKeys.putIfAbsent(
            _revealKey(tab, location),
            GlobalKey.new,
          ),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (previousId != null)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: downloadTextColumn),
                child: FrostDivider(),
              ),
            DownloadTaskTile(
              key: ValueKey(entry.key),
              task: item,
              expanded: _expandedId == item.snapshot.id,
              onTaskTap: _toggleTask,
            ),
          ],
        ),
      ),
    _BatchEntry batch => _batchHeader(batch),
  };

  Widget _batchHeader(_BatchEntry entry) {
    final items = entry.items;
    // Tasks that finish move to the other section but stay part of the batch.
    final batch = _items.where((item) => item.snapshot.batchId == entry.id);
    final summary = downloadTransferSummary(
      items,
      const {},
      finished: batch.where((item) => downloadCompleted(item.snapshot)),
    );
    final active = summary.count > 0;
    final progress = summary.progress;
    return FrostListRow(
      leading: FrostGlyph.icon(
        _collapsed.contains(entry.identity)
            ? appIcons.chevronRight
            : appIcons.chevronDown,
      ),
      title: items.first.snapshot.batchName ?? t.downloads.batch,
      subtitle: FrostRowSubtitle(
        active
            ? t.downloads.batchProgress(
                completed: formatCount(
                  batch
                      .where(
                        (item) => item.snapshot.saveState == SaveState.saved,
                      )
                      .length,
                ),
                total: formatCount(batch.length),
              )
            : downloadBatchResult(items),
      ),
      trailing: !active
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress != null) ...[
                  FrostProgressRing(
                    value: progress,
                    size: FrostControlSize.compact,
                    semanticLabel: t.downloads.active,
                  ),
                  const SizedBox(width: FrostGap.related),
                  FrostText(
                    '${(progress * 100).round()}%',
                    role: FrostTextRole.footnote,
                    tone: FrostTextTone.tertiary,
                    numeric: true,
                  ),
                ] else if (summary.transferring)
                  FrostActivityIndicator(
                    size: FrostControlSize.compact,
                    semanticLabel: t.downloads.active,
                  ),
              ],
            ),
      onPressed: () => _toggleBatch(entry),
    );
  }

  /// A labelled header button that moves into the more menu when the row
  /// is short of room.
  FrostToolbarItem _batchAction({
    required FrostIconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: FrostTypography.of(context).style(FrostTextRole.callout),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width =
        text.width +
        FrostControlSize.compact.iconSize +
        FrostGap.related +
        2 * FrostGap.group;
    text.dispose();
    return FrostToolbarItem.custom(
      minWidth: width,
      priority: FrostToolbarPriority.high,
      overflowEntry: FrostMenuAction(
        label,
        leading: FrostGlyph.icon(icon),
        onSelected: onPressed,
      ),
      builder: (_) => FrostButton.plain(
        label: label,
        icon: icon,
        size: FrostControlSize.compact,
        onPressed: onPressed,
      ),
    );
  }

  FrostPageHeader _header() {
    final hasTasks = _items.isNotEmpty;
    final running = _items.any((item) => _running(item.snapshot));
    final paused = _items.any(
      (item) => item.snapshot.status == DownloadStatus.paused,
    );
    final resume = !running && paused;
    final anyFailed = _items.any((item) => downloadFailed(item.snapshot));
    final anyCompleted = _items.any((item) => downloadCompleted(item.snapshot));
    return FrostPageHeader(
      title: FrostText(t.downloads.title),
      actions: [
        if (hasTasks) ...[
          _batchAction(
            icon: resume ? appIcons.play : appIcons.pause,
            label: resume ? t.downloads.resumeAll : t.downloads.pauseAll,
            onPressed: _busy || !(running || paused)
                ? null
                : () => unawaited(resume ? _resumeAll() : _pauseAll()),
          ),
          FrostToolbarItem.menu(
            label: t.frost.more,
            icon: appIcons.more,
            showsLabel: false,
            entries: [
              FrostMenuAction(
                t.downloads.retryFailed,
                leading: FrostGlyph.icon(appIcons.refresh),
                onSelected: _busy || !anyFailed
                    ? null
                    : () => unawaited(_retryFailed()),
              ),
              FrostMenuAction(
                t.downloads.clearCompleted,
                leading: FrostGlyph.icon(appIcons.delete),
                onSelected: _busy || !anyCompleted
                    ? null
                    : () => unawaited(_clearCompleted()),
              ),
              FrostMenuAction(
                t.downloads.sync,
                leading: FrostGlyph.icon(appIcons.refresh),
                onSelected: _busy
                    ? null
                    : () => unawaited(_run((manager) => manager.sync())),
              ),
              if (ref.watch(downloadPlatformProvider).canRevealDirectory)
                FrostMenuAction(
                  t.downloads.openDirectory,
                  leading: FrostGlyph.icon(appIcons.folder),
                  onSelected: () => unawaited(
                    _run((_) async {
                      final directory = await resolveDesktopDownloadDirectory(
                        explicitDirectory: ref
                            .read(settingsProvider)
                            .downloadPath,
                      );
                      await revealDownloadPath(
                        directory,
                        directory: true,
                        revealer: ref.read(downloadPathRevealerProvider),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return AppPage(
        isEmpty: true,
        empty: FrostEmptyState(
          icon: appIcons.download,
          title: t.downloads.noTasks,
          message: t.downloads.noTasksMessage,
          actionLabel: t.downloads.browse,
          onAction: () => context.goNamed(AppRoute.posts.name),
        ),
        header: _header(),
        slivers: const [],
      );
    }
    String count(int? section) => formatCount(
      section == null
          ? _items.length
          : _items.where((item) => _sectionOf(item.snapshot) == section).length,
    );
    return _DownloadsScope(
      page: this,
      generation: _generation++,
      child: AppSectionPage(
        header: _header(),
        controller: _tabs,
        tabs: FrostTabBar(
          controller: _tabs,
          scrollable: true,
          tabs: [
            FrostTab(label: t.downloads.all, secondaryLabel: count(null)),
            FrostTab(
              label: t.downloads.active,
              secondaryLabel: count(_activeSection),
            ),
            FrostTab(
              label: t.downloads.completed,
              secondaryLabel: count(_completedSection),
            ),
          ],
        ),
        sectionBuilder: (context, index) =>
            AppSection(slivers: [_SectionBody(index)]),
      ),
    );
  }
}

/// Rebuilds the sections' lists when the page's state changes; the layout
/// builds each section once.
class _DownloadsScope extends InheritedWidget {
  const _DownloadsScope({
    required this.page,
    required this.generation,
    required super.child,
  });
  final _DownloadsPageState page;
  final int generation;

  static _DownloadsPageState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DownloadsScope>()!.page;

  @override
  bool updateShouldNotify(_DownloadsScope oldWidget) => true;
}

class _SectionBody extends StatelessWidget {
  const _SectionBody(this.tab);
  final int tab;

  @override
  Widget build(BuildContext context) =>
      SliverMainAxisGroup(slivers: _DownloadsScope.of(context)._slivers(tab));
}
