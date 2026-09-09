import 'dart:async';

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/features/discovery/collection_logic.dart';
import 'package:booruflow/features/discovery/services/discovery_availability.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_logic.g.dart';

@Riverpod(keepAlive: true)
class FeedSelection extends _$FeedSelection {
  @override
  Map<String, FeedCollectionRequest> build() => const {};
  void select(String sourceId, FeedCollectionRequest request) =>
      state = Map.unmodifiable({...state, sourceId: request});
}

@Riverpod(keepAlive: true)
DiscoveryAvailability discoveryAvailability(Ref ref) =>
    DiscoveryAvailability(service: ref.watch(booruServiceProvider));
typedef PopularProbeKey = ({String sourceId, int revision});

class PopularProbeResult {
  const PopularProbeResult(this.available, {this.failedAt});
  final bool available;
  final DateTime? failedAt;
}

@riverpod
class PopularProbe extends _$PopularProbe {
  @override
  Future<PopularProbeResult> build(PopularProbeKey key) {
    final retained = ref.keepAlive();
    Timer? expiry;
    var inactive = false;
    ref.onCancel(() {
      inactive = true;
      expiry = Timer(const Duration(minutes: 5), retained.close);
    });
    ref.onResume(() {
      inactive = false;
      expiry?.cancel();
      // Run the state check after Riverpod has completed its lifecycle callback.
      Future.microtask(() {
        if (!ref.mounted || inactive) return;
        final failedAt = state.value?.failedAt;
        if (failedAt != null &&
            DateTime.now().difference(failedAt) >= const Duration(minutes: 5)) {
          refresh();
        }
      });
    });
    ref.onDispose(() => expiry?.cancel());
    return _probe();
  }

  Future<PopularProbeResult> _probe({bool refresh = false}) async {
    final availability = ref
        .read(booruServiceProvider)
        .sourceById(key.sourceId)
        .capabilities
        .discovery
        .popular;
    if (availability != CapabilityAvailability.requiresProbe) {
      return PopularProbeResult(
        availability == CapabilityAvailability.available,
      );
    }
    try {
      final result = await ref
          .read(discoveryAvailabilityProvider)
          .popular(key.sourceId, refresh: refresh);
      if (result == CapabilityAvailability.available) {
        return const PopularProbeResult(true);
      }
    } catch (_) {
      // A failed optional probe leaves the regular feed available.
    }
    return PopularProbeResult(false, failedAt: DateTime.now());
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await _probe(refresh: true);
    if (ref.mounted) state = AsyncData(result);
  }
}
