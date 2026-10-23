// Owned-window test entrypoints. Normal main never imports this file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:booruflow/app/bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'automation_binding.dart';
import 'main.dart'
    show AutomationHost, AutomationHostState, automationFlutterErrors;
import 'preview/fixture.dart';
import 'profile_paths.dart';

Future<void> main() => runOwnedAutomation(release: true);

Future<void> runOwnedAutomation({required bool release}) async {
  if (kReleaseMode != release || !Platform.isWindows) {
    throw StateError('Dedicated Windows test entrypoint has the wrong build mode');
  }
  final rootPath = Platform.environment['BOORUFLOW_AUTOMATION_PROFILE'];
  if (rootPath == null || !Directory(rootPath).isAbsolute) {
    throw StateError('Explicit isolated profile required');
  }
  final root = Directory(rootPath);
  final host = GlobalKey<AutomationHostState>();
  AutomationBinding(
    (_) async => throw UnsupportedError('Release has no VM Driver'),
  );
  // Default-OFF native automation must be present before production bootstrap.
  const native = MethodChannel('booruflow/automation');
  for (var attempts = 0; ; attempts++) {
    try {
      await native.invokeMethod<Object?>('status');
      break;
    } on MissingPluginException {
      if (attempts >= 50) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    automationFlutterErrors.add(details);
    previousErrorHandler?.call(details);
  };
  AutomationPaths.install(root);
  await bootstrap(
    appBuilder: (_) => AutomationHost(
      key: host,
      child: PreviewFixture(
        board: Platform.environment['BOORUFLOW_PREVIEW_BOARD'] ?? 'M02',
      ),
    ),
  );
  final requests = File('${root.path}/request.json'),
      response = File('${root.path}/response.json');
  var busy = false, lastId = -1;
  Timer.periodic(const Duration(milliseconds: 40), (_) async {
    if (busy || !await requests.exists()) return;
    busy = true;
    try {
      final command =
          jsonDecode(await requests.readAsString()) as Map<String, dynamic>;
      final id = command['id'] as int;
      if (id == lastId || host.currentState == null) return;
      lastId = id;
      try {
        final value = await host.currentState!.request(
          jsonEncode(command['request']),
        );
        await response.writeAsString(
          jsonEncode({'id': id, 'result': jsonDecode(value)}),
          flush: true,
        );
      } catch (error, stack) {
        await response.writeAsString(
          jsonEncode({'id': id, 'error': '$error', 'stack': '$stack'}),
          flush: true,
        );
      }
    } on FormatException {
      /* Ignore an incomplete atomic-control-file write. */
    } finally {
      busy = false;
    }
  });
}
