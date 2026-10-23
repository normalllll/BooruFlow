import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'media_presentation.dart';
import 'models/post.dart';
import 'widgets/rust_extended_network_image_provider.dart';

/// One geometry record for one work, shared by every resolution of that work.
class PostMediaGeometry {
  PostMediaGeometry(Post post)
    : identity = post.postKey,
      _aspectRatio = post.aspectRatio;
  final String identity;
  double _aspectRatio;
  double get aspectRatio => _aspectRatio;
  bool decoded(String identity, double ratio) {
    if (identity != this.identity ||
        !ratio.isFinite ||
        ratio <= 0 ||
        ratio == _aspectRatio) {
      return false;
    }
    _aspectRatio = ratio;
    return true;
  }
}

/// UI-owned image choice shared by a detail stage and the viewer it opens.
/// The open page retains visited streams, including uncached originals, and
/// releases their keep-alive handles on disposal. It owns no transfer or decoder.
class StageImagePresentation extends ChangeNotifier {
  StageImagePresentation({required Post post, ImageProvider? preview})
    : geometry = PostMediaGeometry(post) {
    _preview = preview;
  }
  final PostMediaGeometry geometry;
  ImageProvider? _preview;
  ImageProvider? _frameProvider;
  ImageStream? _frameStream;
  ImageStreamCompleterHandle? _frameHandle;
  Object? _preparationOwner;
  bool preparedBy(Object owner) => identical(owner, _preparationOwner);
  ImageStream? streamFor(ImageProvider provider, Object owner) =>
      preparedBy(owner) && provider == _frameProvider ? _frameStream : null;
  // Retain only the visited member's actual stream for this open page. This is
  // not a global image cache; releasing the page drops every retained handle.
  void retainFrame(
    ImageProvider provider,
    ImageStream stream, {
    required Object preparationOwner,
  }) {
    _preparationOwner = preparationOwner;
    if (identical(_frameStream, stream)) return;
    _frameHandle?.dispose();
    _frameProvider = provider;
    _frameStream = stream;
    _frameHandle = stream.completer?.keepAlive();
  }

  @override
  void dispose() {
    _frameHandle?.dispose();
    _frameStream = null;
    super.dispose();
  }

  String? _readyUrl;
  bool _originalRequested = false;
  bool _failed = false;
  int _revision = 0;
  int? _minimumDecodeWidth, _loadedWidth, _desiredWidth;
  int? get minimumDecodeWidth => _minimumDecodeWidth;
  bool _decodingOriginal = false;
  ImageProvider? get preview => _preview;
  int get revision => _revision;
  bool get originalRequested => _originalRequested;
  MediaVariant? mediaFor(Post post) {
    final stage = postStageMedia(post);
    if (!_originalRequested) return stage;
    final original = post.data.media
        .where(
          (m) => m.kind == MediaVariantKind.original && postImageDecodable(m),
        )
        .firstOrNull;
    // Aliased URLs already contain the original bytes; keep the prepared/cache
    // identity while increasing decode resolution for zoom.
    return original == null || original.url == stage?.url ? stage : original;
  }

  bool canUpgrade(Post post) {
    if (postMediaFormat(post) == PostMediaFormat.video) return false;
    final original = post.data.media
        .where(
          (m) => m.kind == MediaVariantKind.original && postImageDecodable(m),
        )
        .firstOrNull;
    return original != null &&
        original.url != postStageMedia(post)?.url &&
        _readyUrl != original.url;
  }

  bool loadingOriginal(Post post) =>
      _originalRequested && (canUpgrade(post) || _decodingOriginal) && !_failed;
  void requestOriginal(Post post) {
    if (!canUpgrade(post) || loadingOriginal(post)) return;
    if (_originalRequested) _revision++;
    _originalRequested = true;
    _failed = false;
    notifyListeners();
  }

  void requestPixels(Post post, double displayedPixels) {
    _desiredWidth = displayedPixels.ceil();
    final sampleWidth = postStageMedia(post)?.width;
    if (!_originalRequested &&
        sampleWidth != null &&
        displayedPixels > sampleWidth) {
      _minimumDecodeWidth = _desiredWidth;
      requestOriginal(post);
    } else if (_originalRequested &&
        !loadingOriginal(post) &&
        !_failed &&
        _preview is RustExtendedNetworkImageProvider) {
      final provider = _preview! as RustExtendedNetworkImageProvider;
      // A frame narrower than the hint has already reached native resolution.
      final width = _loadedWidth;
      if (width != null &&
          width == provider.decodeWidth &&
          displayedPixels > width &&
          (post.originalMedia.width ?? width + 1) > width) {
        _minimumDecodeWidth = _desiredWidth;
        _decodingOriginal = true;
        _revision++;
        notifyListeners();
      }
    }
  }

  void ready(
    Post post,
    MediaVariant media,
    ImageProvider provider, {
    int? decodedWidth,
  }) {
    if (_readyUrl == media.url &&
        identical(_preview, provider) &&
        !_failed &&
        !loadingOriginal(post)) {
      return;
    }
    _readyUrl = media.url;
    if (post.data.media.any(
      (m) => m.kind == MediaVariantKind.original && m.url == media.url,
    )) {
      _originalRequested = true;
    }
    _preview = provider;
    _loadedWidth = decodedWidth;
    _decodingOriginal = false;
    _failed = _originalRequested && media.url != post.originalMedia.url;
    notifyListeners();
    if (_desiredWidth case final width?) requestPixels(post, width.toDouble());
  }

  void retryStarted() {
    if (!_failed) return;
    _failed = false;
    notifyListeners();
  }

  void failed() {
    if (_failed) return;
    _failed = true;
    notifyListeners();
  }
}
