import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';

// For provider-key assertions and explicitly seeded ImageCache entries only.
// Unexpected network access must fail rather than falling back to a global engine.
Stream<MediaFetchEvent> preseededMedia(MediaRequest request) =>
    throw StateError(
      'A preseeded test image unexpectedly requested transport.',
    );
