import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/features/posts/post_attribution.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../discovery/search_interaction_test.dart' show testSource;

Post post(String? author) => Post(
  BooruPost(
    sourceId: 'yande',
    author: author,
    postId: '1',
    postKey: 'yande:1',
    rating: ContentRating.general,
    tags: const [],
    media: const [],
    flags: const PostFlags(
      hasChildren: false,
      isPending: false,
      isDeleted: false,
      isAiGenerated: false,
    ),
  ),
);

void main() {
  setUp(
    () => BooruService.instance.useSourcesForTesting([testSource('yande')]),
  );

  test('source usernames remain separate from the image source', () {
    final item = post(' Alice_日本語 ');
    expect(item.author, 'Alice_日本語');
    expect(item.authorLabel, 'Alice_日本語');
    expect(item.sourceName, 'yande');
  });

  test('missing usernames never use the source name as the author', () {
    for (final name in [null, '', '   ']) {
      expect(post(name).author, isEmpty);
      expect(post(name).authorLabel, t.postDetail.unknownAuthor);
      expect(post(name).sourceName, 'yande');
    }
  });
}
