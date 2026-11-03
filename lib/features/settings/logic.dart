import 'dart:async';

import 'package:booruflow/features/booru/booru_logic.dart';
import 'package:booruflow/src/rust/api/booru_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logic.g.dart';

class AccountData {
  const AccountData({
    required this.schema,
    required this.auth,
    this.operation = const AsyncData<void>(null),
    this.credentialHints = const {},
  });
  final AsyncValue<void> operation;
  final Map<AuthFieldKind, String> credentialHints;
  final AuthSchema schema;
  final AuthState auth;
}

@riverpod
class Account extends _$Account {
  // Both reads are synchronous, so the first frame already has the status.
  @override
  FutureOr<AccountData> build(String sourceId) {
    final service = ref.watch(booruServiceProvider);
    final schema = service.authSchema(sourceId);
    return AccountData(
      schema: schema,
      auth: service.authState(sourceId),
      credentialHints: _hints(schema),
    );
  }

  // Keep only display-safe hints in shared state, never the full secret.
  Map<AuthFieldKind, String> _hints(AuthSchema schema) {
    final saved = ref.read(booruServiceProvider).savedAuth(sourceId);
    return Map.unmodifiable({
      for (final field in schema.fields)
        if (saved[field.kind.name] case final value? when value.isNotEmpty)
          field.kind: field.secret
              ? '••••••••${value.length > 4 ? value.substring(value.length - 4) : ''}'
              : value,
    });
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
        credentialHints: previous.credentialHints,
      ),
    );
    try {
      final auth = await operation();
      if (ref.mounted) {
        state = AsyncData(
          AccountData(
            schema: previous.schema,
            auth: auth,
            credentialHints: _hints(previous.schema),
          ),
        );
      }
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncData(
          AccountData(
            schema: previous.schema,
            auth: previous.auth,
            operation: AsyncError<void>(error, stack),
            credentialHints: previous.credentialHints,
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
