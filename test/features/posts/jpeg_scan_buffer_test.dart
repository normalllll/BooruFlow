import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:booruflow/features/posts/widgets/jpeg_scan_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

const scanEnds = [
  5617,
  16603,
  22144,
  24368,
  52924,
  93200,
  94372,
  99557,
  103517,
  169787,
];

void main() {
  test('completed scans are independent of transport chunk boundaries', () {
    final bytes = File(
      'test/fixtures/media/r9-progressive.jpg',
    ).readAsBytesSync();
    for (final size in [1, 127, 4096, bytes.length]) {
      final parser = JpegScanParser();
      var previous = 0;
      for (var offset = 0; offset < bytes.length; offset += size) {
        final end = (offset + size).clamp(0, bytes.length);
        parser.add(Uint8List.sublistView(bytes, offset, end));
        if (parser.completedScanEnd > previous) {
          expect(scanEnds, contains(parser.completedScanEnd));
          previous = parser.completedScanEnd;
        }
      }
      expect(parser.completedScans, 10);
      expect(parser.finished, isTrue);
      expect(parser.progressive, isTrue);
      expect(parser.inspectedBytes, lessThanOrEqualTo(bytes.length));
    }
  });

  test(
    'stuffing, restart markers and split marker bytes never finish a scan',
    () {
      final parser = JpegScanParser();
      // Minimal progressive marker structure, followed by entropy bytes. The
      // parser only needs marker lengths; actual image validation belongs to codec.
      parser.add(
        Uint8List.fromList([255, 216, 255, 194, 0, 2, 255, 218, 0, 2, 1, 255]),
      );
      expect(parser.completedScans, 0);
      parser.add(Uint8List.fromList([0, 1, 255, 208, 1, 255, 255]));
      expect(parser.completedScans, 0);
      parser.add(Uint8List.fromList([196]));
      expect(parser.completedScans, 1);
      expect(parser.completedScanEnd, 17);
    },
  );

  for (final name in ['r9-baseline.jpg', 'r9-noninterlaced.png']) {
    test(
      '$name transfers the unmodified final bytes without previews',
      () async {
        final bytes = File('test/fixtures/media/$name').readAsBytesSync();
        var previews = 0;
        final buffer = await JpegScanBuffer.start(
          onPreview: (_, _) => previews++,
        );
        addTearDown(buffer.cancel);
        for (var offset = 0; offset < bytes.length; offset += 8192) {
          buffer.add(
            Uint8List.sublistView(
              bytes,
              offset,
              (offset + 8192).clamp(0, bytes.length),
            ),
          );
        }
        expect(await buffer.finish(), bytes);
        expect(previews, 0);
      },
    );
  }

  test(
    'one outstanding preview; acknowledgement pulls latest completed scan',
    () async {
      final bytes = File(
        'test/fixtures/media/r9-progressive.jpg',
      ).readAsBytesSync();
      final frames = <(Uint8List, int)>[];
      final first = Completer<void>(), next = Completer<void>();
      final buffer = await JpegScanBuffer.start(
        onPreview: (bytes, end) {
          frames.add((bytes, end));
          if (frames.length == 1) first.complete();
          if (frames.length == 2) next.complete();
        },
      );
      addTearDown(buffer.cancel);
      buffer.add(Uint8List.sublistView(bytes, 0, scanEnds.first + 2));
      await first.future;
      expect(frames.single.$2, scanEnds.first);
      // All these scans arrive while the first frame is still being decoded.
      buffer.add(Uint8List.sublistView(bytes, scanEnds.first + 2, 110000));
      buffer.nextPreview();
      await next.future;
      expect(frames.map((frame) => frame.$2), [5617, 103517]);
      expect(frames.last.$1, [...bytes.take(103517), 255, 217]);
      buffer.add(Uint8List.sublistView(bytes, 110000));
      expect(await buffer.finish(), bytes);
      expect(frames.length, 2);
    },
  );

  test(
    'cancel terminates finish instead of leaving a pending result',
    () async {
      final buffer = await JpegScanBuffer.start(onPreview: (_, _) {});
      final finished = buffer.finish();
      buffer.cancel();
      await expectLater(finished, throwsA(isA<ImageLoadCancelled>()));
    },
  );
}
