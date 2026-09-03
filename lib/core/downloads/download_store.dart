import 'dart:convert';

import 'package:drift/drift.dart';

import 'download_database.dart' hide DownloadJob;
import 'download_engine.dart';
import 'download_models.dart';

abstract interface class DownloadStore {
  Future<void> upsertJob(DownloadJob job);

  Future<void> updateProgress(
    String jobId, {
    int? receivedBytes,
    int? totalBytes,
    double? progress,
  });

  Future<void> updateStatus(
    String jobId,
    DownloadStatus status, {
    String? error,
  });

  Future<void> updateSaveState(
    String jobId,
    SaveState state, {
    String? localPath,
    String? galleryAssetId,
    String? error,
  });

  Future<void> appendLog(String jobId, String message);

  Future<void> applyEngineSnapshot(DownloadEngineSnapshot snapshot);

  Future<DownloadTaskSnapshot?> getTask(String jobId);

  Future<DownloadJob?> getJob(String jobId);

  Future<void> deleteTask(String jobId);

  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  });

  Stream<List<DownloadTaskSnapshot>> watchTasks({int? resourceId});

  Stream<DownloadTaskSnapshot?> watchTask(String jobId);

  Stream<DownloadSummary> watchSummary({int? resourceId});

  Future<List<DownloadTaskSnapshot>> listPendingSaveTasks();

  Future<List<DownloadTaskSnapshot>> listRecoverableTasks();

  Future<void> close();
}

class DriftDownloadStore implements DownloadStore {
  DriftDownloadStore(this._db);

  factory DriftDownloadStore.open() {
    return DriftDownloadStore(DownloadDatabase());
  }

  final DownloadDatabase _db;

  @override
  Future<void> close() => _db.close();

  @override
  Future<void> upsertJob(DownloadJob job) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _db
          .into(_db.downloadJobs)
          .insertOnConflictUpdate(
            DownloadJobsCompanion(
              id: Value(job.id),
              resourceId: Value(job.resourceId),
              variantIndex: Value(job.variantIndex),
              url: Value(job.url.toString()),
              filename: Value(job.filename),
              headersJson: Value(jsonEncode(job.networkOptions.headers)),
              networkOptionsJson: Value(
                jsonEncode(job.networkOptions.toJson()),
              ),
              validationJson: Value(jsonEncode(job.validation.toJson())),
              saveTargetJson: Value(jsonEncode(job.saveTarget.toJson())),
              thumbnailUrl: Value(job.thumbnailUrl),
              title: Value(job.title),
              createdAt: Value(job.createdAt.millisecondsSinceEpoch),
              updatedAt: Value(now),
            ),
          );

