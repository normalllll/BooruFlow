import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Every image subscription has loading and failure UI, even when a previously
/// decoded Hero child remounts after cache eviction. It never fades a sharper
/// frame; the owning media view fades only genuinely different content.
class PostImageFrame extends StatelessWidget {
  const PostImageFrame({
    required this.provider,
    required this.fit,
    this.stream,
    required this.placeholderBuilder,
    required this.errorBuilder,
    super.key,
  });
  final ImageProvider provider;

  /// A page-owned decoded stream, including originals outside ImageCache.
  final ImageStream? stream;
  final BoxFit fit;
  final WidgetBuilder placeholderBuilder;
  final Widget Function(Object error) errorBuilder;
  @override
  Widget build(BuildContext context) => Image(
    image: stream?.completer != null
        ? _StreamImageProvider(stream!.completer!)
        : provider,
    fit: fit,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    frameBuilder: (context, child, frame, _) => frame == null
        ? placeholderBuilder(context)
        : FrostMediaImage(child: child),
    errorBuilder: (_, error, _) => errorBuilder(error),
  );
}

/// Reuses the owner's completer through Flutter's normal Image lifecycle. It
/// never resolves the source again or puts an uncached original into the LRU.
class _StreamImageProvider extends ImageProvider<ImageStreamCompleter> {
  const _StreamImageProvider(this.completer);
  final ImageStreamCompleter completer;

  @override
  Future<ImageStreamCompleter> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(completer);

  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    ImageStreamCompleter key,
    ImageErrorListener handleError,
  ) => stream.setCompleter(key);

  @override
  bool operator ==(Object other) =>
      other is _StreamImageProvider && identical(other.completer, completer);
  @override
  int get hashCode => identityHashCode(completer);
}
