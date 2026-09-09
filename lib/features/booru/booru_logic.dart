import 'package:booruflow/features/booru/services/booru_service.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'booru_logic.g.dart';

@Riverpod(keepAlive: true)
BooruService booruService(Ref ref) => BooruService.instance;

class BooruSessionState {
  const BooruSessionState({required this.sourceId, required this.revision});
  final String sourceId;
  final int revision;
}

@Riverpod(keepAlive: true)
class BooruSession extends _$BooruSession {
  @override
  BooruSessionState build() {
    final service = ref.watch(booruServiceProvider);
    BooruSessionState snapshot() => BooruSessionState(
      sourceId: service.selectedSourceId,
      revision: service.revision,
    );
    final subscription = service.changes.listen((_) => state = snapshot());
    ref.onDispose(subscription.cancel);
    return snapshot();
  }

  void selectSource(String id) =>
      ref.read(booruServiceProvider).selectSource(id);
}

@Riverpod(keepAlive: true)
List<BooruSource> booruSources(Ref ref) {
  ref.watch(booruSessionProvider.select((value) => value.revision));
  return ref.watch(booruServiceProvider).sources;
}
