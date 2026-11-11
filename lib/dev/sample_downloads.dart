import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:booruflow/src/rust/api/booru_models.dart';

BooruPost sampleDownloadPost(int index) {
  final (source, id) = switch (index) {
    0 => ('danbooru', 1270269),
    1 => ('yande', 391020),
    2 => ('yande', 391021),
    3 => ('gelbooru', 8812044),
    4 => ('konachan_net', 391020),
    5 => ('danbooru', 1270191),
    6 => ('danbooru', 1268412),
    7 => ('yande', 1102811),
    _ => ('danbooru', 1270000 - index),
  };
  return BooruPost(
    sourceId: source,
    postId: '$id',
    postKey: '$source:$id',
    rating: ContentRating.general,
    tags: const [BooruTag(name: 'Mika_Pikazo', category: TagCategory.artist)],
    media: [
      for (final kind in [MediaVariantKind.sample, MediaVariantKind.original])
        MediaVariant(
          kind: kind,
          url: 'https://sample.invalid/$index.png',
          width: 1200,
          height: 1600,
          mediaType: MediaType.png,
          extension_: 'png',
          byteLengthDecimal: '2726297',
        ),
    ],
    flags: const PostFlags(
      hasChildren: false,
      isPending: false,
      isDeleted: false,
      isAiGenerated: false,
    ),
  );
}

/// A mixed downloads list: a batch with a running and a queued task, a
/// running single, a failure and several saved files.
List<BooruDownloadItem> sampleDownloads() {
  final now = DateTime.now();
  final time = DateTime(now.year, now.month, now.day, 10, 24);
  BooruDownloadItem make(
    int index,
    DownloadStatus status, {
    SaveState save = SaveState.none,
    String? error,
    String? batch,
  }) {
    final post = Post(sampleDownloadPost(index));
    final total = (index == 1 ? 5.1 : 2.6) * 1048576;
    final received = switch (status) {
      DownloadStatus.queued => 0,
      DownloadStatus.downloaded => total.round(),
      _ => (total * (index == 1 ? .61 : .46)).round(),
    };
    return BooruDownloadItem(
      post: post,
      snapshot: DownloadTaskSnapshot(
        id: 'sample-$index',
        resourceId: post.resourceId,
        variantIndex: 0,
        title: '#${post.id}',
        filename: '${post.id}.png',
        sourceId: post.sourceId,
        postId: post.id,
        thumbnailUrl: 'https://sample.invalid/$index.png',
        status: status,
        saveState: save,
        receivedBytes: received,
        totalBytes: total.round(),
        progress: received / total,
        localPath: save == SaveState.saved
            ? 'D:/Pictures/BooruFlow/${post.sourceId}/${post.id}.png'
            : null,
        error: error,
        log: '10:24:00 GET image\n10:24:01 HTTP 200',
        createdAt: time,
        updatedAt: index > 5 ? time.subtract(const Duration(days: 1)) : time,
        batchId: batch,
        batchName: batch == null ? null : 'September favorites',
      ),
    );
  }

  return [
    make(1, DownloadStatus.running, batch: 'september'),
    make(2, DownloadStatus.queued, batch: 'september'),
    make(0, DownloadStatus.running),
    make(3, DownloadStatus.failed, error: 'Connection timed out'),
    for (final i in [4, 5, 6, 7, 8])
      make(i, DownloadStatus.downloaded, save: SaveState.saved),
  ];
}

