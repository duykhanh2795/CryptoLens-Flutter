import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class JsonPreferencesStore {
  const JsonPreferencesStore(this.key);

  final String key;

  Future<Object?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    return jsonDecode(raw);
  }

  Future<void> save(Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> remove() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