      await _db
          .into(_db.downloadStates)
          .insertOnConflictUpdate(
            DownloadStatesCompanion(
              jobId: Value(job.id),
              status: Value(DownloadStatus.queued.name),
              saveState: Value(SaveState.none.name),
              receivedBytes: const Value(0),
              totalBytes: const Value(null),
              progress: const Value(0),
              localPath: const Value(null),
              galleryAssetId: const Value(null),
              error: const Value(null),
              updatedAt: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> updateProgress(
    String jobId, {
    int? receivedBytes,
    int? totalBytes,
    double? progress,
  }) async {
    final companion = DownloadStatesCompanion(
      receivedBytes: receivedBytes == null
          ? const Value.absent()
          : Value(receivedBytes),
      totalBytes: totalBytes == null ? const Value.absent() : Value(totalBytes),
      progress: progress == null
          ? const Value.absent()
          : Value(progress.clamp(0, 1)),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
    await (_db.update(
      _db.downloadStates,
    )..where((table) => table.jobId.equals(jobId))).write(companion);
  }

  @override
  Future<void> updateStatus(
    String jobId,
    DownloadStatus status, {
    String? error,
  }) async {
    await (_db.update(
      _db.downloadStates,
    )..where((table) => table.jobId.equals(jobId))).write(
      DownloadStatesCompanion(
        status: Value(status.name),
        error: Value(error),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> updateSaveState(
    String jobId,
    SaveState state, {
    String? localPath,
    String? galleryAssetId,
    String? error,
  }) async {
    await (_db.update(
      _db.downloadStates,
    )..where((table) => table.jobId.equals(jobId))).write(
      DownloadStatesCompanion(
        saveState: Value(state.name),
        localPath: localPath == null ? const Value.absent() : Value(localPath),
        galleryAssetId: galleryAssetId == null
            ? const Value.absent()
            : Value(galleryAssetId),
        error: Value(error),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> appendLog(String jobId, String message) async {
    await _db.transaction(() async {
      final query = _db.selectOnly(_db.downloadStates)
        ..where(_db.downloadStates.jobId.equals(jobId));
      query.addColumns([_db.downloadStates.log]);
      final existing = await query
          .map((row) => row.read(_db.downloadStates.log))
          .getSingleOrNull();
      final entry = '[${DateTime.now().toIso8601String()}] $message';
      var nextLog = existing == null || existing.isEmpty
          ? entry
          : '$existing\n$entry';
      const maxLogCharacters = 64 * 1024;
      if (nextLog.length > maxLogCharacters) {
        nextLog = nextLog.substring(nextLog.length - maxLogCharacters);
        final firstNewline = nextLog.indexOf('\n');
        if (firstNewline >= 0) {
          nextLog = nextLog.substring(firstNewline + 1);
        }
      }
      await (_db.update(
        _db.downloadStates,
      )..where((table) => table.jobId.equals(jobId))).write(
        DownloadStatesCompanion(
          log: Value(nextLog),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> applyEngineSnapshot(DownloadEngineSnapshot snapshot) async {
    await (_db.update(
      _db.downloadStates,
    )..where((table) => table.jobId.equals(snapshot.jobId))).write(
      DownloadStatesCompanion(
        status: Value(snapshot.status.name),
        saveState: Value(snapshot.saveState.name),
        receivedBytes: Value(snapshot.receivedBytes),
        totalBytes: Value(snapshot.totalBytes),
        progress: Value(snapshot.progress.clamp(0, 1)),
        localPath: snapshot.localPath == null
            ? const Value.absent()
            : Value(snapshot.localPath),
        galleryAssetId: snapshot.galleryAssetId == null
            ? const Value.absent()
            : Value(snapshot.galleryAssetId),
        error: Value(snapshot.error),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<DownloadTaskSnapshot?> getTask(String jobId) async {
    final rows = await _selectSnapshots(jobId: jobId).get();
    if (rows.isEmpty) {
      return null;
    }
    return _snapshotFromRow(rows.first);
  }

  @override
  Future<DownloadJob?> getJob(String jobId) async {
    final row = await (_db.select(
      _db.downloadJobs,
    )..where((table) => table.id.equals(jobId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return DownloadJob(
      id: row.id,
      resourceId: row.resourceId,
      variantIndex: row.variantIndex,
      url: Uri.parse(row.url),
      filename: row.filename,
      networkOptions: _networkOptionsFromJson(
        row.networkOptionsJson,
        legacyHeadersJson: row.headersJson,
      ),
      validation: DownloadValidationOptions.fromJson(
        _objectMapFromJson(row.validationJson),
      ),
      saveTarget: SaveTarget.fromJson(_objectMapFromJson(row.saveTargetJson)),
      thumbnailUrl: row.thumbnailUrl,
      title: row.title,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }

  @override
  Future<void> deleteTask(String jobId) async {
    await (_db.delete(
      _db.downloadJobs,
    )..where((table) => table.id.equals(jobId))).go();
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async {
    final rows = await _selectSnapshots(
      resourceId: resourceId,
      status: status,
      saveState: saveState,
    ).get();
    return rows.map(_snapshotFromRow).toList(growable: false);
  }

  @override
  Stream<List<DownloadTaskSnapshot>> watchTasks({int? resourceId}) {
    return _selectSnapshots(
      resourceId: resourceId,
    ).watch().map((rows) => rows.map(_snapshotFromRow).toList(growable: false));
  }

  @override
  Stream<DownloadTaskSnapshot?> watchTask(String jobId) {
    return _selectSnapshots(
      jobId: jobId,
    ).watch().map((rows) => rows.isEmpty ? null : _snapshotFromRow(rows.first));
  }

  @override
  Stream<DownloadSummary> watchSummary({int? resourceId}) {
    return watchTasks(
      resourceId: resourceId,
    ).map((tasks) => DownloadSummary.fromTasks(tasks, resourceId: resourceId));
  }

  @override
  Future<List<DownloadTaskSnapshot>> listPendingSaveTasks() async {
    final rows = await _selectSnapshots(
      status: DownloadStatus.downloaded,
      saveStates: const [SaveState.pending, SaveState.saving],
    ).get();
    return rows.map(_snapshotFromRow).toList(growable: false);
  }

  @override
  Future<List<DownloadTaskSnapshot>> listRecoverableTasks() async {
    final rows = await _selectSnapshots(
      statuses: const [
        DownloadStatus.queued,
        DownloadStatus.running,
        DownloadStatus.paused,
      ],
    ).get();
    return rows.map(_snapshotFromRow).toList(growable: false);
  }

  Selectable<QueryRow> _selectSnapshots({
    String? jobId,
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
    List<DownloadStatus>? statuses,
    List<SaveState>? saveStates,
  }) {
    final where = <String>[];
    final variables = <Variable<Object>>[];

    if (jobId != null) {
      where.add('j.id = ?');
      variables.add(Variable<String>(jobId));
    }
    if (resourceId != null) {
      where.add('j.resource_id = ?');
      variables.add(Variable<int>(resourceId));
    }
    if (status != null) {
      where.add('s.status = ?');
      variables.add(Variable<String>(status.name));
    }
    if (saveState != null) {
      where.add('s.save_state = ?');
      variables.add(Variable<String>(saveState.name));
    }
    if (statuses != null && statuses.isNotEmpty) {
      where.add(
        's.status IN (${List.filled(statuses.length, '?').join(', ')})',
      );
      variables.addAll(statuses.map((status) => Variable<String>(status.name)));
    }
    if (saveStates != null && saveStates.isNotEmpty) {
      where.add(
        's.save_state IN (${List.filled(saveStates.length, '?').join(', ')})',
      );
      variables.addAll(saveStates.map((state) => Variable<String>(state.name)));
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    return _db.customSelect(
      '''
      SELECT
        j.id AS id,
        j.resource_id AS resource_id,
        j.variant_index AS variant_index,
        j.filename AS filename,
        j.title AS title,
        j.thumbnail_url AS thumbnail_url,
        j.created_at AS created_at,
        s.status AS status,
        s.save_state AS save_state,
        s.received_bytes AS received_bytes,
        s.total_bytes AS total_bytes,
        s.progress AS progress,
        s.local_path AS local_path,
        s.gallery_asset_id AS gallery_asset_id,
        s.error AS error,
        s.log AS log,
        s.updated_at AS updated_at
      FROM download_jobs j
      INNER JOIN download_states s ON s.job_id = j.id
      $whereClause
      ORDER BY j.created_at DESC
      ''',
      variables: variables,
      readsFrom: {_db.downloadJobs, _db.downloadStates},
    );
  }

  DownloadTaskSnapshot _snapshotFromRow(QueryRow row) {
    final filename = row.read<String>('filename');
    return DownloadTaskSnapshot(
      id: row.read<String>('id'),
      resourceId: row.read<int>('resource_id'),
      variantIndex: row.read<int>('variant_index'),
      title: row.readNullable<String>('title') ?? filename,
      filename: filename,
      thumbnailUrl: row.readNullable<String>('thumbnail_url'),
      status: _enumByName(
        DownloadStatus.values,
        row.read<String>('status'),
        DownloadStatus.failed,
      ),
      saveState: _enumByName(
        SaveState.values,
        row.read<String>('save_state'),
        SaveState.none,
      ),
      receivedBytes: row.read<int>('received_bytes'),
      totalBytes: row.readNullable<int>('total_bytes'),
      progress: row.read<double>('progress').clamp(0, 1),
      localPath: row.readNullable<String>('local_path'),
      galleryAssetId: row.readNullable<String>('gallery_asset_id'),
      error: row.readNullable<String>('error'),
      log: row.readNullable<String>('log'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at'),
      ),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

Map<String, String> _stringMapFromJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    return const {};
  }
  return decoded.map(
    (key, value) => MapEntry(key.toString(), value.toString()),
  );
}

Map<String, Object?> _objectMapFromJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    return const {};
  }
  return decoded.map((key, value) => MapEntry(key.toString(), value));
}

DownloadNetworkOptions _networkOptionsFromJson(
  String source, {
  required String legacyHeadersJson,
}) {
  final json = _objectMapFromJson(source);
  if (json.isNotEmpty) {
    return DownloadNetworkOptions.fromJson(json);
  }
  return DownloadNetworkOptions(headers: _stringMapFromJson(legacyHeadersJson));
}
