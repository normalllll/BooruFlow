part of '../downloads_page.dart';

/// Only genuine data insertions/removals animate individual tasks. Batch
/// visibility belongs to the surrounding FrostSliverExpand, never to 208 rows.
class _DownloadTaskSliver extends StatefulWidget {
  const _DownloadTaskSliver({
    required this.entries,
    required this.builder,
    super.key,
  });
  final List<_TaskEntry> entries;
  final Widget Function(_Entry) builder;
  @override
  State<_DownloadTaskSliver> createState() => _DownloadTaskSliverState();
}

class _DownloadTaskSliverState extends State<_DownloadTaskSliver> {
  final _list = GlobalKey<SliverAnimatedListState>();
  late final List<_TaskEntry> _entries = List.of(widget.entries);
  late Map<String, int> _indices = _index();
  Map<String, int> _index() => {
    for (final (i, e) in _entries.indexed) e.key: i,
  };
  @override
  void didUpdateWidget(_DownloadTaskSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.entries;
    final keys = next.map((e) => e.key).toSet();
    final duration = FrostMotion.duration(
      context,
      FrostMotion.standardDuration,
    );
    for (var i = _entries.length - 1; i >= 0; i--) {
      if (!keys.contains(_entries[i].key)) {
        final old = _entries.removeAt(i);
        _list.currentState?.removeItem(
          i,
          (_, animation) => _transition(animation, widget.builder(old)),
          duration: duration,
        );
      }
    }
    for (var i = 0; i < next.length; i++) {
      if (i < _entries.length && _entries[i].key == next[i].key) {
        _entries[i] = next[i];
      } else {
        final oldIndex = _entries.indexWhere((e) => e.key == next[i].key);
        if (oldIndex >= 0) {
          final old = _entries.removeAt(oldIndex);
          _list.currentState?.removeItem(
            oldIndex,
            (_, animation) => _transition(animation, widget.builder(old)),
            duration: duration,
          );
        }
        _entries.insert(i, next[i]);
        _list.currentState?.insertItem(i, duration: duration);
      }
    }
    _indices = _index();
  }

  Widget _transition(Animation<double> animation, Widget child) {
    final extent = animation.drive(
      CurveTween(
        curve: FrostSpringCurve(
          FrostMotion.standard,
          FrostMotion.standardDuration,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: extent,
      child: FadeTransition(opacity: animation, child: child),
      builder: (context, child) => ClipRect(
        // A settled lazy row must retain the shared keyline's full ink/hit
        // bounds. Only insertion/removal clips the changing vertical extent.
        clipBehavior: animation.isCompleted ? Clip.none : Clip.hardEdge,
        clipper: _TaskRevealClipper(context),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: extent.value,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SliverAnimatedList(
    key: _list,
    initialItemCount: _entries.length,
    findChildIndexCallback: (key) =>
        key is _EntryKey ? _indices[key.value] : null,
    itemBuilder: (context, index, animation) => KeyedSubtree(
      key: _EntryKey(_entries[index].key),
      child: _transition(animation, widget.builder(_entries[index])),
    ),
  );
}

/// An inserted/removed row shares the sliver reveal's vertical-only clip. Its
/// legal horizontal paint is limited by the viewport, never the text column.
class _TaskRevealClipper extends CustomClipper<Rect> {
  const _TaskRevealClipper(this.context);
  final BuildContext context;
  @override
  Rect getClip(Size size) {
    final object = context.findRenderObject()!;
    final viewport = RenderAbstractViewport.of(object);
    final bounds = MatrixUtils.transformRect(
      viewport.getTransformTo(object),
      viewport.paintBounds,
    );
    return Rect.fromLTRB(
      math.min(0, bounds.left),
      0,
      math.max(size.width, bounds.right),
      size.height,
    );
  }

  @override
  bool shouldReclip(_TaskRevealClipper oldClipper) => true;
}
