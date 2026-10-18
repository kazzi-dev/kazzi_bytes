import 'package:flutter/foundation.dart';

import '../data/menu_data.dart';
import '../data/models.dart';
import '../data/repositories.dart';

enum MenuStatus { idle, loading, ready, error }

/// Loads the menu and exposes loading / error / data states.
///
/// (Named "catalog" because Flutter already has a MenuController.)
class CatalogController extends ChangeNotifier {
  CatalogController(this.repository);

  final MenuRepository repository;

  MenuStatus _status = MenuStatus.idle;
  MenuData? _data;
  String? _error;
  bool _disposed = false;

  MenuStatus get status => _status;
  String? get error => _error;
  List<Dish> get dishes => _data?.dishes ?? const <Dish>[];
  List<String> get categories => _data?.categories ?? kCategories;
  List<Promo> get promos => _data?.promos ?? const <Promo>[];

  Dish? dishById(String id) {
    for (final Dish dish in _data?.dishes ?? kMenu) {
      if (dish.id == id) return dish;
    }
    return null;
  }

  /// Fetches the menu. With [refresh], existing data stays on screen while
  /// loading and a failure keeps it there. Returns whether it succeeded.
  Future<bool> load({bool refresh = false}) async {
    if (_status == MenuStatus.loading) return true;
    final bool keepData = refresh && _data != null;
    if (!keepData) {
      _status = MenuStatus.loading;
      _error = null;
      _notify();
    }
    try {
      _data = await repository.fetchMenu();
      _status = MenuStatus.ready;
      _error = null;
      _notify();
      return true;
    } on Object catch (e) {
      _error = e is MenuException
          ? e.message
          : 'Something went wrong while loading the menu.';
      if (!keepData) _status = MenuStatus.error;
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
