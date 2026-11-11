// The app on sample data, for development and screenshots: sample posts, tags,
// downloads and settings, with storage in a temporary directory emptied at each
// start so the real profile is never read or written. Run it with
// `flutter run -d windows -t tool/sample_main.dart`.
import 'dart:io';

import 'package:booruflow/app/bootstrap.dart';
import 'package:booruflow/dev/sample_data.dart';
// path_provider already owns this interface in the application dependency
// graph; this entrypoint uses it to isolate every platform path request.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

Future<void> main() => startSample();

/// Starts the app on sample data. Shared with `tool/automation_entry.dart`.
Future<void> startSample() async {
  // One directory, emptied at each start, so runs do not pile up.
  final root = Directory('${Directory.systemTemp.path}/booruflow_sample');
  if (root.existsSync()) root.deleteSync(recursive: true);
  root.createSync(recursive: true);
  PathProviderPlatform.instance = _SamplePaths(root);
  await bootstrap(overrides: sampleOverrides);
}

class _SamplePaths extends PathProviderPlatform {
  _SamplePaths(this.root);
  final Directory root;

  Future<String> _directory(String name) async =>
      (await Directory('${root.path}/$name').create(recursive: true)).path;

  @override
  Future<String?> getApplicationSupportPath() => _directory('support');
  @override
  Future<String?> getApplicationDocumentsPath() => _directory('documents');
  @override
  Future<String?> getApplicationCachePath() => _directory('cache');
  @override
  Future<String?> getTemporaryPath() => _directory('temp');
  @override
  Future<String?> getDownloadsPath() => _directory('downloads');
  @override
  Future<String?> getLibraryPath() => _directory('library');
}
