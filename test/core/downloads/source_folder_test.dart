import 'package:flutter_test/flutter_test.dart';
import 'package:booruflow/core/downloads/download_models.dart';

void main() {
  test('download jobs retain source identity and source subfolder', () {
    final job = DownloadJob.create(
      resourceId: 7,
      sourceId: 'anime_pictures',
      postId: '42',
      variantIndex: 3,
      url: Uri.parse('https://anime-pictures.net/image.jpg'),
      filename: '42.jpg',
      saveTarget: const SaveTarget.downloadsFolder(
        subdirectory: 'anime_pictures',
      ),
    );

    expect(job.sourceId, 'anime_pictures');
    expect(job.postId, '42');
    expect(job.saveTarget.toJson()['subdirectory'], 'anime_pictures');
  });
}
