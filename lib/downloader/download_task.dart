import 'dart:async';

enum DownloadStatus { idle, waiting, busying, completed, failed }

class DownloadTaskState {
  final DownloadStatus status;
  final double progress;
  final String? error;

  const DownloadTaskState({required this.status, required this.progress, required this.error});

  DownloadTaskState copyWith({DownloadStatus? status, double? progress, String? error}) {
    return DownloadTaskState(status: status ?? this.status, progress: progress ?? this.progress, error: error ?? this.error);
  }
}

typedef DownloadTaskStateController = StreamController<DownloadTaskState>;

class DownloadTask<T> {
  final String taskId;
  final T inner;
  final String url;
  final String fileName;
  final DownloadTaskStateController _stateController;
  DownloadTaskState _state;

  DownloadTask({required this.taskId, required this.inner, required this.url, required this.fileName})
    : _stateController = StreamController<DownloadTaskState>.broadcast(),
      _state = const DownloadTaskState(status: DownloadStatus.idle, progress: 0.0, error: null) {
    emit(_state);
  }

  DownloadTaskState get state => _state;

  Stream<DownloadTaskState> get stream => _stateController.stream;

  void emit(DownloadTaskState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
  }
}
