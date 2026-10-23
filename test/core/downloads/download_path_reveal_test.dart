import 'dart:io';
import 'package:booruflow/core/downloads/download_path_reveal.dart';
import 'package:booruflow/core/file_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _Commands {
  final calls = <(String, List<String>, bool)>[];
  int busResult = 0;
  bool missingBus = false;
  Future<int> call(
    String executable,
    List<String> arguments, {
    required bool waitForExit,
  }) async {
    calls.add((executable, List.of(arguments), waitForExit));
    if (executable == 'gdbus') {
      if (missingBus) {
        throw ProcessException(
          executable,
          arguments,
          'fixture missing executable',
        );
      }
      return busResult;
    }
    return 0;
  }
}

void expectCommand(
  (String, List<String>, bool) actual,
  String executable,
  List<String> arguments,
  bool wait,
) {
  expect(actual.$1, executable);
  expect(actual.$2, arguments);
  expect(actual.$3, wait);
}

void main() {
  const mixed =
      r'C:\Users\fixture\Downloads\BooruFlow\yande/muryo\363100 (1).png';
  const canonical =
      r'C:\Users\fixture\Downloads\BooruFlow\yande\muryo\363100 (1).png';
  test(
    'pure reveal planning uses normalized facts and never invents a fallback directory',
    () {
      for (final missingParent in [false, true]) {
        final plan = planDownloadReveal(
          path: mixed,
          directory: false,
          type: FileSystemEntityType.notFound,
          parentExists: !missingParent,
          style: p.Style.windows,
        );
        expect(
          plan.status,
          missingParent
              ? DownloadRevealStatus.missing
              : DownloadRevealStatus.fileMissing,
        );
        expect(
          plan.path,
          missingParent ? canonical : p.windows.dirname(canonical),
        );
      }
      expect(
        planDownloadReveal(
          path: mixed,
          directory: true,
          type: FileSystemEntityType.notFound,
          parentExists: true,
          style: p.Style.windows,
        ).status,
        DownloadRevealStatus.missing,
      );
    },
  );
  test(
    'Windows selects one correctly quoted path argument, keeping flag separate from Unicode/space/comma content',
    () async {
      final commands = _Commands();
      final probed = <String>[];
      final revealer = DownloadPathRevealer(
        operatingSystem: 'windows',
        launch: commands.call,
        probe: (path) async {
          probed.add(path);
          return FileSystemEntityType.file;
        },
      );
      expect(await revealer.reveal(mixed), DownloadRevealStatus.file);
      expect(probed, [canonical]);
      expect(commands.calls, hasLength(1));
      expectCommand(commands.calls.single, 'explorer.exe', [
        '/select,',
        canonical,
      ], false);
      commands.calls.clear();
      const special = r'C:\My Pictures\图 (1),&.png';
      await revealer.reveal(special);
      expect(commands.calls.single.$2, ['/select,', special]);
    },
  );
  test(
    'macOS reveals file with open -R and directory as its own argument',
    () async {
      final commands = _Commands();
      final revealer = DownloadPathRevealer(
        operatingSystem: 'macos',
        launch: commands.call,
        probe: (path) async => path.endsWith('.png')
            ? FileSystemEntityType.file
            : FileSystemEntityType.directory,
      );
      await revealer.reveal('/Users/fixture/My Pictures/图 (1).png');
      expectCommand(commands.calls.single, 'open', [
        '-R',
        '/Users/fixture/My Pictures/图 (1).png',
      ], false);
      commands.calls.clear();
      await revealer.reveal('/Users/fixture/My Pictures', directory: true);
      expectCommand(commands.calls.single, 'open', [
        '/Users/fixture/My Pictures',
      ], false);
    },
  );
  for (final failure in ['none', 'exit', 'missing-executable']) {
    test(
      'Linux ShowItems sends a URI then directory fallback only on DBus failure: $failure',
      () async {
        final commands = _Commands()
          ..busResult = failure == 'exit' ? 1 : 0
          ..missingBus = failure == 'missing-executable';
        final revealer = DownloadPathRevealer(
          operatingSystem: 'linux',
          launch: commands.call,
          probe: (_) async => FileSystemEntityType.file,
        );
        const path = "/home/fixture/My Pictures/图's (1).png";
        await revealer.reveal(path);
        expect(commands.calls.first.$1, 'gdbus');
        expect(commands.calls.first.$3, isTrue);
        expect(
          commands.calls.first.$2,
          contains('org.freedesktop.FileManager1.ShowItems'),
        );
        final uri = Uri.file(path).toString().replaceAll("'", r"\'");
        expect(commands.calls.first.$2, contains("['$uri']"));
        if (failure == 'none') {
          expect(commands.calls, hasLength(1));
        } else {
          expectCommand(commands.calls.last, 'xdg-open', [
            '/home/fixture/My Pictures',
          ], false);
        }
      },
    );
  }
  test(
    'real temporary download exists, disappears, then loses its folder without launching any real desktop UI',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'booruflow-r8-reveal-',
      );
      addTearDown(() async {
        expect(root.absolute.parent.path, Directory.systemTemp.absolute.path);
        await root.delete(recursive: true);
      });
      final folder = Directory(
        p.join(root.path, 'Downloads', 'BooruFlow', 'yande', 'muryo'),
      );
      await folder.create(recursive: true);
      final file = File(p.join(folder.path, '363100 (1).png'));
      await file.writeAsString('fixture');
      final commands = _Commands();
      final revealer = DownloadPathRevealer(launch: commands.call);
      expect(
        await revealer.reveal(file.path.replaceAll('\\', '/')),
        DownloadRevealStatus.file,
      );
      expect(commands.calls.single.$2.last, normalizeLocalPath(file.path));
      commands.calls.clear();
      await file.delete();
      expect(
        await revealer.reveal(file.path),
        DownloadRevealStatus.fileMissing,
      );
      expect(commands.calls.single.$2, [folder.path]);
      commands.calls.clear();
      await folder.delete();
      expect(await revealer.reveal(file.path), DownloadRevealStatus.missing);
      expect(commands.calls, isEmpty);
    },
  );
  test(
    'missing directory, relative and URI locations never probe a default path or launch a manager',
    () async {
      final commands = _Commands();
      final probed = <String>[];
      final revealer = DownloadPathRevealer(
        operatingSystem: 'windows',
        launch: commands.call,
        probe: (path) async {
          probed.add(path);
          return FileSystemEntityType.notFound;
        },
      );
      expect(
        await revealer.reveal(r'C:\missing', directory: true),
        DownloadRevealStatus.missing,
      );
      expect(probed, [r'C:\missing']);
      probed.clear();
      for (final path in [
        '',
        'relative.png',
        'content://media/1',
        'ph://asset/1',
      ]) {
        expect(await revealer.reveal(path), DownloadRevealStatus.missing);
      }
      expect(probed, isEmpty);
      expect(commands.calls, isEmpty);
    },
  );
}
