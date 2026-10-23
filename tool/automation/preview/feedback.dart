// Verification dependencies and notification data exist only in automation.
import 'dart:async';
import 'package:booruflow/features/booru/models/web_challenge_failure.dart';
import 'package:booruflow/features/booru/services/web_challenge_service.dart';
import 'package:booruflow/features/booru/web_challenge_browser.dart';
import 'package:booruflow/features/downloads/download_notifications.dart';
import 'package:booruflow/intl/translations.g.dart';
import 'package:booruflow/src/rust/api/web_challenge.dart';
import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'downloads.dart';

const previewChallengeOperation = WebChallengeOperation(
  operationId: 'fixture',
  spec: WebChallengeSpec(
    sourceId: 'gelbooru',
    displayName: 'Gelbooru',
    entryUrl: 'https://gelbooru.com/',
    navigationHosts: ['gelbooru.com'],
    captureTargets: [],
    timeoutSeconds: 600,
  ),
);

class PreviewChallengeBrowser extends WebChallengeBrowser {
  PreviewChallengeBrowser(this.failed);
  @override
  bool failed;
  @override
  bool get loading => true;
  @override
  bool get available => true;
  @override
  Uri get url => Uri.parse(previewChallengeOperation.spec.entryUrl);
  @override
  Future<void> open(WebChallengeSpec spec) async {}
  @override
  Future<void> reload() async {
    failed = false;
    notifyListeners();
  }

  @override
  Future<WebChallengeCandidate> capture(WebChallengeSpec spec) async =>
      const WebChallengeCandidate(
        cookies: [],
        snapshots: [],
        userAgent: 'fixture',
      );
  @override
  Future<void> clear() async {}
  @override
  Widget content(BuildContext context) => const SizedBox();
}

class _PreviewNativeBackend implements WebChallengeBackend {
  _PreviewNativeBackend(this.fail);
  final bool fail;
  final pending = Completer<WebChallengeState>();
  @override
  Future<WebChallengeOperation> begin(String id) async =>
      previewChallengeOperation;
  @override
  Future<WebChallengeState> runWindow(WebChallengeOperation op) {
    if (fail) throw const WebChallengeFailure('webViewUnavailable');
    return pending.future;
  }

  @override
  Future<void> cancel(String id) async {
    if (!pending.isCompleted) {
      pending.complete(
        const WebChallengeState(
          sourceId: 'gelbooru',
          hasSavedData: false,
          verified: false,
          revision: 0,
        ),
      );
    }
  }

  @override
  Future<void> clear(String id) async {}
  @override
  Future<WebChallengeState> complete(
    String id,
    WebChallengeCandidate candidate,
  ) => throw StateError('Native fixture never captures cookies');
}

WebChallengeService previewNativeChallenge(String board) {
  final backend = _PreviewNativeBackend(board == 'W02');
  // The dedicated automation entrypoint is also test-only; no native backend.
  // ignore: invalid_use_of_visible_for_testing_member
  return WebChallengeService.forTesting(
    backendFactory: () => backend,
    collector: (_, _, _) =>
        throw StateError('No embedded collector in native state fixture'),
    changed: (_) async {},
    nativeWindow: true,
  );
}

void showPreviewNotices(String board) {
  if (board == 'F04') {
    FrostToast.success(t.settings.account.verified);
    return;
  }
  if (board != 'F01') throw ArgumentError('No notification fixture for $board');
  notifyDownloadAdded(taskId: 'preview-0', name: '#1270269');
  final failed = downloadPreviewItems(
    'L01',
  ).firstWhere((item) => item.snapshot.id == 'preview-3');
  notifyDownloadFailure(task: failed.snapshot, manager: _RetryPreviewManager());
  FrostToast.info(t.verificationPage.linkCopied);
}

class _RetryPreviewManager extends PreviewDownloadManager {
  _RetryPreviewManager()
    : super(() => throw StateError('No task stream needed for retry command'));
  @override
  Future<void> retry(String id) async {
    FrostToast.info(t.downloads.messages.downloadRetryWith(name: '#8812044'));
  }
}

// Isolated service injection exercises the real provider/recovery/retry path.
// It never opens WebView2, contacts a source, or stores verification data.
WebChallengeService previewRecoveryChallenge(VoidCallback resolved) =>
    // Test-only entrypoint; never imported by production main.
    // ignore: invalid_use_of_visible_for_testing_member
    WebChallengeService.forTesting(
      backendFactory: _RecoveryBackend.new,
      collector: (_, _, _) async => const WebChallengeCandidate(
        cookies: [],
        snapshots: [],
        userAgent: 'fixture',
      ),
      changed: (_) async => resolved(),
    );

class _RecoveryBackend implements WebChallengeBackend {
  @override
  Future<WebChallengeOperation> begin(String sourceId) async =>
      previewChallengeOperation;
  @override
  Future<WebChallengeState> complete(
    String id,
    WebChallengeCandidate candidate,
  ) async => const WebChallengeState(
    sourceId: 'gelbooru',
    hasSavedData: false,
    verified: true,
    revision: 1,
  );
  @override
  Future<WebChallengeState> runWindow(WebChallengeOperation operation) =>
      throw StateError('No native window in recovery fixture');
  @override
  Future<void> cancel(String id) async {}
  @override
  Future<void> clear(String id) async {}
}
