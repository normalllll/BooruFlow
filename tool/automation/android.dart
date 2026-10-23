// Isolated, loopback-controlled Android test entrypoint. Never imported by main.
import 'dart:convert';
import 'dart:io';
import 'package:booruflow/app/bootstrap.dart';
import 'package:flutter/widgets.dart';
import 'automation_binding.dart';
import 'main.dart'
    show AutomationHost, AutomationHostState, captureAutomationErrors;
import 'preview/fixture.dart';
import 'profile_paths.dart';

const liveAutomation = bool.fromEnvironment('BOORUFLOW_AUTOMATION_LIVE');
const liveProfile = String.fromEnvironment(
  'BOORUFLOW_AUTOMATION_PROFILE',
  defaultValue: 'r12-live-validation',
);

Future<void> main() async {
  if (!Platform.isAndroid) {
    throw StateError('Android fixture only');
  }
  final host = GlobalKey<AutomationHostState>();
  final page = GlobalKey<_AndroidBoardsState>();
  AutomationBinding((message) => host.currentState!.request(message));
  captureAutomationErrors();
  AutomationPaths.install(
    Directory(
      liveAutomation
          ? '/data/user/0/io.github.normalllll.booruflow/files/$liveProfile'
          : '/data/user/0/io.github.normalllll.booruflow/files/r5-validation',
    ),
  );
  await bootstrap(
    appBuilder: (app) => AutomationHost(
      key: host,
      child: _AndroidBoards(key: page, app: app),
    ),
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9415);
  await for (final request in server) {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      String result;
      if (data['command'] == 'live') {
        result = jsonEncode({'live': liveAutomation});
      } else if (data['command'] == 'board' && !liveAutomation) {
        page.currentState!.select(data['board'] as String);
        result = jsonEncode({'board': data['board']});
      } else {
        result = await host.currentState!.request(body);
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(result);
    } catch (error, stack) {
      request.response.statusCode = 500;
      request.response.write(
        jsonEncode({'error': '$error', 'stack': '$stack'}),
      );
    } finally {
      await request.response.close();
    }
  }
}

class _AndroidBoards extends StatefulWidget {
  const _AndroidBoards({required this.app, super.key});
  final Widget app;
  @override
  State<_AndroidBoards> createState() => _AndroidBoardsState();
}

class _AndroidBoardsState extends State<_AndroidBoards> {
  String? board = liveAutomation ? null : 'M02';
  void select(String? value) => setState(() => board = value);
  @override
  Widget build(BuildContext context) => board == null
      ? widget.app
      : PreviewFixture(key: ValueKey(board), board: board!);
}
