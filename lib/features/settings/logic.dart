import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

class AccountData {
  const AccountData({
    required this.schema,
    required this.auth,
    this.operation = const AsyncData<void>(null),
  });
  final AsyncValue<void> operation;
  final AuthSchema schema;
  final AuthState auth;
}

@riverpod
class Account extends _$Account {
  @override
  Future<AccountData> build(String sourceId) async {
    final service = ref.watch(booruServiceProvider);
    final values = await Future.wait<Object>([
      service.authSchema(sourceId),
      service.authState(sourceId),
    ]);
    return AccountData(
      schema: values[0] as AuthSchema,
      auth: values[1] as AuthState,
    );
  }

  Future<bool> _run(Future<AuthState> Function() operation) async {
    if (state.isLoading ||
        !state.hasValue ||
        state.requireValue.operation.isLoading) {
      return false;
    }
    final previous = state.requireValue;
    state = AsyncData(
      AccountData(
        schema: previous.schema,
        auth: previous.auth,
        operation: const AsyncLoading<void>(),
      ),
    );
    try {
      final auth = await operation();
      if (ref.mounted) {
        state = AsyncData(AccountData(schema: previous.schema, auth: auth));
      }
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncData(
          AccountData(
            schema: previous.schema,
            auth: previous.auth,
            operation: AsyncError<void>(error, stack),
          ),
        );
      }
      rethrow;
    }
  }

  Future<bool> save({
    required bool webSession,
    required String cookieHeader,
    required String userAgent,
    required SourceCredentials credentials,
  }) => _run(() {
    final service = ref.read(booruServiceProvider);
    return switch (webSession) {
      true => service.saveWebSession(
        sourceId,
        cookieHeader: cookieHeader,
        userAgent: userAgent,
      ),
      false => service.saveCredentials(sourceId, credentials),
    };
  });
  Future<bool> verify() => _run(
    () => ref.read(booruServiceProvider).engine.verifyAuth(sourceId: sourceId),
  );
  Future<bool> clear() => _run(() async {
    final service = ref.read(booruServiceProvider);
    await service.clearAuth(sourceId);
    return service.authState(sourceId);
  });
}
