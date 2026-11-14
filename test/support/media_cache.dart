import 'dart:io';

import 'package:booruflow/core/media/encoded_media_cache.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:path/path.dart' as path;

/// A cache that keeps its files in [folder].
EncodedMediaCache folderMediaCache(Directory folder) =>
    EncodedMediaCache(store: MediaDiskCache(directory: () async => folder));

/// A cache whose one image is [file], with its proof in `<file>.verified`.
EncodedMediaCache fileMediaCache(File file) => EncodedMediaCache(
  store: MediaDiskCache(
    directory: () async => file.parent,
    fileNameOf: (key) => key.endsWith('.verified')
        ? '${path.basename(file.path)}.verified'
        : path.basename(file.path),
  ),
);
