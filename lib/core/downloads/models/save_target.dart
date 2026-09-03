import 'download_enums.dart';

class SaveTarget {
  const SaveTarget({required this.type, this.directory, this.subdirectory});

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
  final String? directory;
  final String? subdirectory;

  Map<String, Object?> toJson() {
    return {
      'type': type.name,
      'directory': directory,
      'subdirectory': subdirectory,
    };
  }

  static SaveTarget fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String?;
    final type =
        _saveTargetTypeByName(typeName) ?? SaveTargetType.downloadsFolder;
    return SaveTarget(
      type: type,
      directory: json['directory'] as String?,
      subdirectory: json['subdirectory'] as String?,
    );
  }
}

SaveTargetType? _saveTargetTypeByName(String? name) {
  if (name == null) {
    return null;
  }

  for (final value in SaveTargetType.values) {
    if (value.name == name) {
      return value;
    }
  }
  return null;
}