/// One ugoira download per export format.
List<BooruDownloadItem> sampleUgoiraDownloads() {
  final base = sampleDownloadPost(0);
  final post = Post(
    BooruPost(
      sourceId: 'danbooru',
      postId: '12411796',
      postKey: 'danbooru:12411796',
      rating: ContentRating.general,
      tags: const [],
      media: base.media,
      flags: base.flags,
    ),
  );
  return [
    for (final format in UgoiraExport.values)
      BooruDownloadItem(
        post: post,
        snapshot: DownloadTaskSnapshot(
          id: 'ugoira-${format.name}',
          resourceId: post.resourceId,
          sourceId: post.sourceId,
          postId: post.id,
          variantIndex: 0,
          title: '#12411796',
          filename: format == UgoiraExport.losslessWebp
              ? '12411796.webp'
              : '12411796.zip',
          ugoiraExport: format,
          thumbnailUrl: 'https://sample.invalid/0.png',
          status: DownloadStatus.downloaded,
          saveState: SaveState.saved,
          receivedBytes: 1556758,
          totalBytes: 1556758,
          progress: 1,
          localPath: null,
          error: null,
          log: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
  ];
}

BooruDownloadItem _saved({
  required String id,
  required int resource,
  required String filename,
  required DateTime created,
  required DateTime updated,
  String? batchId,
  String? batchName,
}) => BooruDownloadItem(
  snapshot: DownloadTaskSnapshot(
    id: id,
    resourceId: resource,
    variantIndex: 0,
    title: '#$resource',
    filename: filename,
    status: DownloadStatus.downloaded,
    saveState: SaveState.saved,
    receivedBytes: 1024,
    totalBytes: 1024,
    progress: 1,
    localPath: null,
    error: null,
    log: null,
    createdAt: created,
    updatedAt: updated,
    batchId: batchId,
    batchName: batchName,
  ),
);

/// Three distinct 208-task batches plus singles.
List<BooruDownloadItem> sampleLargeDownloads() {
  final now = DateTime.now();
  return [
    for (var batch = 0; batch < 3; batch++)
      for (var i = 0; i < 208; i++)
        _saved(
          id: 'large-$batch-$i',
          resource: batch * 208 + i,
          filename: '$batch-$i.png',
          created: now,
          updated: now,
          batchId: 'large-$batch',
          batchName: 'muryo ${batch + 1}',
        ),
    for (var i = 0; i < 5; i++)
      _saved(
        id: 'single-$i',
        resource: 1000 + i,
        filename: 'single-$i.png',
        created: now,
        updated: now,
      ),
  ];
}

/// Repeated display names, plus one batch split over dates.
List<BooruDownloadItem> sampleSameNamedDownloads() => [
  for (final (group, batch, day) in [
    (0, 'first', 13),
    (1, 'second', 12),
    (2, 'first', 12),
  ])
    for (var i = 0; i < 2; i++)
      _saved(
        id: 'same-name-$group-$i',
        resource: group * 2 + i,
        filename: '$group-$i.png',
        created: DateTime(2026, 9, 12),
        updated: DateTime(2026, 9, day),
        batchId: batch,
        batchName: 'muryo',
      ),
];

class SampleDownloadItems extends DownloadItems {
  @override
  List<BooruDownloadItem> build() => sampleDownloads();

  List<DownloadTaskSnapshot> get snapshots => [
    for (final item in state) item.snapshot,
  ];

  void append(List<DownloadJob> jobs) {
    state = [
      ...state,
      for (final job in jobs)
        BooruDownloadItem(
          snapshot: DownloadTaskSnapshot(
            id: job.id,
            resourceId: job.resourceId,
            sourceId: job.sourceId,
            postId: job.postId,
            variantIndex: job.variantIndex,
            title: job.title ?? job.filename,
            filename: job.filename,
            status: DownloadStatus.queued,
            saveState: SaveState.none,
            receivedBytes: 0,
            totalBytes: null,
            progress: 0,
            localPath: null,
            error: null,
            log: null,
            createdAt: job.createdAt,
            updatedAt: job.createdAt,
            batchId: job.batchId,
            batchName: job.saveTarget.subdirectory,
          ),
        ),
    ];
  }
}

/// Queues jobs into the sample list; nothing is downloaded.
class SampleDownloadManager implements DownloadManager {
  SampleDownloadManager(this.items);
  final SampleDownloadItems Function() items;
  @override
  Future<int> enqueue(List<DownloadJob> jobs) async {
    items().append(jobs);
    return jobs.length;
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async => [
    for (final task in items().snapshots)
      if ((resourceId == null || task.resourceId == resourceId) &&
          (status == null || task.status == status) &&
          (saveState == null || task.saveState == saveState))
        task,
  ];
  @override
  Future<void> sync() async {}
  @override
  Future<void> pause(String id) async {}
  @override
  Future<void> resume(String id) async {}
  @override
  Future<void> retry(String id) async {}
  @override
  Future<void> retrySave(String id) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Future<void> cancel(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Sample manager: ${invocation.memberName}');
}

class SampleBooruDownloads extends BooruDownloads {
  @override
  Future<void> initialize() async {}
  @override
  void beginBatch(String batchId) {}
  @override
  void endBatch(String batchId) {}
  @override
  Future<DownloadJob> prepare(
    Post post, {
    String? batchId,
    SaveTarget? saveTarget,
  }) async => DownloadJob.create(
    resourceId: post.resourceId,
    sourceId: post.sourceId,
    postId: post.id,
    variantIndex: MediaVariantKind.original.index,
    url: Uri.parse(post.originalMedia.url),
    filename: '${post.id}.png',
    saveTarget: saveTarget!,
    batchId: batchId,
  );
}
