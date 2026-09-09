import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'web_challenge_logic.g.dart';

@Riverpod(keepAlive: true)
WebChallengeService webChallengeService(Ref ref) =>
    WebChallengeService(ref.watch(booruServiceProvider));

@riverpod
class WebChallengeSession extends _$WebChallengeSession {
  @override
  WebChallengeSessionState build(WebChallengeService service) {
    final subscription = service.changes.listen((session) => state = session);
    ref.onDispose(subscription.cancel);
    return service.session;
  }

  Future<bool> resolve(BuildContext context, String sourceId) =>
      service.resolve(context, sourceId);
  Future<void> clearSources(List<String> sources) =>
      service.clearSources(sources);
}

typedef WebDataRequest = ({
  String sourceId,
  Future<WebChallengeState> Function(String)? read,
});
@riverpod
Future<WebChallengeState> webChallengeData(Ref ref, WebDataRequest request) {
  ref.watch(booruSessionProvider.select((value) => value.revision));
  return request.read?.call(request.sourceId) ??
      ref
          .read(booruServiceProvider)
          .engine
          .webChallengeState(sourceId: request.sourceId);
}
