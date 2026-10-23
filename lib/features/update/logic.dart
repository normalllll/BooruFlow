import 'package:booruflow/features/update/updater_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'logic.g.dart';

class UpdateInfo {
  const UpdateInfo({required this.version, required this.download});
  final String version;
  final Uri? download;
}

typedef UpdateLookup = Future<UpdateInfo?> Function();
@riverpod
UpdateLookup updateLookup(Ref ref) => () async {
  final release = await UpdaterService.checkForUpdate();
  if (release == null) return null;
  final url = await UpdaterService.selectDownloadUrl(release.$3);
  return UpdateInfo(
    version: release.$1,
    download: url == null ? null : Uri.parse(url),
  );
};

class UpdateCheckState {
  const UpdateCheckState({
    this.result,
    this.operation = const AsyncData<void>(null),
  });
  final UpdateInfo? result;
  final AsyncValue<void> operation;
}

// Keep the explicit check result across About/section navigation.
@Riverpod(keepAlive: true)
class UpdateCheck extends _$UpdateCheck {
  @override
  UpdateCheckState build() => const UpdateCheckState();
  Future<UpdateInfo?>? _pending;
  Future<UpdateInfo?> check() =>
      _pending ??= _run().whenComplete(() => _pending = null);
  Future<UpdateInfo?> _run() async {
    final previous = state.result;
    state = UpdateCheckState(result: previous, operation: const AsyncLoading());
    try {
      final result = await ref.read(updateLookupProvider)();
      if (ref.mounted) state = UpdateCheckState(result: result);
      return result;
    } catch (error, stack) {
      if (ref.mounted) {
        state = UpdateCheckState(
          result: previous,
          operation: AsyncError(error, stack),
        );
      }
      rethrow;
    }
  }
}
