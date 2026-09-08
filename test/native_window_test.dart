import 'dart:async';
import 'dart:ui' as ui;

import 'package:booruflow/app/window/native_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const channel = MethodChannel('desktop_window');
const codec = StandardMethodCodec();

void windowTest(
  String name,
  Future<void> Function(WidgetTester) body, {
  TargetPlatform platform = TargetPlatform.windows,
}) {
  testWidgets(name, (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await body(tester);
    } finally {
      semantics.dispose();
    }
  }, variant: TargetPlatformVariant.only(platform));
}

Future<void> nativeEvent(String method, [Object? arguments]) {
  final completed = Completer<void>();
  ui.channelBuffers.push(
    channel.name,
    codec.encodeMethodCall(MethodCall(method, arguments)),
    (_) => completed.complete(),
  );
  return completed.future;
}

Finder caption(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'getState'
              ? <String, Object>{
                  'maximized': false,
                  'active': true,
                  'revision': 0,
                }
              : null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget app({Widget? home, VoidCallback? sidebar, bool dark = false}) =>
      MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: home ?? const SizedBox.expand(key: ValueKey('page')),
        builder: (context, child) => NativeWindowFrame(
          title: 'Window test',
          leading: const Icon(Icons.image),
          background: Colors.white,
          foreground: Colors.black,
          border: Colors.grey,
          onToggleSidebar: sidebar,
          sidebarTooltip: 'Toggle sidebar',
          child: child!,
        ),
      );

  windowTest('initial drag regions arrive without window events', (
    tester,
  ) async {
    final reply = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getState') return reply.future;
          return null;
        });
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final updates = calls.where((call) => call.method == 'setRegions');
    expect(updates, isNotEmpty);
    final regions = updates.last.arguments as List;
    expect(regions.where((row) => row[4] == 'caption'), hasLength(2));
    expect(regions.where((row) => row[4] == 'maximize'), hasLength(1));
    reply.complete({'revision': 0});
    await tester.pump();
  });

  windowTest('native maximize and restore events update the caption button', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(caption('Maximize'), findsOneWidget);
    await nativeEvent('stateChanged', {'maximized': true, 'revision': 1});
    await tester.pump();
    expect(caption('Restore'), findsOneWidget);
    await nativeEvent('stateChanged', {'maximized': false, 'revision': 2});
    await tester.pump();
    expect(caption('Maximize'), findsOneWidget);
  });

  test('startup query cannot overwrite a more recent native state', () async {
    final reply = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => reply.future);
    final controller = NativeWindowController();
    final initialized = controller.initialize();
    await nativeEvent('stateChanged', {'maximized': true, 'revision': 2});
    reply.complete({'maximized': false, 'revision': 1});
    await initialized;
    expect(controller.state.maximized, isTrue);
    expect(controller.state.revision, 2);
    controller.dispose();
  });

  windowTest('modal barriers do not block window controls', (tester) async {
    await tester.pumpWidget(
      app(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(title: Text('Modal dialog')),
              ),
              child: const Text('Open dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.tap(caption('Minimize'));
    await tester.tap(caption('Close'));
    await tester.pump();
    expect(calls.where((call) => call.method == 'minimize'), hasLength(1));
    expect(calls.where((call) => call.method == 'close'), hasLength(1));
    expect(find.text('Modal dialog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  windowTest('caption regions exclude interactive controls and follow resize', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(sidebar: () {}));
    await tester.pump();
    List<List<Object?>> regions() =>
        (calls.lastWhere((c) => c.method == 'setRegions').arguments as List)
            .map((r) => List<Object?>.from(r as List))
            .toList();
    Rect rect(List<Object?> row) => Rect.fromLTRB(
      (row[0] as num).toDouble(),
      (row[1] as num).toDouble(),
      (row[2] as num).toDouble(),
      (row[3] as num).toDouble(),
    );
    for (final tooltip in ['Toggle sidebar', 'Minimize', 'Close']) {
      final point = tester.getCenter(
        tooltip == 'Toggle sidebar'
            ? find.byTooltip(tooltip)
            : caption(tooltip),
      );
      expect(
        regions().any((r) => rect(r).contains(point)),
        isFalse,
        reason: '$tooltip must retain normal Flutter input',
      );
    }
    expect(tester.getRect(caption('Close')).right, 1000);
    expect(find.byTooltip('Close'), findsNothing);
    final oldMax = regions().singleWhere((r) => r[4] == 'maximize');
    expect(
      rect(oldMax).contains(tester.getCenter(caption('Maximize'))),
      isTrue,
    );
    await tester.binding.setSurfaceSize(const Size(480, 360));
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Toggle sidebar'), findsNothing);
    expect(tester.getRect(caption('Close')).right, 480);
    expect(
      rect(regions().singleWhere((r) => r[4] == 'maximize')).right,
      lessThan(rect(oldMax).right),
    );
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.linux]) {
    windowTest(
      '$platform has no duplicate Flutter title bar or window buttons',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var toggles = 0;
        await tester.pumpWidget(app(sidebar: () => toggles++, dark: true));
        await tester.pump();
        expect(caption('Minimize'), findsNothing);
        expect(caption('Maximize'), findsNothing);
        expect(caption('Close'), findsNothing);
        expect(tester.getSize(find.byKey(const ValueKey('page'))).height, 700);
        expect(desktopTitleBarInset, 0);
        final config =
            calls.lastWhere((c) => c.method == 'setToolbar').arguments as Map;
        expect(config['dark'], isTrue);
        expect(config['showSidebarButton'], isTrue);
        await nativeEvent('toggleSidebar');
        expect(toggles, 1);
        expect(calls.any((c) => c.method == 'setRegions'), isFalse);
      },
      platform: platform,
    );
  }

  windowTest('mobile does not contact the desktop bridge', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(calls, isEmpty);
    expect(caption('Close'), findsNothing);
  }, platform: TargetPlatform.android);
}
