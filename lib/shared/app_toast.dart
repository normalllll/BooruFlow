import 'package:booruflow/app/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:frost_ui/frost_ui.dart';
import 'action_failure.dart';

/// Context-free operation callers share the root navigator's error presenter.
/// No diagnostic formatting or detail dialog is implemented in the App.
abstract final class AppToast {
  static void show(Object message) => FrostToast.info('$message');
  static void success(Object message) => FrostToast.success('$message');
  static void info(Object message) => FrostToast.info('$message');
  static void error(
    Object message, {
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) => errorWithCause(
    message,
    null,
    description: description,
    actionLabel: actionLabel,
    onAction: onAction,
  );
  static void errorWithCause(
    Object message,
    Object? cause, {
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    FrostToast.fromError(
      context,
      AppActionFailure('$message', cause),
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
