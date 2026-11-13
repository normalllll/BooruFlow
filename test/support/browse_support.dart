import 'dart:async';

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/browse/collection_logic.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'frost_app_layers.dart';

/// A Frost app around [child] with a light Windows theme, the shape most widget
/// tests need.
Widget browseTestApp(
  Widget child, {
  double scale = 1,
  Brightness brightness = Brightness.light,
  TargetPlatform platform = TargetPlatform.windows,
  GlobalKey<NavigatorState>? navigatorKey,
}) => TranslationProvider(
  child: ProviderScope(
    child: FrostScope(
      config: appFrostConfig,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: FrostTheme.build(
          config: appFrostConfig,
          brightness: brightness,
          platform: platform,
          locale: const Locale('en'),
        ),
        builder: (context, child) => frostAppLayers(child!),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: FrostLayoutScope(child: child),
          ),
        ),
      ),
    ),
  ),
);

class PendingMediaEngine implements BooruEngine {
  final pending = <Completer<MediaRequest>>[];
  @override
  Future<MediaRequest> prepareMediaUrl({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
    required String url,
    required bool allowDiskCache,
  }) {
    final completer = Completer<MediaRequest>();
    pending.add(completer);
    return completer.future;
  }

  FeedRequest? lastFeed;
  SearchRequest? lastSearch;
  @override
  Future<String> feedWebUrl({required FeedRequest request}) async {
    lastFeed = request;
    return 'https://yande.re/post';
  }

  @override
  Future<String> searchWebUrl({required SearchRequest request}) async {
    lastSearch = request;
    return 'https://yande.re/post?tags=sky';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PendingMediaService extends BooruService {
  final mediaEngine = PendingMediaEngine();
  @override
  BooruEngine get engine => mediaEngine;
}

BooruPost browsePost(int id, {ContentRating rating = ContentRating.general}) =>
    BooruPost(
      sourceId: 'yande',
      postId: '$id',
      postKey: 'yande:$id',
      rating: rating,
      tags: const [],
      media: const [
        MediaVariant(
          kind: MediaVariantKind.sample,
          url: 'https://example.invalid/sample.jpg',
          width: 600,
          height: 800,
        ),
      ],
      webUrl: 'https://yande.re/post/show/$id',
      flags: const PostFlags(
        hasChildren: false,
        isPending: false,
        isDeleted: false,
        isAiGenerated: false,
      ),
    );

CollectionKey collectionKey(int revision) => CollectionKey(
  sourceId: 'yande',
  request: const FeedCollectionRequest(),
  ratings: const [],
  revision: revision,
);
