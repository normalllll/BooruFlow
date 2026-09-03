import 'package:path/path.dart' as p;
import 'package:yande_gui/core/downloads/download_file_system.dart';

String yandePostDownloadFilename({
  required int postId,
  required int variantIndex,
  required Uri sourceUrl,
  String? declaredExtension,
}) {
  final extension =
      _safeExtension(declaredExtension) ??
      _safeExtension(p.extension(sourceUrl.path));
  final variantSuffix = variantIndex == 0 ? '' : '-$variantIndex';
  return safeDownloadFilename(
    'yande-$postId$variantSuffix${extension == null ? '' : '.$extension'}',
  );
}

String? _safeExtension(String? value) {
  final normalized = value?.trim().toLowerCase().replaceFirst('.', '');
  if (normalized == null || !RegExp(r'^[a-z0-9]{1,10}$').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}
