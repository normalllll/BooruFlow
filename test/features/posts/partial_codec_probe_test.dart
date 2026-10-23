import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/automation/partial_codec_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('R9 engine partial JPEG/PNG feasibility', () async {
    final result = await partialCodecProbe(
      'test/fixtures/media',
      terminateJpeg: true,
    );
    await File(
      'build/r9-terminated-codec-tester.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
    for (final entry in result.entries.where(
      (entry) => entry.key != 'platform',
    )) {
      final samples = (entry.value as Map)['samples'] as List;
      expect((samples.last as Map)['decoded'], isTrue);
      expect((samples.last as Map)['meanDifference'], 0);
    }
  });
}
