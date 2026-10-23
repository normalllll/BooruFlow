import 'package:booruflow/core/file_paths.dart';
import 'package:path/path.dart' as p;
import 'download_enums.dart';

class SaveTarget {
  const SaveTarget({required this.type, this._directory, this._subdirectory});

  const SaveTarget.downloadsFolder({String? directory, String? subdirectory})
    : this(
        type: SaveTargetType.downloadsFolder,
        directory: directory,
        subdirectory: subdirectory,
      );

  const SaveTarget.mediaStore({String? subdirectory})
    : this(type: SaveTargetType.mediaStore, subdirectory: subdirectory);

  const SaveTarget.photos({String? subdirectory})
    : this(type: SaveTargetType.photos, subdirectory: subdirectory);

  final SaveTargetType type;
  final String? _directory, _subdirectory;
  String? get directory =>
      _directory == null ? null : normalizeLocalPath(_directory);
  String? get subdirectory => _subdirectory == null
      ? null
      : normalizeLocalPath(
          _subdirectory,
          style: type == SaveTargetType.downloadsFolder ? null : p.Style.posix,
        );

  Map<String, Object?> toJson() {
    return {
      'type': type.name,
      'directory': directory,
      'subdirectory': subdirectory,
    };
  }

  static SaveTarget fromJson(Map<String, Object?> json) {
    return SaveTarget(
      type: SaveTargetType.values.byName(json['type'] as String),
      directory: json['directory'] as String?,
      subdirectory: json['subdirectory'] as String?,
    );
  }
}
