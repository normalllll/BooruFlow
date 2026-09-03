import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'download_database.g.dart';

class DownloadJobs extends Table {
  TextColumn get id => text()();
  IntColumn get resourceId => integer()();
  TextColumn get sourceId => text().withDefault(const Constant('yande'))();
  TextColumn get postId => text().withDefault(const Constant(''))();
  IntColumn get variantIndex => integer().withDefault(const Constant(0))();
  TextColumn get url => text()();
  TextColumn get filename => text()();
  TextColumn get headersJson => text().withDefault(const Constant('{}'))();
  TextColumn get networkOptionsJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get validationJson => text().withDefault(const Constant('{}'))();
  TextColumn get saveTargetJson => text().withDefault(const Constant('{}'))();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get title => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DownloadStates extends Table {
  TextColumn get jobId =>
      text().references(DownloadJobs, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => text()();
  TextColumn get saveState => text()();
  IntColumn get receivedBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  TextColumn get localPath => text().nullable()();
  TextColumn get galleryAssetId => text().nullable()();
  TextColumn get error => text().nullable()();
  TextColumn get log => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {jobId};
}

@DriftDatabase(tables: [DownloadJobs, DownloadStates])
class DownloadDatabase extends _$DownloadDatabase {
  DownloadDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(downloadJobs, downloadJobs.variantIndex);
        }
        if (from < 3) {
          await migrator.addColumn(downloadStates, downloadStates.log);
        }
        if (from < 4) {
          await migrator.addColumn(
            downloadJobs,
            downloadJobs.networkOptionsJson,
          );
          await migrator.addColumn(downloadJobs, downloadJobs.validationJson);
        }
        if (from < 5) {
          await migrator.addColumn(downloadJobs, downloadJobs.sourceId);
          await migrator.addColumn(downloadJobs, downloadJobs.postId);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(p.join(supportDirectory.path, 'yande_gui'));
    await directory.create(recursive: true);
    return NativeDatabase.createInBackground(
      File(p.join(directory.path, 'downloads.sqlite')),
    );
  });
}
