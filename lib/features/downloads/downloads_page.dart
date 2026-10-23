import 'dart:async';
import 'dart:math' as math;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/core/downloads/download_file_system.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_platform.dart';
import 'package:booruflow/core/settings/logic.dart';
import 'package:booruflow/features/downloads/download_presentation.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/widgets/download_task_inspector.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/downloads/widgets/download_transfer_summary.dart';
import 'package:booruflow/intl/number_format.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_navigation.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:flutter/rendering.dart'
    show MatrixUtils, RenderAbstractViewport, ScrollCacheExtent;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

export 'package:booruflow/features/downloads/download_presentation.dart'
    show DownloadFilter;
export 'package:booruflow/features/downloads/widgets/download_task_inspector.dart';

part 'widgets/download_task_sliver.dart';

const _completionHold = Duration(milliseconds: 600);
const _downloadContentMaxWidth = 920.0;
const _downloadInspectorWidth = 340.0;
// Confirmed batch hierarchy; shared row and thumbnail geometry stays unchanged.
const _batchTaskInset = 40.0;

String _filterLabel(DownloadFilter filter) => switch (filter) {
  DownloadFilter.all => t.downloads.all,
  DownloadFilter.active => t.downloads.active,
  DownloadFilter.failed => t.downloads.failed,
  DownloadFilter.saved => t.downloads.saved,
};
bool _matches(DownloadTaskSnapshot task, DownloadFilter filter) =>
    switch (filter) {
      DownloadFilter.all => true,
      DownloadFilter.active => downloadActive(task),
      DownloadFilter.failed => downloadFailed(task),
      DownloadFilter.saved => task.saveState == SaveState.saved,
    };

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

