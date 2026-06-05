import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/storage/preferences_store.dart';

class AuthSessionStore {
  static const _displayNameKey = StorageKeys.authDisplayName;
  static const _emailKey = StorageKeys.authEmail;
  static const _store = PreferencesStore();

  Future<StoredUser?> load() async {
    final email = await _store.getString(_emailKey);
    if (email == null || email.trim().isEmpty) return null;
    return StoredUser(
      displayName:
          await _store.getString(_displayNameKey) ?? email.split('@').first,
      email: email,
    );
  }

  Future<void> save(StoredUser user) async {
    await _store.setString(_displayNameKey, user.displayName);
    await _store.setString(_emailKey, user.email);
  }

  Future<void> clear() async {
    await _store.removeAll([_displayNameKey, _emailKey]);
  }
}

class StoredUser {
  const StoredUser({required this.displayName, required this.email});

  final String displayName;
  final String email;
}
