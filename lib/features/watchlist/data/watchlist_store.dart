import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/core/constants/storage_keys.dart';

class WatchlistStore {
  static const _storageKey = StorageKeys.watchlistCoinIds;

  final Set<String> _coinIds = <String>{};
  bool _loaded = false;

  Future<Set<String>> load() async {
    if (!_loaded) {
      final prefs = await SharedPreferences.getInstance();
      _coinIds
        ..clear()
        ..addAll(prefs.getStringList(_storageKey) ?? const <String>[]);
      _loaded = true;
    }
    return Set.unmodifiable(_coinIds);
  }

  Future<Set<String>> toggle(String coinId) async {
    await load();
    if (_coinIds.contains(coinId)) {
      _coinIds.remove(coinId);
    } else {
      _coinIds.add(coinId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _coinIds.toList()..sort());
    return Set.unmodifiable(_coinIds);
  }
}
