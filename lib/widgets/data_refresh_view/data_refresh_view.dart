import 'dart:async';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

typedef DataRefreshAction = FutureOr<bool> Function();
typedef DataRefreshViewBuilder =
    Widget Function(
      BuildContext context,
      ScrollPhysics physics,
      Widget sliverHeader,
    );

const dataRefreshPhysics = AlwaysScrollableClampingScrollPhysics();
const dataRefreshScrollBehavior = _DataRefreshScrollBehavior();

class _DataRefreshScrollBehavior extends MaterialScrollBehavior {
  const _DataRefreshScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}

class DataRefreshView extends StatefulWidget {
  const DataRefreshView({
    required this.builder,
    required this.onRefresh,
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;
  final DataRefreshAction onRefresh;
  final DataRefreshViewBuilder builder;

  @override
  State<DataRefreshView> createState() => _DataRefreshViewState();
}

class _DataRefreshViewState extends State<DataRefreshView> {
  late final ScrollController _ownedScrollController = ScrollController();

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _ownedScrollController;

  Future<bool> _handleRefresh() async {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      await SchedulerBinding.instance.endOfFrame;
    }

    try {
      return await Future<bool>.value(widget.onRefresh());
    } catch (error, stackTrace) {
      log('Failed to refresh data view.', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ScrollConfiguration(
      behavior: dataRefreshScrollBehavior,
      child: PrimaryScrollController(
        controller: _effectiveScrollController,
        automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
        child: widget.builder(
          context,
          dataRefreshPhysics,
          const DataRefreshSliverHeader(),
        ),
      ),
    );

    return PullToRefreshNotification(
      color: Theme.of(context).colorScheme.primary,
      maxDragOffset: DataRefreshSliverHeader.maxDragOffset,
      refreshOffset: DataRefreshSliverHeader.refreshOffset,
      reachToRefreshOffset: DataRefreshSliverHeader.reachToRefreshOffset,
      armedDragUpCancel: false,
      pullBackOnRefresh: true,
      pullBackOnError: true,
      onRefresh: _handleRefresh,
      child: child,
    );
  }

  @override
  void dispose() {
    _ownedScrollController.dispose();
    super.dispose();
  }
}

class DataRefreshSliverHeader extends StatelessWidget {
  const DataRefreshSliverHeader({super.key});

  static const refreshOffset = 56.0;
  static const reachToRefreshOffset = 84.0;
  static const maxDragOffset = 120.0;

  @override
  Widget build(BuildContext context) {
    return PullToRefreshContainer((info) {
      final mode = info?.mode;
      final offset = info?.dragOffset ?? 0;
      if ((mode == null || mode == PullToRefreshIndicatorMode.canceled) &&
          offset <= 0) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: SizedBox(
          height: offset.clamp(0, maxDragOffset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: refreshOffset,
              child: Center(child: _RefreshIndicator(info: info)),
            ),
          ),
        ),
      );
    });
  }
}

class _RefreshIndicator extends StatelessWidget {
  const _RefreshIndicator({required this.info});

  final PullToRefreshScrollNotificationInfo? info;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mode = info?.mode;

    return switch (mode) {
      PullToRefreshIndicatorMode.snap ||
      PullToRefreshIndicatorMode.refresh => SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: colorScheme.primary,
        ),
      ),
      PullToRefreshIndicatorMode.done => Icon(
        Icons.check_circle_outline,
        size: 24,
        color: colorScheme.primary,
      ),
      PullToRefreshIndicatorMode.error => Icon(
        Icons.error_outline,
        size: 24,
        color: colorScheme.error,
      ),
      _ => SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          value:
              ((info?.dragOffset ?? 0) /
                      DataRefreshSliverHeader.reachToRefreshOffset)
                  .clamp(0, 1),
          color: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
      ),
    };
  }
}
