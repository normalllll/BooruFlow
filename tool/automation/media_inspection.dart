// Read-only diagnostics of real widgets/providers. No requests or state writes.
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/post_media_recovery.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

Map<String, Object?> _provider(ImageProvider? provider) => switch (provider) {
  RustExtendedNetworkImageProvider(
    :final request,
    :final decodeWidth,
    :final firstFrameOnly,
  ) =>
    {
      'type': 'RustExtendedNetworkImageProvider',
      'variant': request.variant.name,
      'url': Uri.parse(request.url).replace(query: '', fragment: '').toString(),
      'decodeWidth': decodeWidth,
      'firstFrameOnly': firstFrameOnly,
    },
  null => {'type': null},
  _ => {'type': provider.runtimeType.toString()},
};

List<Map<String, Object?>> inspectMedia(Element root) {
  final result = <Map<String, Object?>>[];
  void visit(Element element) {
    if (element.widget case final PostMedia media) {
      final variant =
          media.media ??
          media.presentation?.mediaFor(media.post) ??
          postImageVariants(media.post, purpose: media.purpose).firstOrNull;
      final images = <Map<String, Object?>>[];
      final errors = <String>[];
      void image(Element child) {
        if (child.widget case PostMediaRecovery(
          error: final MediaImageException error,
        )) {
          errors.add(error.toString());
        }
        if (child.widget case Image(:final image)) {
          final status = PaintingBinding.instance.imageCache.statusForKey(
            image,
          );
          images.add({
            ..._provider(image),
            'cache': {
              'pending': status.pending,
              'live': status.live,
              'keepAlive': status.keepAlive,
            },
          });
        }
        if (child.widget case RawImage(:final image?)) {
          var opacity = 1.0, offstage = false;
          for (
            RenderObject? object = child.findRenderObject();
            object != null;
            object = object.parent
          ) {
            if (object is RenderOffstage && object.offstage) offstage = true;
            if (object is RenderOpacity) opacity *= object.opacity;
            if (object is RenderAnimatedOpacity) {
              opacity *= object.opacity.value;
            }
          }
          images.add({
            'pixels': [image.width, image.height],
            'offstage': offstage,
            'opacity': opacity,
          });
        }
        child.visitChildren(image);
      }

      element.visitChildren(image);
      final box = element.findRenderObject();
      result.add({
        if (box is RenderBox && box.hasSize)
          'rect': {
            'x': box.localToGlobal(Offset.zero).dx,
            'y': box.localToGlobal(Offset.zero).dy,
            'width': box.size.width,
            'height': box.size.height,
          },
        'post': media.post.postKey,
        'relatedStrip':
            element.findAncestorWidgetOfExactType<FrostThumbnailStrip>() !=
            null,
        'parent': media.post.parentId,
        'hasChildren': media.post.hasChildren,
        'metadataRatio': media.post.aspectRatio,
        if (media.presentation != null)
          'stageRatio': media.presentation!.geometry.aspectRatio,
        'requested': variant?.kind.name,
        'purpose': media.purpose.name,
        'mediaType': variant?.mediaType?.name,
        'url': variant == null
            ? null
            : Uri.parse(
                variant.url,
              ).replace(query: '', fragment: '').toString(),
        'decodeWidth': media.decodeWidth,
        'state': element is StatefulElement
            ? element.state.toDiagnosticsNode().toStringDeep()
            : null,
        'images': images,
        if (errors.isNotEmpty) 'errors': errors,
      });
    }
    element.visitChildren(visit);
  }

  visit(root);
  return result;
}
