import 'package:booruflow/core/downloads/download_manager_contract.dart';
import 'package:booruflow/core/downloads/download_models.dart';
import 'package:booruflow/features/downloads/logic.dart';
import 'package:booruflow/features/downloads/models/booru_download_item.dart';

class TestDownloadItems extends DownloadItems {
  TestDownloadItems(this.initial);
  final List<BooruDownloadItem> initial;
  @override
  List<BooruDownloadItem> build() => initial;
  void replace(List<BooruDownloadItem> value) => state = value;
}

class TestDownloadManager implements DownloadManager {
  final calls = <(String, String)>[];
  final jobs = <DownloadJob>[];
  @override
  Future<void> pause(String id) async {
    calls.add(('pause', id));
  }

  @override
  Future<void> resume(String id) async {
    calls.add(('resume', id));
  }

  @override
  Future<void> retry(String id) async {
    calls.add(('retry', id));
  }

  @override
  Future<void> retrySave(String id) async {
    calls.add(('retrySave', id));
  }

  @override
  Future<void> cancel(String id) async {
    calls.add(('cancel', id));
  }

  @override
  Future<void> deleteTask(String id) async {
    calls.add(('deleteTask', id));
  }

  @override
  Future<void> sync() async {
    calls.add(('sync', ''));
  }

  @override
  Future<int> enqueue(List<DownloadJob> value) async {
    jobs.addAll(value);
    return value.length;
  }

  @override
  Future<List<DownloadTaskSnapshot>> listTasks({
    int? resourceId,
    DownloadStatus? status,
    SaveState? saveState,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
