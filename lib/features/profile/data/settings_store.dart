import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/storage/json_preferences_store.dart';
import 'package:cryptolens_flutter/features/profile/domain/settings.dart';

class SettingsStore {
  const SettingsStore();

  static const storageKey = StorageKeys.settings;
  static const _store = JsonPreferencesStore(storageKey);

  Future<AppSettings> load() async {
    final decoded = await _store.load();
    if (decoded is! Map<String, Object?>) return const AppSettings();
    return AppSettings.fromJson(decoded);
  }

  Future<void> save(AppSettings settings) async {
    await _store.save(settings.toJson());
  }
}
