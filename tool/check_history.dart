// Checks commits before they leave this checkout.
//
//   dart tool/check_history.dart                 commits not yet on upstream
//   dart tool/check_history.dart --range A..B    the commits in A..B
//   dart tool/check_history.dart --staged        the staged diff
//   dart tool/check_history.dart --message FILE  a commit message
//   dart tool/check_history.dart --pre-push R    the refs git hands pre-push
//
// Commit text describes the code, not how it was made. History stays linear,
// fixes to unpushed work are folded into that work, and ignored files stay
// local. Exits 1 and lists every problem when a check fails.
import 'dart:convert';
import 'dart:io';

const _types = 'feat|fix|chore|docs|refactor|test|perf|build|ci|style|revert';
final _subject = RegExp(
  '^($_types)(\\([a-z0-9_./-]+\\))?!?: [a-z0-9`].*[^.]\$',
);
final _fixup = RegExp(r'^(fixup|squash|amend)! ');
final _zero = RegExp(r'^0+$');
final _fixType = RegExp(r'^fix[(!:]');
final _featureType = RegExp(r'^(feat|refactor)[(!:]');

/// Text that belongs to a plan, a review or a conversation, not to the code.
final _textRules = <(String, RegExp)>[
  (
    'plan label',
    RegExp(
      r'''(['"])[A-Z][0-9]{1,2} |//+ -*\s*[A-Z][0-9]{1,2}\b|\bR[0-9]{2}\b''',
    ),
  ),
  (
    'stage or round number',
    RegExp(r'\b(stage|round|phase|batch|wave) [0-9]+\b', caseSensitive: false),
  ),
  (
    'spec section',
    RegExp(r'(§|\b(section|item) )[0-9]+(\.[0-9]+)+', caseSensitive: false),
  ),
  ('request ID', RegExp(r'\b[a-z][a-z0-9_]*-20[0-9]{6}-[a-z0-9][a-z0-9-]*')),
  ('local path', _localPaths()),
  (
    'decision history',
    RegExp(
      r'\b(owner (said|asked|decided|confirmed)|'
      r'per the (brief|spec|plan)|review feedback|handoff note|'
      r'acceptance (case|item)s?|as discussed|issues found in)\b',
      caseSensitive: false,
    ),
  ),
];

/// Only commit messages: tool attribution.
final _messageRules = <(String, RegExp)>[
  (
    'tool attribution',
    RegExp(r'co-authored-by|generated (with|by)', caseSensitive: false),
  ),
];

/// This machine's folders: the one holding the checkouts, and home. Paths of
/// other shapes (test fixtures such as C:\Users\fixture) are fine.
RegExp _localPaths() {
  final top = _git(['rev-parse', '--show-toplevel']).trim();
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  final folders = [File(top).parent.path, ?home]
      .map((path) => path.split(RegExp(r'[\\/]+')).where((s) => s.isNotEmpty))
      .where((segments) => segments.length >= 2)
      .map((segments) => segments.map(RegExp.escape).join(r'[\\/]+'));
  return RegExp(
    '(${folders.join('|')})'
    r'([\\/]|\b)',
    caseSensitive: false,
  );
}

/// New file names that carry a plan stage, such as stage3_tags_test.dart.
final _planPath = RegExp(r'(^|[/_])(stage|round|phase|wave)[0-9]');

/// Lines that may name a request ID by design.
final _allowedLine = RegExp(r'frost-escape:');

