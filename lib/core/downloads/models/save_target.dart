import 'download_enums.dart';

class SaveTarget {
  const SaveTarget({required this.type, this.directory});

  const SaveTarget.downloadsFolder({String? directory})
    : this(type: SaveTargetType.downloadsFolder, directory: directory);

  const SaveTarget.mediaStore() : this(type: SaveTargetType.mediaStore);

  const SaveTarget.photos() : this(type: SaveTargetType.photos);

  final SaveTargetType type;
  final String? directory;

  Map<String, Object?> toJson() {
    return {'type': type.name, 'directory': directory};
  }

  static SaveTarget fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String?;
    final type =
        _saveTargetTypeByName(typeName) ?? SaveTargetType.downloadsFolder;
    return SaveTarget(type: type, directory: json['directory'] as String?);
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
