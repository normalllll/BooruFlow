import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';

class LoadingMoreIndicator extends StatelessWidget {
  final IndicatorStatus status;
  final void Function() errorRefresh;
  final bool isSliver;
  final bool fullScreenErrorCanRetry;

  const LoadingMoreIndicator({
    super.key,
    required this.status,
    required this.errorRefresh,
    this.isSliver = false,
    this.fullScreenErrorCanRetry = false,
  });

  static const textStyle = TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    Widget widget;
    switch (status) {
      case IndicatorStatus.none:
        widget = const SizedBox();
        break;
      case IndicatorStatus.loadingMoreBusying:
        widget = const Center(child: Padding(padding: EdgeInsets.only(top: 10, bottom: 10), child: CupertinoActivityIndicator()));
        break;
      case IndicatorStatus.fullScreenBusying:
        widget = const Center(child: CupertinoActivityIndicator());
        if (isSliver) {
          widget = SliverFillRemaining(child: widget);
        } else {
          widget = CustomScrollView(slivers: <Widget>[SliverFillRemaining(child: widget)]);
        }
        break;
      case IndicatorStatus.error:
        widget = InkWell(onTap: () => errorRefresh(), child: const Center(child: Text('Load failed', style: textStyle)));
        break;
      case IndicatorStatus.fullScreenError:
        widget = SizedBox.expand(
          child:
              fullScreenErrorCanRetry
                  ? InkWell(
                    onTap: () => errorRefresh(),
                    child: Center(child: Text('Load failed${fullScreenErrorCanRetry ? ', click to retry' : ''}', style: textStyle)),
                  )
                  : const Center(child: Text('Load failed', style: textStyle)),
        );

        if (isSliver) {
          widget = SliverFillRemaining(child: widget);
        } else {
          widget = CustomScrollView(slivers: <Widget>[SliverFillRemaining(child: widget)]);
        }
        break;
      case IndicatorStatus.noMoreLoad:
        widget = const Center(child: Padding(padding: EdgeInsets.only(top: 10, bottom: 10), child: Text('No more data', style: textStyle)));
        // widget = const SizedBox();
        break;
      case IndicatorStatus.empty:
        widget = const Center(child: Text('Not found', style: textStyle));
        if (isSliver) {
          widget = SliverFillRemaining(child: widget);
        } else {
          widget = CustomScrollView(slivers: <Widget>[SliverFillRemaining(child: widget)]);
        }
        break;
    }
    return widget;
  }
}
