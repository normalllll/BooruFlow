import 'package:hive_ce/hive.dart';
import 'package:booruflow/core/app_runtime.dart';
import 'package:booruflow/features/booru/booru_service.dart';
import 'package:booruflow/src/rust/api/booru_models.dart';
import 'package:booruflow/src/rust/booru/error.dart';

/// Successful probes survive restarts; authentication, route configuration and
/// app changes invalidate them without changing the adapter's static contract.
class DiscoveryAvailability {
  static final instance = DiscoveryAvailability();
  final _pending = <String, Future<CapabilityAvailability>>{};
  Future<CapabilityAvailability> popular(
    String source, {
    bool refresh = false,
  }) {
    final service = BooruService.instance;
    final key =
        '$source:${AppInfo.version}:${service.cacheRevision(source)}:${service.networkCacheRevision}';
    return _pending.putIfAbsent(key, () async {
      try {
        final box = await Hive.openBox<dynamic>('discovery_capabilities_v1');
        final cached = box.get(key);
        if (!refresh &&
            cached is Map &&
            cached['expires'] is int &&
            cached['state'] is int &&
            (cached['state'] as int) >= 0 &&
            (cached['state'] as int) < CapabilityAvailability.values.length &&
            (cached['expires'] as int) >
                DateTime.now().millisecondsSinceEpoch) {
          return CapabilityAvailability.values[cached['state'] as int];
        }
        if (cached != null) await box.delete(key);
        var state = CapabilityAvailability.available;
        try {
          await service.engine.feed(
            request: FeedRequestDto(
              sourceId: source,
              kind: FeedKind.recentPopular,
              range: PopularRange.day,
              ratings: [ContentRating.general],
              pageSize: 1,
            ),
          );
        } on BooruErrorDto catch (error) {
          state =
              error.code == BooruErrorCode.unsupportedCapability ||
                  error.httpStatus == 404
              ? CapabilityAvailability.unsupported
              : CapabilityAvailability.temporarilyUnavailable;
        } catch (_) {
          state = CapabilityAvailability.temporarilyUnavailable;
        }
        final ttl = state == CapabilityAvailability.temporarilyUnavailable
            ? const Duration(minutes: 5)
            : const Duration(hours: 24);
        await box.put(key, {
          'state': state.index,
          'expires': DateTime.now().add(ttl).millisecondsSinceEpoch,
        });
        if (box.length > 64) {
          await box.deleteAll(
            box.keys.where((k) => k != key).take(box.length - 64).toList(),
          );
        }
        return state;
      } finally {
        _pending.remove(key);
      }
    });
  }
}
