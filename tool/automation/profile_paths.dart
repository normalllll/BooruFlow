import 'dart:io';

// path_provider already owns this interface in the application dependency graph.
// Import it only in this test entrypoint to isolate all platform path requests;
// no new third-party dependency or production path override is introduced.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class AutomationPaths extends PathProviderPlatform {
  AutomationPaths(this.root);
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

  static void install(Directory root) {
    PathProviderPlatform.instance = AutomationPaths(root);
  }
}
