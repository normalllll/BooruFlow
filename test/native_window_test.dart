import 'dart:async';
import 'dart:ui' as ui;

import 'package:booruflow/app/frost_config.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_window/frost_window.dart';

const channel = MethodChannel('frost_window');
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

Finder caption(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  ),
  matching: find.byType(IconButton),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  late FrostWindowController controller;
  setUp(() {
    calls.clear();
    LocaleSettings.setLocale(AppLocale.en);
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
    controller.dispose();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> drain(WidgetTester tester) async {
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump();
    }
  }

  Widget app({Widget? home, bool dark = false}) {
    controller = FrostWindowController(minimumSize: const Size(320, 480));
    return TranslationProvider(
      child: FrostScope(
        config: appFrostConfig,
        child: MaterialApp(
          theme: FrostTheme.build(
            config: appFrostConfig,
            brightness: dark ? Brightness.dark : Brightness.light,
            platform: defaultTargetPlatform,
            locale: const Locale('en'),
          ),
          home: home ?? const SizedBox.expand(key: ValueKey('page')),
          builder: (context, child) => Overlay.wrap(
            child: FrostWindowHost(
              controller: controller,
              title: 'Window test',
              child: FrostShell(
                destinations: [
                  FrostNavDestination(label: 'Browse', icon: appIcons.image),
                ],
                selectedIndex: 0,
                atDestinationRoot: true,
                onDestinationSelected: (_) {},
                canGoBack: false,
                onBack: () {},
                showsMobileNavigation: true,
                brand: const FrostText(
                  'Window test',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
    // Initialization waits for the native query, then publishes the first
    // measured frame without requiring a native resize/state event.
    reply.complete({'revision': 0});
    await drain(tester);
    expect(
      controller.ready,
      isTrue,
      reason: calls.map((call) => call.method).join(", "),
    );
    final updates = calls.where((call) => call.method == 'setRegions');
    expect(updates, isNotEmpty);
    final regions = updates.last.arguments as List;
    // The edge-to-edge Back control owns the first rail-width slot; only the
    // remaining brand/title span is draggable.
    final captionRegions = regions.where((row) => row[4] == 'caption');
    expect(captionRegions, hasLength(1));
    expect(captionRegions.single[0], 80);
    expect(
      tester.getRect(find.byKey(const ValueKey('frost-shell-back'))),
      const Rect.fromLTWH(0, 0, 80, 40),
    );
    expect(regions.where((row) => row[4] == 'maximize'), hasLength(1));
  });

  windowTest('native maximize and restore events update the caption button', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await drain(tester);
    expect(caption('Maximize'), findsOneWidget);
    await nativeEvent('stateChanged', {'maximized': true, 'revision': 1});
    await tester.pump();
    expect(caption('Restore'), findsOneWidget);
    await nativeEvent('stateChanged', {'maximized': false, 'revision': 2});
    await drain(tester);
    expect(caption('Maximize'), findsOneWidget);
  });

  test('startup query cannot overwrite a more recent native state', () async {
    final reply = Completer<Object?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => reply.future);
    controller = FrostWindowController(minimumSize: const Size(320, 480));
    final initialized = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    await nativeEvent('stateChanged', {'maximized': true, 'revision': 2});
    reply.complete({'maximized': false, 'revision': 1});
    await initialized;
    expect(controller.state.maximized, isTrue);
    expect(controller.state.revision, 2);
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
    await drain(tester);
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
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await drain(tester);
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
    for (final tooltip in ['Expand sidebar', 'Minimize', 'Close']) {
      final point = tester.getCenter(
        tooltip == 'Expand sidebar'
            ? find.byWidgetPredicate(
                (widget) => widget is FrostTooltip && widget.message == tooltip,
              )
            : caption(tooltip),
      );
      expect(
        regions().any((r) => rect(r).contains(point)),
        isFalse,
        reason: '$tooltip must retain normal Flutter input',
      );
    }
    expect(tester.getRect(caption('Close')).right, 1000);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(
      tester.getSemantics(caption('Close')).getSemanticsData().label,
      contains('Close'),
    );
    final oldMax = regions().singleWhere((r) => r[4] == 'maximize');
    expect(
      rect(oldMax).contains(tester.getCenter(caption('Maximize'))),
      isTrue,
    );
    tester.view.physicalSize = const Size(480, 360);
    await tester.pump();
    await tester.pump();
    expect(find.byType(FrostCaptionButtons), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey('page'))).top, 40);
    expect(tester.getRect(caption('Close')).right, 480);
    expect(
      rect(regions().singleWhere((r) => r[4] == 'maximize')).right,
      lessThan(rect(oldMax).right),
    );
    expect(tester.takeException(), isNull);
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.linux]) {
    windowTest(
      '$platform keeps system frame and fixed shell Back without custom window buttons',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(app(dark: true));
        await drain(tester);
        expect(caption('Minimize'), findsNothing);
        expect(caption('Maximize'), findsNothing);
        expect(caption('Close'), findsNothing);
        expect(tester.getRect(find.byKey(const ValueKey('page'))).top, 8);
        final back = find.bySemanticsLabel(t.frost.back);
        expect(back, findsOneWidget);
        expect(
          tester
              .getSemantics(back)
              .getSemanticsData()
              .flagsCollection
              .isEnabled,
          ui.Tristate.isFalse,
        );
        expect(frostUsesCustomTitleBar, isFalse);
        expect(calls, isEmpty);
      },
      platform: platform,
    );
  }

  windowTest('mobile does not contact the desktop bridge', (tester) async {
    await tester.pumpWidget(app());
    await drain(tester);
    expect(calls, isEmpty);
    expect(caption('Close'), findsNothing);
  }, platform: TargetPlatform.android);
}
