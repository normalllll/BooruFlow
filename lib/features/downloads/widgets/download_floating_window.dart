import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:booruflow/core/downloads/download_manager.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/features/downloads/widgets/download_task_widgets.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/booru_download_item.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:booruflow/features/posts/models/post.dart';

class DownloadFloatingWindow extends StatefulWidget {
  const DownloadFloatingWindow({
    required this.child,
    required this.onTaskTap,
    super.key,
  });

  final Widget child;
  final ValueChanged<Post> onTaskTap;

  @override
  State<DownloadFloatingWindow> createState() => _DownloadFloatingWindowState();
}

class _DownloadFloatingWindowState extends State<DownloadFloatingWindow> {
  static const _desktopRailWidth = 96.0;
  static const _desktopButtonSize = 52.0;
  static const _mobileButtonSize = 56.0;
  static const _desktopPanelSize = Size(420, 420);
  static const _mobilePanelMaxWidth = 380.0;
  static const _mobilePanelMaxHeight = 430.0;
  static const _edgePadding = 12.0;
  static const _desktopBottomOffset = 18.0;
  static const _mobileBottomNavigationReserve = 88.0;

  final _sessionStartedAt = DateTime.now();
  final _sessionTaskIds = <String>{};
  Offset? _mobilePosition;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return StreamBuilder<List<BooruDownloadItem>>(
                stream: BooruDownloads.instance.watchItems,
                builder: (context, snapshot) {
                  final tasks =
                      snapshot.data ?? BooruDownloads.instance.currentItems;
                  _rememberSessionTasks(tasks);

                  final panelTasks = [
                    for (final task in tasks)
                      if (_sessionTaskIds.contains(task.snapshot.id)) task,
                  ];
                  final Widget overlay;
                  if (panelTasks.isEmpty) {
                    overlay = const SizedBox.shrink(
                      key: ValueKey<String>('download-overlay-empty'),
                    );
                  } else {
                    final summary = DownloadSummary.fromTasks([
                      for (final task in panelTasks) task.snapshot,
                    ]);
                    overlay = KeyedSubtree(
                      key: const ValueKey<String>('download-overlay-visible'),
                      child: _usesDesktopDock(constraints.biggest)
                          ? _buildDesktopDock(
                              constraints.biggest,
                              summary,
                              panelTasks,
                            )
                          : _buildMobileWindow(
                              context,
                              constraints,
                              summary,
                              panelTasks,
                            ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    reverseDuration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.82,
                            end: 1,
                          ).animate(animation),
                          alignment: Alignment.bottomLeft,
                          child: child,
                        ),
                      );
                    },
                    child: overlay,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopDock(
    Size availableSize,
    DownloadSummary summary,
    List<BooruDownloadItem> tasks,
  ) {
    final panelWidth = math.min(
      _desktopPanelSize.width,
      math.max(0.0, availableSize.width - _desktopRailWidth - 28),
    );
    final panelHeight = math.min(
      _desktopPanelSize.height,
      math.max(0.0, availableSize.height - 32),
    );

    return Stack(
      children: [
        Positioned.fill(
          key: const ValueKey<String>('desktop-download-dismiss-layer'),
          child: IgnorePointer(
            ignoring: !_expanded,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          key: const ValueKey<String>('desktop-download-button'),
          left: 0,
          bottom: _desktopBottomOffset,
          width: _desktopRailWidth,
          child: Center(
            child: _DownloadDockButton(
              summary: summary,
              expanded: _expanded,
              onPressed: _toggleExpanded,
            ),
          ),
        ),
        if (panelWidth >= 180 && panelHeight >= 160)
          Positioned(
            key: const ValueKey<String>('desktop-download-panel'),
            left: _desktopRailWidth + 12,
            bottom: _desktopBottomOffset,
            width: panelWidth,
            height: panelHeight,
            child: IgnorePointer(
              ignoring: !_expanded,
              child: AnimatedOpacity(
                opacity: _expanded ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedSlide(
                  offset: _expanded ? Offset.zero : const Offset(-0.04, 0.03),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _expanded ? 1 : 0.9,
                    alignment: Alignment.bottomLeft,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: _DownloadPanel(
                      summary: summary,
                      tasks: tasks,
                      onClose: _collapse,
                      onSync: () => unawaited(_syncDownloads()),
                      onTaskTap: _openTask,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileWindow(
    BuildContext context,
    BoxConstraints constraints,
    DownloadSummary summary,
    List<BooruDownloadItem> tasks,
  ) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final windowSize = _windowSizeFor(constraints.biggest);
    final position = _clampedPosition(
      _mobilePosition ??
          _defaultMobilePosition(constraints.biggest, windowSize, viewPadding),
      constraints.biggest,
      windowSize,
      viewPadding,
    );

    return Stack(
      children: [
        Positioned.fill(
          key: const ValueKey<String>('mobile-download-dismiss-layer'),
          child: IgnorePointer(
            ignoring: !_expanded,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          key: const ValueKey<String>('mobile-download-window'),
          left: position.dx,
          top: position.dy,
          width: windowSize.width,
          height: windowSize.height,
          child: _DraggableDownloadWindow(
            expanded: _expanded,
            summary: summary,
            tasks: tasks,
            onDragDelta: (delta) => _moveMobileWindow(
              delta,
              constraints.biggest,
              windowSize,
              viewPadding,
            ),
            onToggleExpanded: _toggleExpanded,
            onClose: _collapse,
            onSync: () => unawaited(_syncDownloads()),
            onTaskTap: _openTask,
          ),
        ),
      ],
    );
  }

  bool _usesDesktopDock(Size size) {
    return size.shortestSide >= 600 &&
        size.width >= (AppPlatform.isDesktop ? 840 : 900);
  }

  Size _windowSizeFor(Size availableSize) {
    return Size(
      math.min(
        _mobilePanelMaxWidth,
        math.max(0.0, availableSize.width - _edgePadding * 2),
      ),
      math.min(
        _mobilePanelMaxHeight,
        math.max(0.0, availableSize.height - _edgePadding * 2),
      ),
    );
  }

  Offset _defaultMobilePosition(
    Size availableSize,
    Size windowSize,
    EdgeInsets viewPadding,
  ) {
    final right = viewPadding.right + _edgePadding;
    final bottom =
        viewPadding.bottom + _edgePadding + _mobileBottomNavigationReserve;
    return Offset(
      availableSize.width - windowSize.width - right,
      availableSize.height - windowSize.height - bottom,
    );
  }

  Offset _clampedPosition(
    Offset position,
    Size availableSize,
    Size windowSize,
    EdgeInsets viewPadding,
  ) {
    final minX = viewPadding.left + _edgePadding;
    final minY = viewPadding.top + _edgePadding;
    final maxX = math.max(
      minX,
      availableSize.width - windowSize.width - viewPadding.right - _edgePadding,
    );
    final maxY = math.max(
      minY,
      availableSize.height -
          windowSize.height -
          viewPadding.bottom -
          _edgePadding,
    );
    return Offset(
      position.dx.clamp(minX, maxX).toDouble(),
      position.dy.clamp(minY, maxY).toDouble(),
    );
  }

  void _moveMobileWindow(
    Offset delta,
    Size availableSize,
    Size windowSize,
    EdgeInsets viewPadding,
  ) {
    setState(() {
      final current =
          _mobilePosition ??
          _defaultMobilePosition(availableSize, windowSize, viewPadding);
      _mobilePosition = _clampedPosition(
        current + delta,
        availableSize,
        windowSize,
        viewPadding,
      );
    });
  }

  void _rememberSessionTasks(List<BooruDownloadItem> tasks) {
    for (final item in tasks) {
      final task = item.snapshot;
      if (!task.createdAt.isBefore(_sessionStartedAt) ||
          _isActiveOrNeedsAttention(task)) {
        _sessionTaskIds.add(task.id);
      }
    }
  }

  Future<void> _syncDownloads() async {
    try {
      await downloadManager.sync();
    } catch (error) {
      AppToast.errorWithCause(t.downloads.syncFailed, error);
    }
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  void _collapse() {
    if (_expanded) setState(() => _expanded = false);
  }

  void _openTask(BooruDownloadItem task) {
    final post = task.post;
    if (post == null) return;
    _collapse();
    widget.onTaskTap(post);
  }
}

class _DownloadDockButton extends StatelessWidget {
  const _DownloadDockButton({
    required this.summary,
    required this.expanded,
    required this.onPressed,
  });

  final DownloadSummary summary;
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = _DownloadBadge.fromSummary(summary);

    return Material(
      color: expanded
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      elevation: expanded ? 4 : 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: _DownloadFloatingWindowState._desktopButtonSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    Icons.downloading_outlined,
                    color: expanded
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _DownloadBadgeView(badge: badge),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraggableDownloadWindow extends StatelessWidget {
  const _DraggableDownloadWindow({
    required this.expanded,
    required this.summary,
    required this.tasks,
    required this.onDragDelta,
    required this.onToggleExpanded,
    required this.onClose,
    required this.onSync,
    required this.onTaskTap,
  });

  final bool expanded;
  final DownloadSummary summary;
  final List<BooruDownloadItem> tasks;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClose;
  final VoidCallback onSync;
  final ValueChanged<BooruDownloadItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !expanded,
            child: AnimatedOpacity(
              opacity: expanded ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: expanded ? 1 : 0.82,
                alignment: Alignment.bottomRight,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: _DownloadPanel(
                  summary: summary,
                  tasks: tasks,
                  onDragDelta: onDragDelta,
                  onClose: onClose,
                  onSync: onSync,
                  onTaskTap: onTaskTap,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: 0,
          bottom: 0,
          width: _DownloadFloatingWindowState._mobileButtonSize,
          height: _DownloadFloatingWindowState._mobileButtonSize,
          child: IgnorePointer(
            ignoring: expanded,
            child: AnimatedOpacity(
              opacity: expanded ? 0 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              child: AnimatedScale(
                scale: expanded ? 0.82 : 1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: _MobileDownloadButton(
                  summary: summary,
                  expanded: expanded,
                  onDragDelta: onDragDelta,
                  onPressed: onToggleExpanded,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileDownloadButton extends StatelessWidget {
  const _MobileDownloadButton({
    required this.summary,
    required this.expanded,
    required this.onDragDelta,
    required this.onPressed,
  });

  final DownloadSummary summary;
  final bool expanded;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = _DownloadBadge.fromSummary(summary);

    return GestureDetector(
      onPanUpdate: (details) => onDragDelta(details.delta),
      child: Material(
        color: colorScheme.primaryContainer,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.22),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    Icons.downloading_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              _DownloadBadgeView(badge: badge, offset: -1),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadPanel extends StatelessWidget {
  const _DownloadPanel({
    required this.summary,
    required this.tasks,
    required this.onClose,
    required this.onSync,
    required this.onTaskTap,
    this.onDragDelta,
  });

  final DownloadSummary summary;
  final List<BooruDownloadItem> tasks;
  final ValueChanged<Offset>? onDragDelta;
  final VoidCallback onClose;
  final VoidCallback onSync;
  final ValueChanged<BooruDownloadItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 180 || constraints.maxHeight < 160) {
          return _DownloadPanelFallback(
            summary: summary,
            onDragDelta: onDragDelta,
            onClose: onClose,
          );
        }

        final colorScheme = Theme.of(context).colorScheme;
        return Material(
          elevation: 14,
          color: colorScheme.surface,
          shadowColor: Colors.black.withValues(alpha: 0.24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DownloadPanelHeader(
                  summary: summary,
                  onDragDelta: onDragDelta,
                  onSync: onSync,
                  onClose: onClose,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: DownloadTaskList(
                      tasks: tasks,
                      compact: true,
                      showTooltips: false,
                      onTaskTap: onTaskTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DownloadPanelFallback extends StatelessWidget {
  const _DownloadPanelFallback({
    required this.summary,
    required this.onDragDelta,
    required this.onClose,
  });

  final DownloadSummary summary;
  final ValueChanged<Offset>? onDragDelta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = _DownloadBadge.fromSummary(summary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: onDragDelta == null
          ? null
          : (details) => onDragDelta!(details.delta),
      onTap: onClose,
      child: Material(
        color: colorScheme.primaryContainer,
        shape: const CircleBorder(),
        elevation: 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.downloading_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            _DownloadBadgeView(badge: badge, offset: -1),
          ],
        ),
      ),
    );
  }
}

class _DownloadPanelHeader extends StatelessWidget {
  const _DownloadPanelHeader({
    required this.summary,
    required this.onDragDelta,
    required this.onSync,
    required this.onClose,
  });

  final DownloadSummary summary;
  final ValueChanged<Offset>? onDragDelta;
  final VoidCallback onSync;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.downloads.sync,
          icon: const Icon(Icons.sync_outlined),
          onPressed: onSync,
        ),
        IconButton(
          tooltip: t.downloads.collapse,
          icon: const Icon(Icons.close_outlined),
          onPressed: onClose,
        ),
      ],
    );

    if (onDragDelta == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: DownloadSummaryView(summary: summary, compact: true)),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, bottom: 28),
            child: actions,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 240) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => onDragDelta!(details.delta),
                child: Row(
                  children: [
                    Icon(
                      Icons.drag_indicator_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(fit: BoxFit.scaleDown, child: actions),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DownloadSummaryView(summary: summary, compact: true),
            ],
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => onDragDelta!(details.delta),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.drag_indicator_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DownloadSummaryView(summary: summary, compact: true),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 12,
                  bottom: 28,
                ),
                child: actions,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadBadge {
  const _DownloadBadge({required this.label, required this.hasFailures});

  factory _DownloadBadge.fromSummary(DownloadSummary summary) {
    final active = summary.queued + summary.running + summary.savePending;
    final failures = summary.failed + summary.saveFailed;
    return _DownloadBadge(
      label: failures > 0
          ? '$failures'
          : active > 0
          ? '$active'
          : '${summary.total}',
      hasFailures: failures > 0,
    );
  }

  final String label;
  final bool hasFailures;
}

class _DownloadBadgeView extends StatelessWidget {
  const _DownloadBadgeView({required this.badge, this.offset = -2});

  final _DownloadBadge badge;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PositionedDirectional(
      end: offset,
      top: offset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: badge.hasFailures ? colorScheme.error : colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                badge.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isActiveOrNeedsAttention(DownloadTaskSnapshot task) {
  return task.status == DownloadStatus.queued ||
      task.status == DownloadStatus.running ||
      task.status == DownloadStatus.failed ||
      task.saveState == SaveState.pending ||
      task.saveState == SaveState.saving ||
      task.saveState == SaveState.failed;
}
