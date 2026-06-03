import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/core/constants/storage_keys.dart';

class AuthSessionStore {
  static const _displayNameKey = StorageKeys.authDisplayName;
  static const _emailKey = StorageKeys.authEmail;

  Future<StoredUser?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    if (email == null || email.trim().isEmpty) return null;
    return StoredUser(
      displayName: prefs.getString(_displayNameKey) ?? email.split('@').first,
      email: email,
    );
  }

  Future<void> save(StoredUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, user.displayName);
    await prefs.setString(_emailKey, user.email);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_displayNameKey);
    await prefs.remove(_emailKey);
  }
}

class StoredUser {
  const StoredUser({required this.displayName, required this.email});

  final String displayName;
  final String email;
}
