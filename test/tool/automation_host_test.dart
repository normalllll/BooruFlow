import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/automation/main.dart'
    show AutomationHost, AutomationHostState;

class _Content extends StatefulWidget {
  const _Content();
  static int mounts = 0;
  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  @override
  void initState() {
    super.initState();
    _Content.mounts++;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Text(
      '${Theme.of(context).brightness.name}:${size.width}:${size.height}',
    );
  }
}

void main() {
  testWidgets(
    'test platform brightness preserves app State, metrics and system restoration',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const channel = MethodChannel('booruflow/automation');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      _Content.mounts = 0;
      final host = GlobalKey<AutomationHostState>();
      await tester.pumpWidget(
        AutomationHost(
          key: host,
          child: MaterialApp(
            themeMode: ThemeMode.system,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const _Content(),
          ),
        ),
      );
      Future<void> brightness(String value) async {
        final response = host.currentState!.request(
          jsonEncode({'command': 'platformBrightness', 'value': value}),
        );
        await tester.pump();
        expect(jsonDecode(await response)['platformBrightness'], value);
        await tester.pumpAndSettle();
      }

      await brightness('dark');
      expect(find.text('dark:800.0:600.0'), findsOneWidget);
      tester.view.physicalSize = const Size(600, 700);
      await tester.pumpAndSettle();
      expect(find.text('dark:600.0:700.0'), findsOneWidget);
      await brightness('light');
      expect(find.text('light:600.0:700.0'), findsOneWidget);
      await brightness('system');
      expect(
        find.text(
          '${tester.platformDispatcher.platformBrightness.name}:600.0:700.0',
        ),
        findsOneWidget,
      );
      expect(_Content.mounts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'internal mouse pointer follows Flutter hover and tap without native input',
    (tester) async {
      const channel = MethodChannel('booruflow/automation');
      final methods = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        methods.add(call.method);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final host = GlobalKey<AutomationHostState>();
      var entered = 0, exited = 0, tapped = 0;
      await tester.pumpWidget(
        AutomationHost(
          key: host,
          child: MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                onEnter: (_) => entered++,
                onExit: (_) => exited++,
                child: GestureDetector(
                  onTap: () => tapped++,
                  child: const SizedBox(
                    width: 100,
                    height: 80,
                    child: Text('Target'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.text('Target'));
      Future<void> send(String action) async {
        final pending = host.currentState!.request(
          jsonEncode({
            'command': 'pointer',
            'action': action,
            'x': center.dx,
            'y': center.dy,
          }),
        );
        await tester.pump();
        expect(jsonDecode(await pending)['nativeInput'], false);
      }

      await send('hover');
      expect(entered, 1);
      expect(tapped, 0);
      await send('tap');
      expect(tapped, 1);
      await send('remove');
      expect(exited, 1);
      expect(methods.toSet(), Platform.isWindows ? {'present'} : isEmpty);
      await expectLater(
        host.currentState!.request(
          jsonEncode({'command': 'pointer', 'action': 'tap', 'x': -1, 'y': 10}),
        ),
        throwsArgumentError,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'held pointer capture supports mouse and touch with cancel or activation',
    (tester) async {
      const channel = MethodChannel('booruflow/automation');
      final methods = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        methods.add(call.method);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final host = GlobalKey<AutomationHostState>();
      var calls = 0, downs = 0;
      await tester.pumpWidget(
        AutomationHost(
          key: host,
          child: MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: Listener(
                onPointerDown: (_) => downs++,
                child: GestureDetector(
                  onTap: () => calls++,
                  child: const SizedBox(
                    width: 100,
                    height: 80,
                    child: Text('Target'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.text('Target'));
      Future<void> send(String action, {String? kind}) async {
        final pending = host.currentState!.request(
          jsonEncode({
            'command': 'touch',
            'action': action,
            'kind': kind,
            'x': center.dx,
            'y': center.dy,
          }),
        );
        await tester.pump();
        expect(jsonDecode(await pending)['nativeInput'], false);
      }

      for (final kind in ['mouse', 'touch']) {
        await send('down', kind: kind);
        expect(calls, 0);
        await send('cancel');
        expect(calls, 0);
      }
      expect(downs, 2);
      await send('down', kind: 'mouse');
      await send('up');
      expect(calls, 1);
      expect(methods.toSet(), Platform.isWindows ? {'present'} : isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'list inspection never registers inherited dependencies during route changes',
    (tester) async {
      const channel = MethodChannel('booruflow/automation');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final host = GlobalKey<AutomationHostState>();
      await tester.pumpWidget(
        AutomationHost(
          key: host,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Second')),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      final pending = host.currentState!.request(
        jsonEncode({'command': 'listDiagnostics'}),
      );
      await tester.pump();
      expect(jsonDecode(await pending)['sources'], isEmpty);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      Navigator.of(tester.element(find.text('Second'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
