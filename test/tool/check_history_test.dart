@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _script = File('tool/check_history.dart').absolute.path;

void main() {
  late Directory root;
  late String repo;

  String git(List<String> args) {
    final result = Process.runSync('git', args, workingDirectory: repo);
    if (result.exitCode != 0) fail('git ${args.join(' ')}: ${result.stderr}');
    return (result.stdout as String).trim();
  }

  void write(String path, String text) {
    File('$repo/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  void commit(String message, Map<String, String> files) {
    files.forEach(write);
    git(['add', '-A']);
    git(['commit', '-q', '-m', message]);
  }

  /// Runs the check in the test repository and returns its exit code and the
  /// problems it printed.
  Future<(int, String)> check(List<String> args, {String input = ''}) async {
    final home = '${root.path}/home';
    final process = await Process.start(
      'dart',
      [_script, ...args],
      workingDirectory: repo,
      environment: {'HOME': home, 'USERPROFILE': home},
      // dart is a batch file on Windows.
      runInShell: Platform.isWindows,
    );
    process.stdin.write(input);
    await process.stdin.close();
    final problems = process.stderr.transform(utf8.decoder).join();
    await process.stdout.drain<void>();
    return (await process.exitCode, await problems);
  }

  Future<String> problems(List<String> args) async => (await check(args)).$2;

  setUp(() {
    root = Directory.systemTemp.createTempSync('check_history_');
    repo = '${root.path}/repo';
    Directory(repo).createSync();
    git(['init', '-q', '-b', 'main']);
    git(['config', 'user.name', 'Test']);
    git(['config', 'user.email', 'test@example.com']);
    git(['config', 'core.autocrlf', 'false']);
    commit('chore: start', {
      '.gitignore': 'docs/\n',
      'lib/old.dart': 'void old() {}\n',
    });
    git(['tag', 'base']);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('passes clean history, including a fix to code from before', () async {
    commit('feat(tags): add the tag list', {'lib/tags.dart': 'void a() {}\n'});
    commit('fix(old): handle an empty name', {'lib/old.dart': 'void b() {}\n'});
    expect(await check(['--range', 'base..HEAD']), (0, ''));
  });

  test('asks to fold a fix into the unpushed feature it corrects', () async {
    commit('feat(tags): add the tag list', {'lib/tags.dart': 'void a() {}\n'});
    commit('fix(tags): sort the list', {'lib/tags.dart': 'void b() {}\n'});
    final (code, out) = await check(['--range', 'base..HEAD']);
    expect(code, 1);
    expect(out, contains('fold it into that commit'));
  });

  test('rejects leftover fixups, merges and malformed subjects', () async {
    commit('feat(tags): add the tag list', {'lib/tags.dart': 'void a() {}\n'});
    commit('fixup! feat(tags): add the tag list', {'lib/tags.dart': '//\n'});
    git(['checkout', '-q', '-b', 'side', 'base']);
    commit('Add a readme.', {'README.md': 'text\n'});
    git(['checkout', '-q', 'main']);
    git(['merge', '-q', '--no-edit', 'side']);
    final out = await problems(['--range', 'base..HEAD']);
    expect(out, contains('fixup left over'));
    expect(out, contains('merge commit'));
    expect(out, contains('subject "Add a readme." is not'));
  });

  test('finds plan and conversation text in code and messages', () async {
    commit('test: lock the stage 3 cases', {
      'test/stage3_tags_test.dart': "test('A5 shows counts', () {});\n",
      'lib/a.dart': '// Requirement: ${root.path}/frost_ui/docs/PLAN.md\n',
      'lib/b.dart': '// Applies the review feedback.\n',
    });
    final out = await problems(['--range', 'base..HEAD']);
    expect(out, contains('message: stage or round number "stage 3"'));
    expect(out, contains('file name carries a plan stage'));
    expect(out, contains('plan label'));
    expect(out, contains('local path'));
    expect(out, contains('decision history "review feedback"'));
  });

  test('allows request IDs only on frost-escape lines', () async {
    commit('feat(ui): draw the wave', {
      'lib/wave.dart':
          '// frost-escape: booruflow-20261029-mixed-input-density\n'
          '// See booruflow-20261102-ambient-transition-cost.\n',
    });
    final out = await problems(['--range', 'base..HEAD']);
    expect(out, contains('request ID "booruflow-20261102-ambient'));
    expect(out, isNot(contains('mixed-input-density')));
  });

  test('rejects files that .gitignore keeps local', () async {
    write('docs/handoff.md', 'notes\n');
    git(['add', '-f', 'docs/handoff.md']);
    expect(
      await problems(['--staged']),
      contains('adds ignored file docs/handoff.md'),
    );
    git(['commit', '-q', '-m', 'docs: add notes']);
    expect(
      await problems(['--range', 'base..HEAD']),
      contains('adds ignored file docs/handoff.md'),
    );
  });

  test('checks the staged diff', () async {
    write('lib/c.dart', '// Stage 2 layout\n');
    git(['add', '-A']);
    final (code, out) = await check(['--staged']);
    expect(code, 1);
    expect(out, contains('stage or round number'));
  });

  test('checks a message and accepts fixup subjects', () async {
    final message = File('${root.path}/MSG');
    message.writeAsStringSync(
      'fix(posts): apply stage 5 review feedback\n\n'
      'Co-Authored-By: someone\n'
      '# R99 is a comment\n'
      '# ------------------------ >8 ------------------------\n'
      'R20 in the diff below the scissors\n',
    );
    final out = await problems(['--message', message.path]);
    expect(out, contains('stage or round number'));
    expect(out, contains('tool attribution'));
    expect(out, isNot(contains('R99')));
    expect(out, isNot(contains('R20')));

    message.writeAsStringSync('fixup! feat(tags): add the tag list\n');
    expect(await check(['--message', message.path]), (0, ''));
    message.writeAsStringSync('Update stuff\n');
    expect(await problems(['--message', message.path]), contains('is not'));
  });

  test('checks the refs git hands to pre-push', () async {
    final base = git(['rev-parse', 'base']);
    commit('feat(tags): add the tag list', {'lib/tags.dart': 'void a() {}\n'});
    commit('fix(tags): sort the list', {'lib/tags.dart': 'void b() {}\n'});
    final head = git(['rev-parse', 'HEAD']);
    final (code, out) = await check([
      '--pre-push',
      'origin',
    ], input: 'refs/heads/main $head refs/heads/main $base\n');
    expect(code, 1);
    expect(out, contains('fold it into that commit'));
  });
}
