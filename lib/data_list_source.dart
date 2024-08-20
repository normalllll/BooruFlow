import 'package:loading_more_list/loading_more_list.dart';

abstract class DataListSource<T> extends LoadingMoreBase<T> {
  bool _initialized = false;

  static const int _limit = 100;

  int _page = 1;

  bool _hasMore = true;

  @override
  bool get hasMore => !_initialized || _hasMore;

  bool nextClear = false;

  @override
  Future<bool> refresh([bool notifyStateChanged = false, bool auto = true]) async {
    _hasMore = true;
    _initialized = false;
    _page = 1;

    if (!auto) {
      nextClear = true;
    }
    final result = await super.refresh(notifyStateChanged);
    if (!auto) {
      setState();
    }
    return result;
  }

  @override
  Future<bool> loadData([bool isLoadMoreAction = false]) async {
    try {
      final list = await fetchList(_page, _limit);
      if (list.isEmpty) {
        _hasMore = false;
        return true;
      }

      if (nextClear) {
        clear();
        nextClear = false;
        addAll(list.sublist(10, 20));
      } else {
        addAll(list);
      }

      print(length);
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
