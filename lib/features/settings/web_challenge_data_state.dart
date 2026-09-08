import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';

final webDataRevisionProvider = NotifierProvider<WebDataRevision, int>(
  WebDataRevision.new,
);

class WebDataRevision extends Notifier<int> {
  @override
  int build() {
    final revision = BooruService.instance.revision;
    void changed() => state = revision.value;
    revision.addListener(changed);
    ref.onDispose(() => revision.removeListener(changed));
    return revision.value;
  }
}

typedef WebDataRequest = ({
  String sourceId,
  Future<WebChallengeState> Function(String)? read,
});
final webChallengeDataProvider = FutureProvider.autoDispose
    .family<WebChallengeState, WebDataRequest>((ref, request) {
      ref.watch(webDataRevisionProvider);
      return request.read?.call(request.sourceId) ??
          BooruService.instance.engine.webChallengeState(
            sourceId: request.sourceId,
          );
    });
