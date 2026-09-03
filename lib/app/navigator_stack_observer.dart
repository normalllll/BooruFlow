import 'package:flutter/material.dart';

class NavigatorStackObserver extends NavigatorObserver {
  NavigatorStackObserver(this.onStackChanged);

  final VoidCallback onStackChanged;
  final _routes = <Route<dynamic>>[];

  bool get canPopPageRoute =>
      _routes.where((route) => route is! PopupRoute<dynamic>).length > 1;

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onStackChanged());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routes.add(route);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routes.remove(route);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routes.remove(route);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final index = _routes.indexOf(oldRoute);
      if (index >= 0) {
        if (newRoute == null) {
          _routes.removeAt(index);
        } else {
          _routes[index] = newRoute;
        }
      } else if (newRoute != null) {
        _routes.add(newRoute);
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _notify();
  }
}
