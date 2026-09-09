import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps displayed content while a refresh or command is pending or fails.
class AsyncContent<T> {
  const AsyncContent(
    this.value, {
    this.operation = const AsyncData<void>(null),
  });
  final T value;
  final AsyncValue<void> operation;
  bool get isLoading => operation.isLoading;
  Object? get error => operation.error;
  AsyncContent<T> loading() =>
      AsyncContent(value, operation: const AsyncLoading<void>());
  AsyncContent<T> failed(Object error, StackTrace stack) =>
      AsyncContent(value, operation: AsyncError<void>(error, stack));
}
