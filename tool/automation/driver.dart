import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const _timeout = Duration(seconds: 12);

Future<void> main(List<String> args) async {
  stdout.encoding = utf8;
  stderr.encoding = utf8;
  if (args.length < 2) throw ArgumentError('VM_URI COMMAND [ARGS]');
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: args[0],
    printCommunication: false,
    logCommunicationToFile: false,
  );
  try {
    await driver.runUnsynchronized(() async {
      final action = args[1];
      switch (action) {
        case 'tree':
          stdout.writeln((await driver.getRenderTree()).tree);
        case 'request':
          stdout.writeln(await driver.requestData(args[2], timeout: _timeout));
        case 'app-record':
          final directory = Directory(args[2]);
          await directory.create(recursive: true);
          final count = int.parse(args[3]);
          final fps = int.parse(args[4]);
          final watch = Stopwatch()..start();
          final times = <int>[];
          int? width, height;
          for (var index = 0; index < count; index++) {
            final data =
                jsonDecode(await request(driver, 'appScreenshot'))
                    as Map<String, Object?>;
            width ??= data['width'] as int;
            height ??= data['height'] as int;
            if (width != data['width'] || height != data['height']) {
              throw StateError('App dimensions changed during recording');
            }
            await File(
              '${directory.path}/${index.toString().padLeft(4, '0')}.png',
            ).writeAsBytes(base64Decode(data['png'] as String));
            times.add(watch.elapsedMicroseconds);
            final remaining =
                ((index + 1) * 1000000 / fps).round() -
                watch.elapsedMicroseconds;
            if (remaining > 0) {
              await Future<void>.delayed(Duration(microseconds: remaining));
            }
          }
          stdout.writeln(
            jsonEncode({
              'width': width,
              'height': height,
              'frames': count,
              'sampleTimesMicroseconds': times,
              'elapsedSeconds': watch.elapsedMicroseconds / 1000000,
            }),
          );
        case 'app-shot':
          final data =
              jsonDecode(await request(driver, 'appScreenshot'))
                  as Map<String, Object?>;
          final file = File(args[2]);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(base64Decode(data.remove('png') as String));
          stdout.writeln(jsonEncode({...data, 'path': file.absolute.path}));
        case 'rect' ||
            'tap' ||
            'wait' ||
            'wait-absent' ||
            'text-of' ||
            'center' ||
            'scroll':
          // A selector must come from a previous tree/semantics observation.
          final selector = automationFinder(args[2], args[3]);
          await request(driver, 'refresh');
          switch (action) {
            case 'rect':
              final start = await driver.getTopLeft(
                selector,
                timeout: _timeout,
              );
              final end = await driver.getBottomRight(
                selector,
                timeout: _timeout,
              );
              stdout.writeln(
                jsonEncode({
                  'left': start.dx,
                  'top': start.dy,
                  'right': end.dx,
                  'bottom': end.dy,
                }),
              );
            case 'tap':
              await driver.tap(selector, timeout: _timeout);
            case 'wait':
              await driver.waitFor(selector, timeout: _timeout);
            case 'wait-absent':
              await driver.waitForAbsent(selector, timeout: _timeout);
            case 'text-of':
              stdout.writeln(
                jsonEncode({
                  'text': await driver.getText(selector, timeout: _timeout),
                }),
              );
            case 'center':
              final offset = await driver.getCenter(
                selector,
                timeout: _timeout,
              );
              stdout.writeln(jsonEncode({'x': offset.dx, 'y': offset.dy}));
            case 'scroll':
              await driver.scroll(
                selector,
                double.parse(args[4]),
                double.parse(args[5]),
                const Duration(milliseconds: 400),
                timeout: _timeout,
              );
          }
          await request(driver, 'refresh');
          if (!['text-of', 'center', 'rect'].contains(action)) {
            stdout.writeln(await request(driver, 'state'));
          }
        case 'text':
          await driver.enterText(args[2], timeout: _timeout);
          await request(driver, 'refresh');
          stdout.writeln(await request(driver, 'state'));
        case 'semantics':
          await driver.setSemantics(true, timeout: _timeout);
          stdout.writeln(await request(driver, 'semanticsTree'));
        default:
          throw ArgumentError('Unknown command: $action');
      }
    });
  } finally {
    await driver.close();
  }
}

Future<String> request(FlutterDriver driver, String command) =>
    driver.requestData(jsonEncode({'command': command}), timeout: _timeout);

/// Composes observed selectors when an app and an overlay repeat a label.
SerializableFinder automationFinder(String kind, String value) =>
    switch (kind) {
      'key' => find.byValueKey(value),
      'text' => find.text(value),
      'semantics' => find.bySemanticsLabel(value),
      'type' => find.byType(value),
      'scoped' => _scopedFinder(jsonDecode(value) as Map<String, Object?>),
      'ancestor' => _scopedFinder(
        jsonDecode(value) as Map<String, Object?>,
        ancestor: true,
      ),
      _ => throw ArgumentError('Use key/text/semantics/type/scoped selector'),
    };
SerializableFinder _scopedFinder(
  Map<String, Object?> data, {
  bool ancestor = false,
}) {
  SerializableFinder read(Object? value) {
    final item = value! as Map<String, Object?>;
    return automationFinder(item['kind']! as String, item['value']! as String);
  }

  if (ancestor) {
    return find.ancestor(
      of: read(data['of']),
      matching: read(data['matching']),
      firstMatchOnly: data['firstMatchOnly'] == true,
    );
  }
  return find.descendant(
    of: read(data['of']),
    matching: read(data['matching']),
    firstMatchOnly: data['firstMatchOnly'] == true,
  );
}
