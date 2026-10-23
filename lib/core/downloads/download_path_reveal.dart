import 'dart:io';
import 'package:path/path.dart' as p;
import '../file_paths.dart';

enum DownloadRevealStatus { file, directory, fileMissing, missing }

/// A decision based solely on supplied filesystem facts, before starting a UI.
({DownloadRevealStatus status, String path}) planDownloadReveal({
  required String path,
  required bool directory,
  required FileSystemEntityType type,
  required bool parentExists,
  required p.Style style,
}) {
  final normalized = normalizeLocalPath(path, style: style);
  final context = localPathContext(style: style);
  if (normalized.isEmpty ||
      isNonFileLocation(normalized) ||
      !context.isAbsolute(normalized)) {
    return (status: DownloadRevealStatus.missing, path: normalized);
  }
  if (directory) {
    return (
      status: type == FileSystemEntityType.directory
          ? DownloadRevealStatus.directory
          : DownloadRevealStatus.missing,
      path: normalized,
    );
  }
  if (type == FileSystemEntityType.file) {
    return (status: DownloadRevealStatus.file, path: normalized);
  }
  return parentExists
      ? (
          status: DownloadRevealStatus.fileMissing,
          path: context.dirname(normalized),
        )
      : (status: DownloadRevealStatus.missing, path: normalized);
}

typedef DownloadPathProbe = Future<FileSystemEntityType> Function(String path);
typedef FileManagerLauncher =
    Future<int> Function(
      String executable,
      List<String> arguments, {
      required bool waitForExit,
    });

/// The injected process boundary prevents tests from launching desktop windows.
class DownloadPathRevealer {
  DownloadPathRevealer({
    String? operatingSystem,
    DownloadPathProbe? probe,
    FileManagerLauncher? launch,
  }) : operatingSystem = operatingSystem ?? Platform.operatingSystem,
       _probe = probe ?? FileSystemEntity.type,
       _launch = launch ?? _start;
  final String operatingSystem;
  final DownloadPathProbe _probe;
  final FileManagerLauncher _launch;

  static Future<int> _start(
    String executable,
    List<String> arguments, {
    required bool waitForExit,
  }) async {
    if (waitForExit) return (await Process.run(executable, arguments)).exitCode;
    await Process.start(executable, arguments, mode: ProcessStartMode.detached);
    return 0;
  }

  Future<DownloadRevealStatus> reveal(
    String path, {
    bool directory = false,
  }) async {
    final style = operatingSystem == 'windows'
        ? p.Style.windows
        : p.Style.posix;
    final context = localPathContext(style: style);
    final normalized = normalizeLocalPath(path, style: style);
    if (normalized.isEmpty ||
        isNonFileLocation(normalized) ||
        !context.isAbsolute(normalized)) {
      return DownloadRevealStatus.missing;
    }
    final type = await _probe(normalized);
    final parentExists =
        !directory &&
        type != FileSystemEntityType.file &&
        await _probe(context.dirname(normalized)) ==
            FileSystemEntityType.directory;
    final plan = planDownloadReveal(
      path: normalized,
      directory: directory,
      type: type,
      parentExists: parentExists,
      style: style,
    );
    if (plan.status == DownloadRevealStatus.missing) return plan.status;
    final selected = plan.status == DownloadRevealStatus.file;
    if (operatingSystem == 'linux' && selected) {
      // FileManager1 expects URI strings, including encoding and GVariant quoting.
      final uri = Uri.file(
        plan.path,
        windows: false,
      ).toString().replaceAll(r'\', r'\\').replaceAll("'", r"\'");
      try {
        final code = await _launch('gdbus', [
          'call',
          '--session',
          '--dest',
          'org.freedesktop.FileManager1',
          '--object-path',
          '/org/freedesktop/FileManager1',
          '--method',
          'org.freedesktop.FileManager1.ShowItems',
          "['$uri']",
          "''",
        ], waitForExit: true);
        if (code == 0) return plan.status;
      } on ProcessException {
        // A desktop without gdbus still has the directory-only xdg-open path.
      }
    }
    final (command, arguments) = switch (operatingSystem) {
      // Keep /select, separate from the path: Dart quotes one path argument.
      // Embedded literal quotes would be escaped a second time on Windows.
      'windows' => ('explorer.exe', [if (selected) '/select,', plan.path]),
      'macos' => ('open', [if (selected) '-R', plan.path]),
      'linux' => (
        'xdg-open',
        [selected ? context.dirname(plan.path) : plan.path],
      ),
      _ => throw UnsupportedError(
        'File manager is unavailable on this platform',
      ),
    };
    final code = await _launch(command, arguments, waitForExit: false);
    if (code != 0) {
      throw ProcessException(
        command,
        arguments,
        'File manager launch failed',
        code,
      );
    }
    return plan.status;
  }
}
