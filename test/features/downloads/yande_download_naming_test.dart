import 'package:flutter_test/flutter_test.dart';
import 'package:yande_gui/features/downloads/domain/yande_download_naming.dart';

void main() {
  test('filename is readable and always contains the post id', () {
    expect(
      yandePostDownloadFilename(
        postId: 987654,
        variantIndex: 0,
        sourceUrl: Uri.parse('https://assets.yande.re/random/file.jpeg'),
      ),
      'yande-987654.jpeg',
    );
  });

  test('declared extension wins and later variants stay distinguishable', () {
    expect(
      yandePostDownloadFilename(
        postId: 42,
        variantIndex: 3,
        sourceUrl: Uri.parse('https://assets.yande.re/no-extension'),
        declaredExtension: '.PNG',
      ),
      'yande-42-3.png',
    );
  });
}
