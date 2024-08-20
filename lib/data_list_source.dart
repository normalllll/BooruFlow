import 'package:loading_more_list/loading_more_list.dart';

abstract class DataListSource<T> extends LoadingMoreBase<T> {
  bool _initialized = false;

  static const int _limit = 100;

  int _page = 1;

  bool _hasMore = true;

  @override
  bool get hasMore => !_initialized || _hasMore;

  @override
  Future<bool> refresh([bool notifyStateChanged = false]) async {
    _hasMore = true;
    _initialized = false;
    _page = 1;
    if (!notifyStateChanged) {
      clear();
    }
    return super.refresh(notifyStateChanged);
  }

  @override
  Future<bool> loadData([bool isLoadMoreAction = false]) async {
    try {
      final list = await fetchList(_page, _limit);
      if (list.isEmpty) {
        _hasMore = false;
        return true;
      }
      addAll(list);
      _page++;
      if (!_initialized) {
        _initialized = true;
      }

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<T>> fetchList(int page, int limit);
}
