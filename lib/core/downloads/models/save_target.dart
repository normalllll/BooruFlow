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
    return SaveTarget(
      type: SaveTargetType.values.byName(json['type'] as String),
      directory: json['directory'] as String?,
      subdirectory: json['subdirectory'] as String?,
    );
  }
}
