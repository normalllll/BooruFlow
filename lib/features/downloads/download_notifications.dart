import 'dart:async';

import 'package:booruflow/app/app_router.dart';
import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/core/downloads/download_permission_guard.dart';
import 'package:booruflow/features/booru/booru_error_presentation.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/shared/app_toast.dart';
import 'package:frost_ui/frost_ui.dart';

void openDownloadTask(String id) => AppRouter.router.go(
  Uri(
    path: '/downloads',
    queryParameters: {
      'task': id,
      'reveal': '${DateTime.now().microsecondsSinceEpoch}',
    },
  ).toString(),
);

void notifyDownloadAdded({required String taskId, required String name}) =>
    FrostToast.success(
      t.verificationPage.downloadAdded,
      description: name,
      actionLabel: t.verificationPage.view,
      onAction: () => openDownloadTask(taskId),
    );

/// Bind each notice to its own task. A save failure must retry saving, rather
/// than restarting an already completed transfer. Exceptions stay in app UI.
void notifyDownloadFailure({
  required DownloadTaskSnapshot task,
  required DownloadManager manager,
}) => AppToast.errorWithCause(
  t.verificationPage.downloadFailed,
  task.error,
  description: [
    task.postId == null ? task.filename : '#${task.postId}',
    if (task.error case final error?) error.split('\n').first,
  ].join(' · '),
  actionLabel: t.generic.retry,
  onAction: () =>
      unawaited(retryNotifiedDownload(task: task, manager: manager)),
);
Future<void> retryNotifiedDownload({
  required DownloadTaskSnapshot task,
  required DownloadManager manager,
}) async {
  try {
    if (task.saveState == SaveState.failed) {
      await manager.retrySave(task.id);
    } else {
      await manager.retry(task.id);
    }
  } catch (error) {
    AppToast.errorWithCause(t.downloads.actionFailed, error);
  }
}

void notifyDownloadEnqueueFailure({
  required String name,
  required Object error,
  required Future<bool> Function() retry,
}) => AppToast.errorWithCause(
  t.verificationPage.downloadFailed,
  error,
  description:
      '$name · ${error is DownloadPermissionDenied ? t.batchDownload.permissionDenied : describeBooruError(error, includeDiagnostics: false)}',
  actionLabel: error is DownloadPermissionDenied
      ? t.ugoira.openSettings
      : t.generic.retry,
  onAction: () => unawaited(
    error is DownloadPermissionDenied
        ? NativeDownloadPermissionGuard.openAppSettings()
        : retry(),
  ),
);
