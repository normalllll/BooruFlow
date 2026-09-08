import 'package:booruflow/features/downloads/download_naming.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filename is readable and always contains the post id', () {
    expect(
      booruPostDownloadFilename(
        postId: 987654,
        variantIndex: 0,
        sourceUrl: Uri.parse('https://assets.yande.re/random/file.jpeg'),
      ),
      '987654.jpeg',
    );
  });

  test('declared extension wins and later variants stay distinguishable', () {
    expect(
      booruPostDownloadFilename(
        postId: 42,
        variantIndex: 3,
        sourceUrl: Uri.parse('https://assets.yande.re/no-extension'),
        declaredExtension: '.PNG',
      ),
      '42-3.png',
    );
  });
}
