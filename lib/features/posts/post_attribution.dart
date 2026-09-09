import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/features/posts/models/post.dart';
import 'package:booruflow/intl/translations.g.dart';

extension PostAttribution on Post {
  String get authorLabel =>
      author.isEmpty ? t.postDetail.unknownAuthor : author;

  String get sourceName {
    for (final source in BooruService.instance.sources) {
      if (source.sourceId == sourceId) return source.displayName;
    }
    return sourceId;
  }
}
