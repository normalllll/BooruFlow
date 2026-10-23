import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English settings labels use sentence case', () {
    // Product names, system destinations and literal HTTP header names keep
    // their spelling. Acronyms such as API, DNS and ID are allowed separately.
    const names = [
      'BooruFlow',
      'WebP',
      'Photos',
      'Files',
      'Downloads',
      'User-Agent',
    ];
    const sections = {'settings', 'settingsV2', 'settingsDetails', 'ugoira'};
    final issues = <String>[];
    final scannedSections = <String>{};
    final lines = File('lib/intl/en.i18n.yaml').readAsLinesSync();
    var section = '';
    var checked = 0;
    for (var i = 0; i < lines.length; i++) {
      if (RegExp(r'^[A-Za-z][A-Za-z0-9]*:$').hasMatch(lines[i])) {
        section = lines[i].substring(0, lines[i].length - 1);
      }
      if (!sections.contains(section)) continue;
      final match = RegExp(r'^ +([A-Za-z0-9_]+): +(.+)$').firstMatch(lines[i]);
      if (match == null) continue;
      var label = match[2]!.replaceAll('...', '…');
      // This guard covers short row titles, options and actions. Paragraphs
      // have independent sentence starts and are reviewed as prose.
      if (RegExp(r'[.!?:;]').hasMatch(label)) continue;
      label = label.replaceAll(RegExp(r'\$\{?\w+\}?'), '');
      for (final name in names) {
        label = label.replaceAll(name, name.toLowerCase());
      }
      final words = RegExp(r'[A-Za-z]+(?:-[A-Za-z]+)*').allMatches(label);
      checked++;
      scannedSections.add(section);
      for (final word in words.skip(1)) {
        final text = word[0]!;
        if (!RegExp(r'^[A-Z]{2,}s?$').hasMatch(text) &&
            RegExp('[A-Z]').hasMatch(text)) {
          issues.add('${i + 1}: ${match[1]} contains noninitial capital $text');
        }
      }
    }
    expect(
      checked,
      greaterThan(100),
      reason: 'Settings labels must be scanned.',
    );
    expect(scannedSections, sections);
    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}
