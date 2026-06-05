import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/storage/preferences_store.dart';

class WatchlistStore {
  static const _storageKey = StorageKeys.watchlistCoinIds;
  static const _store = PreferencesStore();

  final Set<String> _coinIds = <String>{};
  bool _loaded = false;

  Future<Set<String>> load() async {
    if (!_loaded) {
      _coinIds
        ..clear()
        ..addAll(await _store.getStringList(_storageKey));
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
    await _store.setStringList(_storageKey, _coinIds.toList()..sort());
    return Set.unmodifiable(_coinIds);
  }
}