/// Files whose added lines are not written by hand, or that quote the rules.
bool _skipsContent(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.lock') ||
    path.endsWith('.svg') ||
    path.endsWith('frb_generated.rs') ||
    path.endsWith('frb_generated.dart') ||
    path.startsWith('lib/src/rust/') ||
    path.contains('check_history');

final _problems = <String>[];

void main(List<String> args) {
  final mode = args.isEmpty ? '' : args.first;
  switch (mode) {
    case '--staged':
      _checkStaged();
    case '--message':
      _checkMessageFile(File(args[1]).readAsStringSync());
    case '--range':
      _checkRange(args[1]);
    case '--pre-push':
      _checkPrePush(args.length > 1 ? args[1] : 'origin');
    default:
      _checkRange(_defaultRange());
  }
  if (_problems.isEmpty) return;
  stderr.writeln('check_history: ${_problems.length} problem(s)');
  for (final problem in _problems) {
    stderr.writeln('  $problem');
  }
  exitCode = 1;
}

String _defaultRange() {
  final upstream = Process.runSync('git', [
    'rev-parse',
    '--abbrev-ref',
    '@{upstream}',
  ]);
  final base = upstream.exitCode == 0
      ? (upstream.stdout as String).trim()
      : 'origin/main';
  return '$base..HEAD';
}

void _checkStaged() {
  final added = _git(['diff', '--cached', '--name-only', '--diff-filter=A'])
      .split('\n')
      .where((p) => p.isNotEmpty)
      .toList();
  _checkAddedFiles('staged', added);
  _checkDiff(
    'staged',
    _git(['diff', '--cached', '-U0', '--no-color', '--no-ext-diff']),
  );
}

/// A message as git hands it to commit-msg: comment lines and everything
/// below the scissors line of `git commit -v` are not part of it.
void _checkMessageFile(String text) {
  final lines = <String>[];
  for (final line in const LineSplitter().convert(text)) {
    if (line.startsWith('# ------------------------ >8')) break;
    if (!line.startsWith('#')) lines.add(line);
  }
  final message = lines.join('\n');
  final subject = lines.firstWhere(
    (l) => l.trim().isNotEmpty,
    orElse: () => '',
  );
  // git commit --fixup writes these; the rebase before a push folds them.
  if (!_fixup.hasMatch(subject)) _checkSubject('commit', subject);
  _checkMessage('commit', message);
}

void _checkSubject(String where, String subject) {
  if (!_subject.hasMatch(subject)) {
    _problems.add(
      '$where: subject "$subject" is not "type(scope): summary" in lower '
      'case without a trailing period',
    );
  }
}

void _checkAddedFiles(String where, List<String> added) {
  for (final path in added.where(_planPath.hasMatch)) {
    _problems.add('$where: file name carries a plan stage: $path');
  }
  if (added.isEmpty) return;
  for (final path in _ignored(added)) {
    _problems.add('$where: adds ignored file $path');
  }
}

void _checkPrePush(String remote) {
  // Git writes one line per ref: <local ref> <local sha> <remote ref> <remote sha>.
  String? line;
  while ((line = stdin.readLineSync(encoding: utf8)) != null) {
    final parts = line!.trim().split(' ');
    if (parts.length < 4 || _zero.hasMatch(parts[1])) continue;
    final base = _zero.hasMatch(parts[3]) ? '$remote/main' : parts[3];
    _checkRange('$base..${parts[1]}');
  }
}

void _checkRange(String range) {
  final shas = _git(['rev-list', '--reverse', range])
      .split('\n')
      .where((s) => s.isNotEmpty)
      .toList();
  final files = <String, Set<String>>{};
  final created = <String, Set<String>>{};
  final subjects = <String, String>{};
  for (final sha in shas) {
    final short = sha.substring(0, 7);
    final message = _git(['log', '-1', '--format=%B', sha]);
    final subject = message.split('\n').first.trim();
    subjects[sha] = subject;
    final where = '$short $subject';
    final parents = _git(['log', '-1', '--format=%P', sha]).trim().split(' ');
    if (parents.length > 1) {
      _problems.add('$where: merge commit; rebase onto the base instead');
      continue;
    }
    if (_fixup.hasMatch(subject)) {
      _problems.add(
        '$where: fixup left over; squash it with '
        'GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>',
      );
    } else {
      _checkSubject(short, subject);
    }
    _checkMessage(short, message);

    final status = _git([
      'diff-tree',
      '--no-commit-id',
      '--name-status',
      '-r',
      '--root',
      sha,
    ]);
    final touched = <String>{};
    final added = <String>[];
    for (final row in status.split('\n').where((r) => r.isNotEmpty)) {
      final cells = row.split('\t');
      touched.add(cells.last);
      if (cells.first == 'A') added.add(cells.last);
    }
    files[sha] = touched;
    created[sha] = added.toSet();
    _checkAddedFiles(where, added);
    _checkDiff(
      short,
      _git(['show', '--format=', '-U0', '--no-color', '--no-ext-diff', sha]),
    );
  }

  // A fix to a feature that has not left this checkout belongs in that feature.
  for (final sha in shas) {
    if (!_fixType.hasMatch(subjects[sha]!)) continue;
    for (final other in shas) {
      if (other == sha || !_featureType.hasMatch(subjects[other]!)) continue;
      // Only files the feature created: a wide refactor touches most files,
      // and a later fix to old code there is still its own change.
      final shared = files[sha]!.intersection(created[other]!);
      if (shared.isEmpty) continue;
      _problems.add(
        '${sha.substring(0, 7)} ${subjects[sha]}: changes ${shared.join(', ')}, '
        'created by unpushed ${other.substring(0, 7)} ${subjects[other]}; '
        'fold it into that commit',
      );
      break;
    }
  }
}

void _checkMessage(String where, String message) {
  for (final line in message.split('\n')) {
    for (final (name, rule) in [..._textRules, ..._messageRules]) {
      final match = rule.firstMatch(line);
      if (match != null) {
        _problems.add('$where message: $name "${match[0]!.trim()}"');
      }
    }
  }
}

void _checkDiff(String where, String diff) {
  String? path;
  for (final line in diff.split('\n')) {
    if (line.startsWith('+++ ')) {
      path = line.startsWith('+++ b/') ? line.substring(6) : null;
      continue;
    }
    if (path == null || !line.startsWith('+') || _skipsContent(path)) continue;
    if (_allowedLine.hasMatch(line)) continue;
    for (final (name, rule) in _textRules) {
      final match = rule.firstMatch(line);
      if (match != null) {
        _problems.add('$where $path: $name "${match[0]!.trim()}"');
      }
    }
  }
}

String _git(List<String> args) {
  final result = Process.runSync(
    'git',
    args,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    stderr.writeln('git ${args.join(' ')} failed: ${result.stderr}');
    exit(2);
  }
  return result.stdout as String;
}

/// The [paths] that .gitignore excludes. check-ignore exits 1 when none are.
List<String> _ignored(List<String> paths) {
  final result = Process.runSync('git', [
    'check-ignore',
    '--no-index',
    '--',
    ...paths,
  ], stdoutEncoding: utf8);
  return (result.stdout as String)
      .split('\n')
      .where((p) => p.isNotEmpty)
      .toList();
}
