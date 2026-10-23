import 'dart:typed_data';
import 'package:booruflow/core/media/image_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'capability follows the installed writer and writes exactly the supplied PNG',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      Uint8List? written;
      final available = ImageClipboard(
        writePng: (value) async => written = value,
      );
      expect(available.supportsImages, true);
      await available.write(bytes);
      expect(written, same(bytes));
      const absent = ImageClipboard();
      expect(absent.supportsImages, false);
      await expectLater(absent.write(bytes), throwsUnsupportedError);
    },
  );
}
