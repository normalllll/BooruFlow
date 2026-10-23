import 'dart:io';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/posts/media_presentation.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/post_media.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';

/// Restored tasks retain their source identity and use the same injected Rust
/// engine/cache as live post artwork. Resizing never recreates this request.
class DownloadArtwork extends ConsumerStatefulWidget {
  const DownloadArtwork({required this.task, this.decodeWidth, super.key});
  final BooruDownloadItem task;
  final int? decodeWidth;
  @override
  ConsumerState<DownloadArtwork> createState() => _DownloadArtworkState();
}

class _DownloadArtworkState extends ConsumerState<DownloadArtwork> {
  Future<ImageProvider?>? _image;
  @override
  void initState() {
    super.initState();
    _prepare();
    ref.listenManual(
      booruSessionProvider.select((session) => session.revision),
      (_, _) {
        if (mounted) setState(_prepare);
      },
    );
  }

  @override
  void didUpdateWidget(DownloadArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((
          oldWidget.task.sourceId,
          oldWidget.task.postId,
          oldWidget.task.snapshot.thumbnailUrl,
          oldWidget.task.snapshot.localPath,
          oldWidget.decodeWidth,
        ) !=
        (
          widget.task.sourceId,
          widget.task.postId,
          widget.task.snapshot.thumbnailUrl,
          widget.task.snapshot.localPath,
          widget.decodeWidth,
        )) {
      _prepare();
    }
  }

  void _prepare() => _image = _thumbnail(widget.task);

  Future<ImageProvider?> _thumbnail(BooruDownloadItem task) async {
    // Restored tasks need no source login or preview cache when their saved
    // image still exists. Resize the decode, not just the painted thumbnail.
    if (task.snapshot.localPath case final path?
        when {
          MediaType.jpeg,
          MediaType.png,
          MediaType.gif,
          MediaType.webp,
          MediaType.otherImage,
        }.contains(mediaTypeForExtension(path.split('.').last))) {
      final file = File(path);
      if (await file.exists()) {
        return ResizeImage.resizeIfNeeded(
          widget.decodeWidth,
          null,
          FileImage(file),
        );
      }
      if (!mounted) return null;
    }
    final source = task.sourceId,
        post = task.postId,
        url = task.snapshot.thumbnailUrl;
    if (task.post != null || source == null || post == null || url == null) {
      return null;
    }
    return _load(source, post, url);
  }

  Future<ImageProvider?> _load(String source, String post, String url) async {
    final engine = ref.read(booruServiceProvider).engine;
    var media = MediaVariant(kind: MediaVariantKind.preview, url: url);
    if (!postImageDecodable(media)) {
      // Older history could retain a video sample as its thumbnail URL. Recover
      // the image cover from current metadata instead of retrying video bytes.
      final data = Post(await engine.getPost(sourceId: source, postId: post));
      final cover = postImageVariants(data).firstOrNull;
      if (cover == null) return null;
      media = cover;
    }
    final request = await engine.prepareMediaUrl(
      sourceId: source,
      postId: post,
      variant: media.kind,
      url: media.url,
      allowDiskCache: true,
    );
    return RustExtendedNetworkImageProvider(
      request: request,
      mediaStream: (request) => engine.streamMedia(request: request),
      decodeWidth: widget.decodeWidth,
      firstFrameOnly: {
        MediaType.gif,
        MediaType.webp,
      }.contains(postMediaType(media)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
      future: _image,
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.waiting &&
              widget.task.snapshot.localPath == null
          ? FrostMediaFrame.skeleton(aspectRatio: null)
          : snapshot.data == null && widget.task.post != null
          ? PostMedia(post: widget.task.post!, decodeWidth: widget.decodeWidth)
          : snapshot.data == null
          ? FrostMediaFrame(
              child: Center(
                child: FrostIcon(
                  appIcons.image,
                  color: FrostThemeTokens.of(context).textTertiary,
                ),
              ),
            )
          : FrostMediaFrame(image: snapshot.data),
    );
  }
}
