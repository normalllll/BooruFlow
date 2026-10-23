import 'package:booruflow/core/downloads/models/save_target.dart';
import 'package:booruflow/core/file_paths.dart';
import 'package:booruflow/features/downloads/batch/logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'Windows paths normalize mixed separators without losing spaces, Unicode, UNC or punctuation',
    () {
      const raw = r'C:\Users\夾具\Downloads\BooruFlow\yande/muryo\363100 (1).png';
      expect(
        normalizeLocalPath(raw, style: p.Style.windows),
        r'C:\Users\夾具\Downloads\BooruFlow\yande\muryo\363100 (1).png',
      );
      expect(
        normalizeLocalPath(
          r'\\server\share/圖片/a (1),&.png',
          style: p.Style.windows,
        ),
        r'\\server\share\圖片\a (1),&.png',
      );
      expect(
        normalizeLocalPath(
          'C:/Images/../Downloads/a.png',
          style: p.Style.windows,
        ),
        r'C:\Downloads\a.png',
      );
      expect(
        normalizeLocalPath(
          'file:///C:/My%20Images/%E5%9B%BE.png',
          style: p.Style.windows,
        ),
        r'C:\My Images\图.png',
      );
    },
  );
  test(
    'POSIX and gallery-relative names use slash; URI identifiers remain opaque',
    () {
      expect(
        normalizeLocalPath(
          r'/home/fixture/Downloads\BooruFlow/yande\muryo/a.png',
          style: p.Style.posix,
        ),
        '/home/fixture/Downloads/BooruFlow/yande/muryo/a.png',
      );
      for (final uri in [
        'content://media/external/images/1',
        'ph://asset/123',
        'assets-library://asset?id=1',
      ]) {
        for (final style in [p.Style.windows, p.Style.posix]) {
          expect(normalizeLocalPath(uri, style: style), uri);
        }
      }
      expect(
        const SaveTarget.mediaStore(subdirectory: r'yande\batch').subdirectory,
        'yande/batch',
      );
      expect(
        const SaveTarget.photos(
          subdirectory: r'yande\batch',
        ).toJson()['subdirectory'],
        'yande/batch',
      );
      expect(normalizeLocalPath(''), '');
    },
  );
  test(
    'batch names reject path separators rather than creating accidental nesting',
    () {
      for (final name in ['a/b', r'a\b', '.', '..']) {
        expect(validBatchFolder(name), isFalse, reason: name);
        expect(
          () => const BatchSaveLocation(
            root: '/fixture',
            target: SaveTarget.mediaStore(),
          ).folder(name),
          throwsArgumentError,
        );
      }
      expect(validBatchFolder('初音 (1)'), isTrue);
    },
  );
}
