import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/features/alerts/domain/alert_rule.dart';

class AlertRuleStore {
  static const storageKey = StorageKeys.alertsRules;

  Future<List<AlertRule>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(AlertRule.fromJson)
        .whereType<AlertRule>()
        .toList();
  }

  Future<void> save(List<AlertRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    if (rules.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(
      storageKey,
      jsonEncode(rules.map((rule) => rule.toJson()).toList()),
    );
  }
}
