import 'dart:io';
import 'package:path/path.dart' as p;

final _windowsPaths = p.Context(style: p.Style.windows);
final _posixPaths = p.Context(style: p.Style.posix);

/// Use the host's file separators; gallery-relative names always opt into POSIX.
p.Context localPathContext({p.Style? style}) =>
    (style ?? (Platform.isWindows ? p.Style.windows : p.Style.posix)) ==
        p.Style.windows
    ? _windowsPaths
    : _posixPaths;

/// URI-backed media locations are identifiers, never filesystem paths.
bool isNonFileLocation(String value) {
  if (value.indexOf(':') <= 1) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.hasScheme &&
      uri.scheme.length > 1 &&
      uri.scheme != 'file';
}

/// One normalization for saving, persistence, presentation and file-manager IO.
/// Mixed separators in old records are accepted, while content/ph URIs survive.
String normalizeLocalPath(String value, {p.Style? style}) {
  if (value.isEmpty || isNonFileLocation(value)) return value;
  final context = localPathContext(style: style);
  if (value.startsWith('file:')) {
    final uri = Uri.tryParse(value);
    if (uri == null) return value;
    try {
      value = uri.toFilePath(windows: context.style == p.Style.windows);
    } on UnsupportedError {
      return value;
    }
  }
  return context.normalize(
    context.style == p.Style.windows ? value : value.replaceAll(r'\', '/'),
  );
}
