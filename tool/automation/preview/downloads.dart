// Deterministic engine snapshots for L boards; never imported by production.
import 'dart:async';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';
import 'package:booruflow/features/downloads/services/booru_downloads.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/src/rust/api/booru_download.dart' show UgoiraExport;
import 'package:booruflow/src/rust/api/booru_models.dart';

BooruPost downloadPreviewPost(int index) {
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
          url: 'https://preview.invalid/$index.png',
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

List<BooruDownloadItem> downloadPreviewItems(
  String board, {
  bool earlier = false,
}) {
  if (board == 'L13') {
    final post = Post(
      BooruPost(
        sourceId: 'danbooru',
        postId: '12411796',
        postKey: 'danbooru:12411796',
        rating: ContentRating.general,
        tags: const [],
        media: downloadPreviewPost(0).media,
        flags: downloadPreviewPost(0).flags,
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
            thumbnailUrl: 'https://preview.invalid/0.png',
            status: DownloadStatus.downloaded,
            saveState: SaveState.saved,
            receivedBytes: format == UgoiraExport.losslessWebp
                ? 1556758
                : 2354861,
            totalBytes: format == UgoiraExport.losslessWebp ? 1556758 : 2354861,
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
  if (board == 'L14') return downloadPreviewItems('L10').take(1).toList();
  if (board == 'L12') return largeDownloadPreviewItems();
  if (board == 'L15') return sameNamedDownloadPreviewItems();
  if (!{'L01', 'L02', 'L03', 'L09', 'L10'}.contains(board)) return [];
  final failedOnly = board == 'L03';
  final now = DateTime.now();
  final time = DateTime(now.year, now.month, now.day, 10, 24);
  BooruDownloadItem make(
    int index,
    DownloadStatus status, {
    SaveState save = SaveState.none,
    String? error,
    String? batch,
  }) {
    final post = Post(downloadPreviewPost(index));
    final total =
        (index == 1
            ? 5.1
            : index == 4
            ? 3.9
            : 2.6) *
        1048576;
    final received = switch (status) {
      DownloadStatus.queued => 0,
      DownloadStatus.downloaded => total.round(),
      _ => (total * (index == 1 ? .61 : .46)).round(),
    };
    final initial = earlier && status == DownloadStatus.running
        ? (received - 512000).clamp(0, received)
        : received;
    return BooruDownloadItem(
      post: post,
      snapshot: DownloadTaskSnapshot(
        id: 'preview-$index',
        resourceId: post.resourceId,
        variantIndex: 0,
        title: '#${post.id}',
        filename: '${post.id}.png',
        sourceId: post.sourceId,
        postId: post.id,
        thumbnailUrl: 'https://preview.invalid/$index.png',
        status: status,
        saveState: save,
        receivedBytes: initial,
        totalBytes: total.round(),
        progress: initial / total,
        localPath: save == SaveState.saved
            ? 'D:/Pictures/BooruFlow/${post.sourceId}/${post.id}.png'
            : null,
        error: error,
        log:
            '10:24:00 GET image\n10:24:01 HTTP 200\n10:24:02 Received $received bytes',
        createdAt: time,
        updatedAt: (index > 5 ? time.subtract(const Duration(days: 1)) : time)
            .add(Duration(seconds: earlier ? 0 : 1)),
        batchId: batch,
        batchName: batch == null ? null : '九月收藏',
      ),
    );
  }

  if (failedOnly) {
    return [
      make(3, DownloadStatus.failed, error: '连接超时'),
      make(6, DownloadStatus.failed, error: '图源拒绝访问此资源'),
      make(
        7,
        DownloadStatus.downloaded,
        save: SaveState.failed,
        error: '保存失败：路径不可写入',
      ),
      for (final i in [0, 1, 2, 4, 5, 8])
        make(i, DownloadStatus.downloaded, save: SaveState.saved),
    ];
  }
  final batch = board == 'L01' || board == 'L02' ? 'september' : null;
  return [
    if (board == 'L09' || board == 'L10') make(0, DownloadStatus.running),
    make(1, DownloadStatus.running, batch: batch),
    make(2, DownloadStatus.queued, batch: batch),
    if (board != 'L09' && board != 'L10') make(0, DownloadStatus.running),
    make(3, DownloadStatus.failed, error: '连接超时'),
    for (final i in [4, 5, 6, 7, 8])
      make(i, DownloadStatus.downloaded, save: SaveState.saved),
  ];
}

class PreviewDownloadItems extends DownloadItems {
  PreviewDownloadItems(this.board);
  final String board;
  @override
  List<BooruDownloadItem> build() {
    // Two genuine timestamped samples exercise the production rate derivation.
    final timer = Timer(
      const Duration(seconds: 2),
      () => state = downloadPreviewItems(board),
    );
    ref.onDispose(timer.cancel);
    return downloadPreviewItems(board, earlier: true);
  }

  List<DownloadTaskSnapshot> get stateForPreview =>
      state.map((item) => item.snapshot).toList();
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

class PreviewDownloadManager implements DownloadManager {
  PreviewDownloadManager(this.items);
  final PreviewDownloadItems Function() items;
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
  }) async => items().stateForPreview
      .where(
        (task) =>
            (resourceId == null || task.resourceId == resourceId) &&
            (status == null || task.status == status) &&
            (saveState == null || task.saveState == saveState),
      )
      .toList();
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
      throw UnsupportedError('Preview manager: ${invocation.memberName}');
}

class PreviewBatchDownloads extends BooruDownloads {
  PreviewBatchDownloads(this.failures);
  final Set<String> failures;
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
  }) async {
    if (failures.remove(post.id)) throw StateError('连接超时');
    return DownloadJob.create(
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
}

/// Three distinct 208-task batches plus singles; no production storage is read.
List<BooruDownloadItem> largeDownloadPreviewItems() {
  final now = DateTime.now();
  return [
    for (var batch = 0; batch < 3; batch++)
      for (var i = 0; i < 208; i++)
        BooruDownloadItem(
          snapshot: DownloadTaskSnapshot(
            id: 'large-$batch-$i',
            resourceId: batch * 208 + i,
            variantIndex: 0,
            title: '#${batch * 208 + i}',
            filename: '$batch-$i.png',
            status: DownloadStatus.downloaded,
            saveState: SaveState.saved,
            receivedBytes: 1024,
            totalBytes: 1024,
            progress: 1,
            localPath: null,
            error: null,
            log: null,
            createdAt: now,
            updatedAt: now,
            batchId: 'large-$batch',
            batchName: 'muryo ${batch + 1}',
          ),
        ),
    for (var i = 0; i < 5; i++)
      BooruDownloadItem(
        snapshot: DownloadTaskSnapshot(
          id: 'single-$i',
          resourceId: 1000 + i,
          variantIndex: 0,
          title: '#${1000 + i}',
          filename: 'single-$i.png',
          status: DownloadStatus.downloaded,
          saveState: SaveState.saved,
          receivedBytes: 1024,
          totalBytes: 1024,
          progress: 1,
          localPath: null,
          error: null,
          log: null,
          createdAt: now,
          updatedAt: now,
        ),
      ),
  ];
}

/// Repeated display names, plus one batch split over dates. No real records.
List<BooruDownloadItem> sameNamedDownloadPreviewItems() => [
  for (final (group, batch, day) in [
    (0, 'first', 13),
    (1, 'second', 12),
    (2, 'first', 12),
  ])
    for (var i = 0; i < 2; i++)
      BooruDownloadItem(
        snapshot: DownloadTaskSnapshot(
          id: 'same-name-$group-$i',
          resourceId: group * 2 + i,
          variantIndex: 0,
          title: '#${group * 2 + i}',
          filename: '$group-$i.png',
          status: DownloadStatus.downloaded,
          saveState: SaveState.saved,
          receivedBytes: 1024,
          totalBytes: 1024,
          progress: 1,
          localPath: null,
          error: null,
          log: null,
          createdAt: DateTime(2026, 9, 12),
          updatedAt: DateTime(2026, 9, day),
          batchId: batch,
          batchName: 'muryo',
        ),
      ),
];
