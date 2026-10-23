/// The one boundary that understands pre-v2 storage formats. Hive files move
/// before boxes open, settings migrate before readers start, and Drift runs its
/// versioned schema upgrade when the database opens. No UI parses legacy data.
library;

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'downloads/download_database.dart';
import 'downloads/models/download_enums.dart';
import 'downloads/models/save_target.dart';
import 'file_paths.dart';
import 'settings/background.dart';

const legacySettingsVersionKey = 'legacyUpgradeVersion';
const legacyDownloadSchemaVersion = 4;
const _legacySettingsVersion = 1;

Future<Map<String, dynamic>> upgradeLegacySettings(
  Map<String, dynamic> stored,
  Future<void> Function(String, dynamic) write,
) async {
  if (stored[legacySettingsVersionKey] == _legacySettingsVersion) return stored;
  final result = Map<String, dynamic>.of(stored);
  Future<void> save(String key, Object? value) async {
    if (result[key] == value) return;
    await write(key, value);
    result[key] = value;
  }

  final background = stored['background'] is Map
      ? BackgroundSettings.fromRecord(stored['background'])
      : BackgroundSettings(
          material: stored['reduceTransparency'] == true
              ? BackgroundMaterial.off
              : BackgroundMaterial.ambient,
        );
  await save('background', background.toRecord());
  if (stored['downloadPath'] case final String path) {
    await save('downloadPath', normalizeLocalPath(path));
  }
  // Historical ordinal tables are fixed here, independent of the current enums.
  const modes = ['off', 'persistedIpOverride', 'persistedIpOverride'];
  const dns = ['uncensoredDns', 'dohSb'];
  const ratings = [
    'general',
    'sensitive',
    'questionable',
    'explicit',
    'unknown',
  ];
  final mode = stored['booruNetworkFallbackMode'];
  await save('booruNetworkFallbackMode', switch (mode) {
    final int i when i >= 0 && i < modes.length => modes[i],
    'legacyIpUrl' => 'persistedIpOverride',
    final String s when modes.contains(s) => s,
    _ => 'off',
  });
  final provider = stored['booruDnsProvider'];
  await save('booruDnsProvider', switch (provider) {
    final int i when i >= 0 && i < dns.length => dns[i],
    final String s when dns.contains(s) => s,
    _ => 'uncensoredDns',
  });
  if (stored['booruRatings'] case final List values) {
    await save('booruRatings', [
      for (final value in values)
        if (value is int && value >= 0 && value < ratings.length)
          ratings[value]
        else if (value is String && ratings.contains(value))
          value,
    ]);
  }
  await save(legacySettingsVersionKey, _legacySettingsVersion);
  return result;
}

// Only these application-owned legacy files may be moved. Downloaded files and
// unrelated Documents content must stay visible in Files.
const _legacyBoxes = [
  'settings',
  'booru_credentials',
  'discovery_tags',
  'discovery_capabilities_v1',
];

Future<void> upgradeDocumentsStorage(
  Directory documents,
  Directory private,
) async {
  final version = File(p.join(private.path, 'legacy-upgrade-version'));
  if (await version.exists() && await version.readAsString() == '1') return;
  await _moveDocumentsBoxes(documents, private);
  // Mark only after every rename succeeds; interrupted upgrades are retryable.
  await version.writeAsString('1', flush: true);
}

Future<void> _moveDocumentsBoxes(Directory documents, Directory private) async {
  for (final name in _legacyBoxes) {
    var destination = private;
    if (await File(p.join(private.path, '$name.hive')).exists() ||
        await File(p.join(private.path, '$name.hivec')).exists()) {
      // Never overwrite newer private data. Preserve any duplicate legacy data
      // privately, including interrupted-compaction files, for recovery.
      destination = Directory(p.join(private.path, 'legacy-documents'));
    }
    for (final extension in ['hive', 'hivec']) {
      final source = File(p.join(documents.path, '$name.$extension'));
      if (!await source.exists()) continue;
      await destination.create(recursive: true);
      var target = p.join(destination.path, '$name.$extension');
      if (await File(target).exists()) {
        target = '$target.${DateTime.now().microsecondsSinceEpoch}';
      }
      // Both directories belong to the same iOS app container. Atomic rename
      // preserves bytes; a failure stops initialization rather than losing data.
      await source.rename(target);
    }
    final lock = File(p.join(documents.path, '$name.lock'));
    if (await lock.exists()) await lock.delete();
  }
}

Future<void> upgradeDownloadDatabase(
  DownloadDatabase database,
  Migrator migrator,
  int from,
  int to,
) async {
  if (from < 3) {
    await migrator.addColumn(
      database.downloadJobs,
      database.downloadJobs.ugoiraExport,
    );
  }
  if (from < 2) {
    await migrator.addColumn(
      database.downloadJobs,
      database.downloadJobs.batchId,
    );
  }
  if (from < 4) {
    final jobs = await database
        .customSelect('SELECT id, save_target_json FROM download_jobs')
        .get();
    for (final row in jobs) {
      final raw = row.read<String>('save_target_json');
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic> ||
            decoded['type'] is! String ||
            !SaveTargetType.values.any(
              (type) => type.name == decoded['type'],
            ) ||
            decoded['directory'] != null && decoded['directory'] is! String ||
            decoded['subdirectory'] != null &&
                decoded['subdirectory'] is! String) {
          continue;
        }
        final target = SaveTarget.fromJson(decoded).toJson();
        if (target['directory'] != decoded['directory'] ||
            target['subdirectory'] != decoded['subdirectory']) {
          await database.customStatement(
            'UPDATE download_jobs SET save_target_json = ? WHERE id = ?',
            [
              jsonEncode({...decoded, ...target}),
              row.read<String>('id'),
            ],
          );
        }
      } on FormatException {
        // Keep malformed optional legacy metadata for the existing reader.
      }
    }
    final states = await database
        .customSelect(
          'SELECT job_id, local_path FROM download_states WHERE local_path IS NOT NULL',
        )
        .get();
    for (final row in states) {
      final raw = row.read<String>('local_path');
      final normalized = normalizeLocalPath(raw);
      if (normalized != raw) {
        await database.customStatement(
          'UPDATE download_states SET local_path = ? WHERE job_id = ?',
          [normalized, row.read<String>('job_id')],
        );
      }
    }
  }
}
