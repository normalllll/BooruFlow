import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all locale copy values omit ellipses', () {
    final files = Directory('lib/intl')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.i18n.yaml'))
        .toList();
    expect(files, hasLength(4));
    final issues = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (final (index, line) in lines.indexed) {
        if (line.trimLeft().startsWith('#')) continue;
        if (line.contains('…') || line.contains('...')) {
          issues.add('${file.path}:${index + 1}: $line');
        }
      }
    }
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  test('runtime copy does not append ellipses', () {
    final issues = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') ||
          file.path.endsWith('.g.dart') ||
          file.path.endsWith('.freezed.dart')) {
        continue;
      }
      for (final (index, line) in file.readAsLinesSync().indexed) {
        // MD5 uses a measured visual abbreviation; the complete value remains
        // selectable/copyable. This is layout truncation rather than UI copy.
        final md5Layout =
            file.path.endsWith('post_detail_panel.dart') &&
            line.contains('post.md5.substring');
        if ((line.contains('…') && !md5Layout) ||
            line.contains("...'") ||
            line.contains('..."')) {
          issues.add('${file.path}:${index + 1}: $line');
        }
      }
    }
    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}
