import 'dart:convert';

import 'package:cryptolens_flutter/core/storage/preferences_store.dart';

class JsonPreferencesStore {
  const JsonPreferencesStore(
    this.key, [
    this._store = const PreferencesStore(),
  ]);

  final String key;
  final PreferencesStore _store;

  Future<Object?> load() async {
    final raw = await _store.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    return jsonDecode(raw);
  }

  Future<void> save(Object? value) async {
    if (value == null) {
      await remove();
      return;
    }
    await _store.setString(key, jsonEncode(value));
  }

  Future<void> remove() async {
    await _store.remove(key);
  }
}