class _SectionEntry extends _Entry {
  const _SectionEntry(this.id, this.label);
  final String id, label;
  @override
  String get key => 'section:$id';
}

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({this.taskId, this.revealRequest, super.key});
  final String? taskId, revealRequest;
  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  final _sliverCache = <String, (List<Object?>, Widget)>{};
  final _scroll = ScrollController();
  final _revealKeys = <String, GlobalKey>{};
  int _revealGeneration = 0;
  String? _revealedTask;
  // A batch can have visible groups on several dates or in several statuses.
  final _collapsed = <(String, String)>{};
  final _completionTimers = <String, Timer>{};
  final _held = <String, BooruDownloadItem>{};
  late List<BooruDownloadItem> _items;
  late List<_Entry> _entries;
  DownloadFilter _filter = DownloadFilter.all;
  String? _selectedId;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _items = ref.read(downloadItemsProvider);
    _selectedId = widget.taskId;
    _entries = _describe();
    _scheduleReveal();
    ref.listenManual(downloadItemsProvider, (previous, next) {
      final before = {
        for (final item in previous ?? <BooruDownloadItem>[])
          item.snapshot.id: item,
      };
      for (final item in next) {
        final old = before[item.snapshot.id];
        if (old != null &&
            _matches(old.snapshot, _filter) &&
            !_matches(item.snapshot, _filter) &&
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
      if (widget.taskId != null && widget.taskId == _selectedId) {
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
      _selectedId = widget.taskId;
      _revealedTask = null;
      _filter = DownloadFilter.all;
      _sync();
      for (final group in _entries.whereType<_BatchEntry>()) {
        if (group.items.any((item) => item.snapshot.id == _selectedId)) {
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
    if (!_items.any((item) => item.snapshot.id == id)) return;
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(0);
    for (var step = 0; step <= _entries.length; step++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _revealGeneration || !_scroll.hasClients) {
        return;
      }
      final current = _entries
          .whereType<_TaskEntry>()
          .where((entry) => entry.item.snapshot.id == id)
          .firstOrNull;
      final target = _revealKeys[current?.location]?.currentContext;
      if (target != null && target.mounted) {
        _revealedTask = id;
        await Scrollable.ensureVisible(target, alignment: .25);
        return;
      }
      final position = _scroll.position;
      final next = (position.pixels + position.viewportDimension * .8).clamp(
        0.0,
        position.maxScrollExtent,
      );
      if (next == position.pixels) return;
      _scroll.jumpTo(next);
    }
  }

  @override
  void dispose() {
    _revealGeneration++;
    _scroll.dispose();
    for (final timer in _completionTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  List<_Entry> _describe() {
    final visible = _items.where(
      (item) =>
          _matches(item.snapshot, _filter) ||
          _held.containsKey(item.snapshot.id),
    );
    final sections = <String, List<BooruDownloadItem>>{};
    for (final item in visible) {
      final task = item.snapshot, local = task.updatedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final section = downloadActive(task) || _held.containsKey(task.id)
          ? 'active'
          : downloadFailed(task)
          ? 'failed'
          : day.toIso8601String();
      (sections[section] ??= []).add(item);
    }
    final dates =
        sections.keys
            .where((key) => key != 'active' && key != 'failed')
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final result = <_Entry>[];
    for (final section in ['active', 'failed', ...dates]) {
      final items = sections[section];
      if (items == null || items.isEmpty) continue;
      final caption = switch (section) {
        'active' => t.downloads.active,
        'failed' => t.downloads.failed,
        _ => downloadDay(DateTime.parse(section)),
      };
      if (_filter != DownloadFilter.failed) {
        result.add(_SectionEntry(section, caption));
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
          result.add(_BatchEntry(batch, group.value, section));
          previous = null;
        }
        {
          for (final item in group.value) {
            result.add(
              _TaskEntry(
                item,
                section: section,
                nested: batch != null,
                previousId: previous,
              ),
            );
            previous = item.snapshot.id;
          }
        }
      }
    }
    return result;
  }

  void _sync() {
    final previous = {for (final entry in _entries) entry.key: entry};
    _entries = _describe().map((entry) {
      final old = previous[entry.key];
      return switch ((old, entry)) {
        (_TaskEntry a, _TaskEntry b)
            when identical(a.item, b.item) &&
                a.nested == b.nested &&
                a.section == b.section &&
                a.previousId == b.previousId =>
          old!,
        (_SectionEntry a, _SectionEntry b) when a.label == b.label => old!,
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

  List<Widget> _slivers() {
    final used = <String>{};
    Widget cached(
      String key,
      List<Object?> signature,
      Widget Function() build,
    ) {
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

    final result = <Widget>[];
    for (var i = 0; i < _entries.length;) {
      final entry = _entries[i++];
      if (entry is _TaskEntry) {
        final tasks = [entry];
        while (i < _entries.length && _entries[i] is _TaskEntry) {
          tasks.add(_entries[i++] as _TaskEntry);
        }
        result.add(
          cached(
            'single:${entry.key}',
            [
              ...tasks,
              _filter,
              tasks.any((e) => e.item.snapshot.id == _selectedId)
                  ? _selectedId
                  : null,
            ],
            () => _DownloadTaskSliver(
              key: ValueKey('single:${entry.key}'),
              entries: tasks,
              builder: _entry,
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
              child: _entry(entry),
            ),
          ),
        );
        if (entry is _BatchEntry) {
          final tasks = <_TaskEntry>[];
          while (i < _entries.length) {
            final next = _entries[i];
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
              _filter,
              tasks.any((e) => e.item.snapshot.id == _selectedId)
                  ? _selectedId
                  : null,
            ],
            () => _DownloadTaskSliver(
              key: ValueKey('tasks:${entry.key}'),
              entries: tasks,
              builder: _entry,
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
    _sliverCache.removeWhere((key, _) => !used.contains(key));
    return result;
  }

  void _toggleBatch(_BatchEntry entry) => setState(() {
    // The reveal owns only visible geometry; do not jump to the header first.
    // ScrollPosition performs any necessary end-of-content boundary correction.
    if (!_collapsed.add(entry.identity)) _collapsed.remove(entry.identity);
  });

  void _setFilter(DownloadFilter filter) => setState(() {
    _filter = filter;
    _held.clear();
    for (final timer in _completionTimers.values) {
      timer.cancel();
    }
    _completionTimers.clear();
    _sync();
  });
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
    Future<void> Function(DownloadManager, String) action,
  ) => _run((manager) async {
    for (final item in List.of(_items)) {
      if (matches(item.snapshot)) await action(manager, item.snapshot.id);
    }
  });
  Widget _entry(_Entry entry) => switch (entry) {
    _SectionEntry(:final id) => Padding(
      padding: const EdgeInsets.only(
        top: FrostGap.section,
        bottom: FrostGap.inline,
      ),
      child: FrostText(
        switch (id) {
          'active' => t.downloads.active,
          'failed' => t.downloads.failed,
          _ => downloadDay(DateTime.parse(id)),
        },
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
          key: _revealKeys.putIfAbsent(location, GlobalKey.new),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (previousId != null)
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: downloadThumbnailExtent + FrostGap.related,
                ),
                child: FrostDivider(),
              ),
            DownloadTaskTile(
              key: ValueKey(entry.key),
              task: item,
              plainRetry: _filter == DownloadFilter.failed,
              selected: _selectedId == item.snapshot.id,
              onTaskTap: (item) =>
                  setState(() => _selectedId = item.snapshot.id),
            ),
          ],
        ),
      ),
    _BatchEntry batch => _batchHeader(batch),
  };

  Widget _batchHeader(_BatchEntry entry) {
    final items = entry.items;
    final summary = downloadTransferSummary(items, const {});
    final active = summary.count > 0;
    final progress = summary.progress;
    return FrostListRow(
      icon: _collapsed.contains(entry.identity)
          ? appIcons.chevronRight
          : appIcons.chevronDown,
      title: items.first.snapshot.batchName ?? t.downloads.batch,
      subtitle: active
          ? t.downloads.batchProgress(
              completed: formatCount(
                items
                    .where((item) => item.snapshot.saveState == SaveState.saved)
                    .length,
              ),
              total: formatCount(items.length),
            )
          : downloadBatchResult(items),
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
                ] else
                  FrostActivityIndicator(
                    size: FrostControlSize.compact,
                    semanticLabel: t.downloads.active,
                  ),
              ],
            ),
      onPressed: () => _toggleBatch(entry),
    );
  }

  Future<void> _retryFailed() => _run((manager) async {
    for (final item in List.of(_items)) {
      if (!downloadFailed(item.snapshot)) continue;
      if (item.snapshot.saveState == SaveState.failed) {
        await manager.retrySave(item.snapshot.id);
      } else {
        await manager.retry(item.snapshot.id);
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final selected = _items
        .where((item) => item.snapshot.id == _selectedId)
        .firstOrNull;
    final options = [
      for (final filter in DownloadFilter.values)
        FrostPickerOption(
          value: filter,
          label:
              '${_filterLabel(filter)} ${formatCount(_items.where((item) => _matches(item.snapshot, filter)).length)}',
        ),
    ];
    return FrostWindowTitleContribution(
      path: AppRoute.downloads.path,
      page: FrostPageTitle(id: AppRoute.downloads, title: t.downloads.title),
      child: FrostInspector(
        // GoRouter retains inactive branches with tickers disabled. Preserve
        // selection there, but never present its modal inspector over a sibling.
        open: selected != null && TickerMode.valuesOf(context).enabled,
        title: t.downloads.taskDetails,
        sheetDetents: const [FrostSheetDetent.fitted],
        showsSheetCloseButton: false,
        width: _downloadInspectorWidth,
        onOpenChanged: (open) {
          if (!open) setState(() => _selectedId = null);
        },
        inspector: selected == null
            ? const SizedBox.shrink()
            : DownloadTaskInspector(task: selected),
        child: FrostPinnedChrome(
          chrome: FrostContentColumn(
            maxWidth: double.infinity,
            child: FrostPageHeader(
              title: FrostText(t.downloads.title, role: FrostTextRole.headline),
              controls: [
                if (_items.isNotEmpty)
                  FrostToolbarItem.picker<DownloadFilter>(
                    value: _filter,
                    choices: options,
                    label: t.downloads.tasksTitle,
                    onChanged: _setFilter,
                  ),
              ],
              actions: [
                if (_items.isNotEmpty)
                  FrostToolbarItem.action(
                    icon: appIcons.delete,
                    label: t.downloads.clearCompleted,
                    onPressed:
                        _busy ||
                            !_items.any(
                              (item) => downloadCompleted(item.snapshot),
                            )
                        ? null
                        : () => unawaited(
                            _each(
                              downloadCompleted,
                              (manager, id) => manager.deleteTask(id),
                            ),
                          ),
                  ),
                if (_items.isNotEmpty)
                  FrostToolbarItem.menu(
                    label: t.frost.more,
                    icon: appIcons.more,
                    showsLabel: false,
                    entries: [
                      FrostMenuAction(
                        t.downloads.pauseAll,
                        icon: appIcons.pause,
                        onSelected: _busy
                            ? null
                            : () => unawaited(
                                _each(
                                  (task) =>
                                      task.status == DownloadStatus.running ||
                                      task.status == DownloadStatus.queued,
                                  (manager, id) => manager.pause(id),
                                ),
                              ),
                      ),
                      FrostMenuAction(
                        t.downloads.resumeAll,
                        icon: appIcons.play,
                        onSelected: _busy
                            ? null
                            : () => unawaited(
                                _each(
                                  (task) =>
                                      task.status == DownloadStatus.paused,
                                  (manager, id) => manager.resume(id),
                                ),
                              ),
                      ),
                      FrostMenuAction(
                        t.downloads.retryFailed,
                        icon: appIcons.refresh,
                        onSelected: _busy
                            ? null
                            : () => unawaited(
                                _run((manager) async {
                                  for (final item in List.of(_items)) {
                                    if (downloadFailed(item.snapshot)) {
                                      if (item.snapshot.saveState ==
                                          SaveState.failed) {
                                        await manager.retrySave(
                                          item.snapshot.id,
                                        );
                                      } else {
                                        await manager.retry(item.snapshot.id);
                                      }
                                    }
                                  }
                                }),
                              ),
                      ),
                      FrostMenuAction(
                        t.downloads.sync,
                        icon: appIcons.refresh,
                        onSelected: _busy
                            ? null
                            : () =>
                                  unawaited(_run((manager) => manager.sync())),
                      ),
                      if (ref
                          .watch(downloadPlatformProvider)
                          .canRevealDirectory)
                        FrostMenuAction(
                          t.downloads.openDirectory,
                          icon: appIcons.folder,
                          onSelected: () => unawaited(
                            _run((_) async {
                              final directory =
                                  await resolveDesktopDownloadDirectory(
                                    explicitDirectory: ref
                                        .read(settingsProvider)
                                        .downloadPath,
                                  );
                              await revealDownloadPath(
                                directory,
                                directory: true,
                                revealer: ref.read(
                                  downloadPathRevealerProvider,
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          body: CustomScrollView(
            key: const PageStorageKey('downloads-scroll'),
            // Build/decode artwork only inside the viewport, never in an
            // offscreen cache strip while a large saved batch is revealed.
            scrollCacheExtent: const ScrollCacheExtent.pixels(0),
            controller: _scroll,
            slivers: [
              const FrostChromeSpacer(),
              if (_items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FrostEmptyState(
                    icon: appIcons.download,
                    title: t.downloads.noTasks,
                    message: t.downloads.noTasksMessage,
                    actionLabel: t.downloads.browse,
                    onAction: () => context.goNamed(AppRoute.posts.name),
                  ),
                )
              else ...[
                if (_filter == DownloadFilter.failed ||
                    (_filter != DownloadFilter.saved &&
                        _items.any((item) => downloadActive(item.snapshot))))
                  FrostSliverContentColumn(
                    maxWidth: _downloadContentMaxWidth,
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: FrostGap.section),
                        child: DownloadTransferSummary(
                          items: _items,
                          filter: _filter,
                          busy: _busy,
                          onRetryFailed: () => unawaited(_retryFailed()),
                          onPauseAll: () => unawaited(
                            _each(
                              (task) =>
                                  task.status == DownloadStatus.running ||
                                  task.status == DownloadStatus.queued,
                              (manager, id) => manager.pause(id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                FrostSliverContentColumn(
                  maxWidth: _downloadContentMaxWidth,
                  sliver: SliverMainAxisGroup(slivers: _slivers()),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: FrostGap.section),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
