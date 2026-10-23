import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/settings/settings_service.dart';
import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/src/rust/api/booru_download.dart';
import 'package:booruflow/src/rust/api/booru_engine.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_test/flutter_test.dart';
import '../discovery/search_interaction_test.dart' show testSource;
import '../posts/media_type_presentation_test.dart' show mediaPost, variant;

class _Store implements SettingsServiceStore {
  final values = <String, dynamic>{};
  @override
  Map<String, dynamic> load() => Map.of(values);
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

class _Engine implements BooruEngine {
  _Engine(this.extension);
  String extension;
  @override
  Future<PreparedDownload> prepareDownload({
    required String sourceId,
    required String postId,
    required MediaVariantKind variant,
  }) async => PreparedDownload(
    sourceId: sourceId,
    postId: postId,
    variant: variant,
    url: 'https://cdn.example/original.$extension',
    headers: const [],
    allowedMediaKinds: const [],
    filename: '$postId.$extension',
    expectedBytesDecimal: '100',
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Service extends BooruService {
  _Service(this.value) {
    useSourcesForTesting([testSource('danbooru')]);
  }
  final BooruEngine value;
  @override
  BooruEngine get engine => value;
}

void main() {
  test(
    'single and batch preparation share persisted choice; originals remain originals',
    () async {
      final store = _Store();
      await SettingsService.initialize(store: store);
      expect(SettingsService.ugoiraExport, UgoiraExport.losslessWebp);
      final engine = _Engine('zip');
      final downloads = BooruDownloads(service: _Service(engine));
      final post = mediaPost([variant(MediaVariantKind.original, 'zip')]);
      final webp = await downloads.prepare(post);
      expect(webp.filename, '${post.id}.webp');
      expect(webp.ugoiraExport, UgoiraExport.losslessWebp);
      SettingsService.ugoiraExport = UgoiraExport.originalZip;
      final zip = await downloads.prepare(
        post,
        batchId: 'batch',
        saveTarget: const SaveTarget.downloadsFolder(),
      );
      expect(zip.filename, '${post.id}.zip');
      expect(zip.ugoiraExport, UgoiraExport.originalZip);
      expect(zip.id, isNot(webp.id));
      await SettingsService.initialize(store: store);
      expect(SettingsService.ugoiraExport, UgoiraExport.originalZip);
      for (final ext in ['mp4', 'webm', 'gif', 'png']) {
        engine.extension = ext;
        final original = await downloads.prepare(post);
        expect(original.filename, '${post.id}.$ext');
        expect(original.ugoiraExport, isNull);
      }
      expect(
        webp.ugoiraExport,
        UgoiraExport.losslessWebp,
      ); // later settings do not mutate queued work
    },
  );
}
