import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/storage/json_preferences_store.dart';
import 'package:cryptolens_flutter/features/alerts/domain/alert_rule.dart';

class AlertRuleStore {
  const AlertRuleStore();

  static const storageKey = StorageKeys.alertsRules;
  static const _store = JsonPreferencesStore(storageKey);

  Future<List<AlertRule>> load() async {
    final decoded = await _store.load();
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(AlertRule.fromJson)
        .whereType<AlertRule>()
        .toList();
  }

  Future<void> save(List<AlertRule> rules) async {
    if (rules.isEmpty) {
      await _store.remove();
      return;
    }
    await _store.save(rules.map((rule) => rule.toJson()).toList());
  }
}
