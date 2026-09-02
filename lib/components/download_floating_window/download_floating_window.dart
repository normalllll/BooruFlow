import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yande_gui/components/yande_image/yande_image.dart';
import 'package:yande_gui/downloader/download_task.dart';
import 'package:yande_gui/downloader/downloader.dart';
import 'package:yande_gui/global.dart';
import 'package:yande_gui/intl/translations.g.dart';
import 'package:yande_gui/src/rust/yande/model/post.dart';

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
  static const _collapsedSize = Size.square(56);
  static const _panelMaxWidth = 420.0;
  static const _panelMaxHeight = 430.0;
  static const _edgePadding = 12.0;
  static const _mobileBottomReserve = 74.0;

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
              return StreamBuilder<List<DownloadTask<Post>>>(
                stream: Downloader.instance.taskListStream,
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? Downloader.instance.taskList;
                  if (tasks.isEmpty) return const SizedBox.shrink();

                  final orderedTasks = tasks.reversed.toList(growable: false);
                  final summary = _DownloadSummary.fromTasks(tasks);
                  final size = constraints.biggest;

                  if (_usesDesktopDock(size)) {
                    return _buildDesktopDock(
                      context,
                      size,
                      summary,
                      orderedTasks,
                    );
                  }

                  return _buildMobileWindow(
                    context,
                    constraints,
                    summary,
                    orderedTasks,
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
    BuildContext context,
    Size availableSize,
    _DownloadSummary summary,
    List<DownloadTask<Post>> tasks,
  ) {
    final panelWidth = math.min(
      _panelMaxWidth,
      math.max(0.0, availableSize.width - _desktopRailWidth - 28),
    );
    final panelHeight = math.min(
      _panelMaxHeight,
      math.max(0.0, availableSize.height - 32),
    );

    return Stack(
      children: [
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        Positioned(
          left: (_desktopRailWidth - _collapsedSize.width) / 2,
          bottom: 18,
          width: _collapsedSize.width,
          height: _collapsedSize.height,
          child: _DownloadFloatingButton(
            summary: summary,
            expanded: _expanded,
            onPressed: _toggleExpanded,
          ),
        ),
        if (_expanded && panelWidth >= 180 && panelHeight >= 160)
          Positioned(
            left: _desktopRailWidth + 12,
            bottom: 18,
            width: panelWidth,
            height: panelHeight,
            child: _DownloadPanel(
              summary: summary,
              tasks: tasks,
              onClose: _collapse,
              onRetryAll: Downloader.instance.retryAll,
              onTaskTap: _openTask,
            ),
          ),
      ],
    );
  }

  Widget _buildMobileWindow(
    BuildContext context,
    BoxConstraints constraints,
    _DownloadSummary summary,
    List<DownloadTask<Post>> tasks,
  ) {
    final availableSize = constraints.biggest;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final windowSize = _windowSizeFor(availableSize);
    final position = _clampedPosition(
      _mobilePosition ??
          _defaultMobilePosition(availableSize, windowSize, viewPadding),
      availableSize,
      windowSize,
      viewPadding,
    );

    return Stack(
      children: [
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        Positioned(
          left: position.dx,
          top: position.dy,
          width: windowSize.width,
          height: windowSize.height,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _expanded
                ? _DownloadPanel(
                    key: const ValueKey('download-panel'),
                    summary: summary,
                    tasks: tasks,
                    draggable: true,
                    onDragDelta: (delta) => _moveMobileWindow(
                      delta,
                      availableSize,
                      windowSize,
                      viewPadding,
                    ),
                    onClose: _collapse,
                    onRetryAll: Downloader.instance.retryAll,
                    onTaskTap: _openTask,
                  )
                : _DownloadFloatingButton(
                    key: const ValueKey('download-button'),
                    summary: summary,
                    expanded: false,
                    onDragDelta: (delta) => _moveMobileWindow(
                      delta,
                      availableSize,
                      windowSize,
                      viewPadding,
                    ),
                    onPressed: _toggleExpanded,
                  ),
          ),
        ),
      ],
    );
  }

  bool _usesDesktopDock(Size size) {
    return size.shortestSide >= 600 && size.width >= (isDesktop ? 840 : 900);
  }

  Size _windowSizeFor(Size availableSize) {
    if (!_expanded) return _collapsedSize;
    return Size(
      math.min(
        _panelMaxWidth,
        math.max(0.0, availableSize.width - _edgePadding * 2),
      ),
      math.min(
        _panelMaxHeight,
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
    final bottom = viewPadding.bottom + _edgePadding + _mobileBottomReserve;
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

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  void _collapse() {
    if (_expanded) setState(() => _expanded = false);
  }

  void _openTask(DownloadTask<Post> task) {
    _collapse();
    widget.onTaskTap(task.inner);
  }
}

class _DownloadFloatingButton extends StatelessWidget {
  const _DownloadFloatingButton({
    required this.summary,
    required this.expanded,
    required this.onPressed,
    this.onDragDelta,
    super.key,
  });

  final _DownloadSummary summary;
  final bool expanded;
  final VoidCallback onPressed;
  final ValueChanged<Offset>? onDragDelta;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeCount = summary.failed > 0
        ? summary.failed
        : summary.active > 0
        ? summary.active
        : summary.total;

    return Semantics(
      button: true,
      label: t.downloads.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDragDelta == null
            ? null
            : (details) => onDragDelta!(details.delta),
        onTap: onPressed,
        child: Material(
          color: expanded
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          elevation: expanded ? 4 : 2,
          shadowColor: Colors.black.withValues(alpha: 0.22),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.downloading_outlined,
                    color: expanded
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              PositionedDirectional(
                end: -1,
                top: -1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: summary.failed > 0
                        ? colorScheme.error
                        : colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
    required this.onRetryAll,
    required this.onTaskTap,
    this.draggable = false,
    this.onDragDelta,
    super.key,
  });

  final _DownloadSummary summary;
  final List<DownloadTask<Post>> tasks;
  final bool draggable;
  final ValueChanged<Offset>? onDragDelta;
  final VoidCallback onClose;
  final VoidCallback onRetryAll;
  final ValueChanged<DownloadTask<Post>> onTaskTap;

  @override
  Widget build(BuildContext context) {
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: draggable && onDragDelta != null
                  ? (details) => onDragDelta!(details.delta)
                  : null,
              child: _DownloadPanelHeader(
                summary: summary,
                draggable: draggable,
                onRetryAll: onRetryAll,
                onClose: onClose,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 6),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 54),
                itemBuilder: (context, index) => _CompactDownloadTask(
                  task: tasks[index],
                  onTap: () => onTaskTap(tasks[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadPanelHeader extends StatelessWidget {
  const _DownloadPanelHeader({
    required this.summary,
    required this.draggable,
    required this.onRetryAll,
    required this.onClose,
  });

  final _DownloadSummary summary;
  final bool draggable;
  final VoidCallback onRetryAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = summary.progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (draggable) ...[
              Icon(
                Icons.drag_indicator_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.download_for_offline_outlined,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.downloads.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 8),
            _PanelIconButton(
              icon: Icons.refresh_outlined,
              tooltip: t.generic.retry,
              onTap: onRetryAll,
            ),
            const SizedBox(width: 4),
            _PanelIconButton(
              icon: Icons.close_outlined,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: onClose,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: progress, minHeight: 5),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _SummaryCount(
              icon: Icons.downloading_outlined,
              label: t.downloads.active,
              count: summary.active,
              color: colorScheme.primary,
            ),
            _SummaryCount(
              icon: Icons.download_done_outlined,
              label: t.downloads.completed,
              count: summary.completed,
            ),
            if (summary.failed > 0)
              _SummaryCount(
                icon: Icons.error_outline,
                label: t.downloads.failed,
                count: summary.failed,
                color: colorScheme.error,
              ),
          ],
        ),
      ],
    );
  }
}

class _CompactDownloadTask extends StatelessWidget {
  const _CompactDownloadTask({required this.task, required this.onTap});

  final DownloadTask<Post> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DownloadTaskState>(
      stream: task.stream,
      initialData: task.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? task.state;
        final colorScheme = Theme.of(context).colorScheme;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: YandeImage(
                    task.inner.previewUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusLabel(state.status),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: state.status == DownloadStatus.failed
                                      ? colorScheme.error
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: state.status == DownloadStatus.completed
                              ? 1
                              : state.progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          color: state.status == DownloadStatus.failed
                              ? colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (state.status == DownloadStatus.failed)
                  _PanelIconButton(
                    icon: Icons.refresh_outlined,
                    tooltip: t.generic.retry,
                    onTap: () => Downloader.instance.startTask(task.taskId),
                  )
                else
                  Icon(
                    _statusIcon(state.status),
                    size: 20,
                    color: state.status == DownloadStatus.completed
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 32,
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  const _SummaryCount({
    required this.icon,
    required this.label,
    required this.count,
    this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final valueColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: valueColor),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _DownloadSummary {
  const _DownloadSummary({
    required this.total,
    required this.active,
    required this.completed,
    required this.failed,
    required this.progress,
  });

  factory _DownloadSummary.fromTasks(List<DownloadTask<Post>> tasks) {
    var active = 0;
    var completed = 0;
    var failed = 0;
    var progress = 0.0;

    for (final task in tasks) {
      final state = task.state;
      switch (state.status) {
        case DownloadStatus.idle:
        case DownloadStatus.waiting:
        case DownloadStatus.busying:
          active++;
        case DownloadStatus.completed:
          completed++;
        case DownloadStatus.failed:
          failed++;
      }
      progress += state.status == DownloadStatus.completed
          ? 1
          : state.progress.clamp(0.0, 1.0);
    }

    return _DownloadSummary(
      total: tasks.length,
      active: active,
      completed: completed,
      failed: failed,
      progress: tasks.isEmpty ? 0 : progress / tasks.length,
    );
  }

  final int total;
  final int active;
  final int completed;
  final int failed;
  final double progress;
}

String _statusLabel(DownloadStatus status) {
  return switch (status) {
    DownloadStatus.idle || DownloadStatus.waiting => t.downloads.waiting,
    DownloadStatus.busying => t.downloads.downloading,
    DownloadStatus.completed => t.downloads.completed,
    DownloadStatus.failed => t.downloads.failed,
  };
}

IconData _statusIcon(DownloadStatus status) {
  return switch (status) {
    DownloadStatus.idle => Icons.download_outlined,
    DownloadStatus.waiting => Icons.schedule_outlined,
    DownloadStatus.busying => Icons.downloading_outlined,
    DownloadStatus.completed => Icons.check_circle_outline,
    DownloadStatus.failed => Icons.error_outline,
  };
}
