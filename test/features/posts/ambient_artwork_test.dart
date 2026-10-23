import 'package:booruflow/app/ambient_artwork.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/widgets/rust_extended_network_image_provider.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import '../discovery/browse_v2_test.dart' show PendingMediaService, browsePost;
import '../discovery/search_interaction_test.dart' show testSource;

class _Store implements SettingsServiceStore {
  @override
  Map<String, dynamic> load() => {};
  @override
  Future<void> write(String key, dynamic value) async {}
}

MediaRequest request(int id) => MediaRequest(
  sourceId: 'yande',
  postId: '$id',
  variant: MediaVariantKind.sample,
  url: 'https://example.invalid/sample.jpg',
  headers: const [],
  routeKey: 'test',
  cacheKey: 'post-$id',
  authRevision: 0,
  routeRevision: 'test',
  allowDiskCache: true,
);

void main() {
  late PendingMediaService service;
  late ProviderContainer container;
  setUp(() async {
    await SettingsService.initialize(store: _Store());
    service = PendingMediaService()
      ..useSourcesForTesting([testSource('yande')]);
    container = ProviderContainer(
      overrides: [booruServiceProvider.overrideWithValue(service)],
    );
  });
  tearDown(() => container.dispose());

  test(
    'same work retains grid source and does not prepare a larger original for backdrop',
    () async {
      final artwork = container.read(ambientArtworkProvider.notifier);
      const grid = AssetImage('grid-preview');
      await artwork.select(Post(browsePost(1)), preview: grid);
      expect(container.read(ambientArtworkProvider), same(grid));
      await artwork.select(
        Post(browsePost(1)),
        preview: const AssetImage('original-upgrade'),
      );
      expect(container.read(ambientArtworkProvider), same(grid));
      expect(service.mediaEngine.pending, isEmpty);
    },
  );

  test(
    'rapid navigation keeps old source while preparing and publishes only latest small source',
    () async {
      final artwork = container.read(ambientArtworkProvider.notifier);
      const previous = AssetImage('previous-artwork');
      artwork.show(previous);
      final second = artwork.select(Post(browsePost(2)));
      final third = artwork.select(Post(browsePost(3)));
      expect(container.read(ambientArtworkProvider), same(previous));
      service.mediaEngine.pending.first.complete(request(2));
      await second;
      expect(container.read(ambientArtworkProvider), same(previous));
      service.mediaEngine.pending.last.complete(request(3));
      await third;
      final selected =
          container.read(ambientArtworkProvider)
              as RustExtendedNetworkImageProvider;
      expect(selected.request.postId, '3');
      expect(selected.decodeWidth, FrostAmbientBackdropHost.sampleWidth);
      final failed = artwork.select(Post(browsePost(4)));
      service.mediaEngine.pending.last.completeError(
        StateError('optional artwork unavailable'),
      );
      await failed;
      expect(container.read(ambientArtworkProvider), same(selected));
    },
  );
}
