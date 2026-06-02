import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/features/profile/domain/settings.dart';

class SettingsStore {
  static const storageKey = 'cryptolens.settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const AppSettings();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) return const AppSettings();
    return AppSettings.fromJson(decoded);
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(settings.toJson()));
  }
}
