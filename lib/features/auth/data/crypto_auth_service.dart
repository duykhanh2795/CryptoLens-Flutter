import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cryptolens_flutter/core/config/app_config.dart';
import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/errors/app_exception.dart';
import 'package:cryptolens_flutter/core/storage/preferences_store.dart';
import 'package:cryptolens_flutter/core/validation/validators.dart';
import 'package:cryptolens_flutter/features/auth/domain/auth_models.dart';

export 'package:cryptolens_flutter/features/auth/domain/auth_models.dart';

class CryptoAuthService {
  CryptoAuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const supabaseUrl = AppConfig.supabaseUrl;
  static const supabaseAnonKey = AppConfig.supabaseAnonKey;

  static const _rememberLoginKey = StorageKeys.authRememberLogin;
  static const _rememberedEmailKey = StorageKeys.authRememberedEmail;
  static const _preferences = PreferencesStore();

  final SupabaseClient _client;

  CryptoAuthUser? get currentUser => _toUser(_client.auth.currentUser);

  Stream<CryptoAuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      return _toUser(event.session?.user ?? _client.auth.currentUser);
    });
  }

  Future<CryptoAuthUser> login({
    required String email,
    required String password,
    required bool remember,
  }) async {
    _validateEmail(email);
    _throwIfInvalid(Validators.minLength(password, 6, 'Password'));
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _toUser(response.user ?? _client.auth.currentUser);
      if (user == null) {
        throw const CryptoAuthException('Login failed. Please try again.');
      }
      await saveLoginPreferences(rememberLogin: remember, email: email);
      return user;
    } on AuthException catch (error) {
      throw CryptoAuthException(_mapAuthError(error.message));
    }
  }

  Future<CryptoAuthUser> register({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _throwIfInvalid(Validators.requiredText(displayName, 'Name'));
    _validateEmail(email);
    _throwIfInvalid(Validators.minLength(password, 6, 'Password'));
    _throwIfInvalid(Validators.matching(password, confirmPassword, 'Password'));
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      final user = _toUser(response.user ?? _client.auth.currentUser);
      return user ??
          CryptoAuthUser(
            id: '',
            email: email.trim(),
            displayName: displayName.trim(),
          );
    } on AuthException catch (error) {
      throw CryptoAuthException(_mapAuthError(error.message));
    }
  }

  Future<void> resetPassword(String email) async {
    _validateEmail(email);
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (error) {
      throw CryptoAuthException(_mapAuthError(error.message));
    }
  }

  Future<void> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _throwIfInvalid(Validators.minLength(newPassword, 6, 'New password'));
    _throwIfInvalid(
      Validators.matching(newPassword, confirmPassword, 'Password'),
    );
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw CryptoAuthException(_mapAuthError(error.message));
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw CryptoAuthException(_mapAuthError(error.message));
    }
  }

  Future<LoginPreferences> loadLoginPreferences() async {
    return LoginPreferences(
      rememberLogin: await _preferences.getBool(_rememberLoginKey),
      rememberedEmail: await _preferences.getString(_rememberedEmailKey) ?? '',
    );
  }

  Future<void> saveLoginPreferences({
    required bool rememberLogin,
    required String email,
  }) async {
    await _preferences.setBool(_rememberLoginKey, rememberLogin);
    if (rememberLogin && email.trim().isNotEmpty) {
      await _preferences.setString(_rememberedEmailKey, email.trim());
    } else {
      await _preferences.remove(_rememberedEmailKey);
    }
  }

  CryptoAuthUser? _toUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName = metadata['display_name']?.toString().trim();
    final avatarUrl = metadata['avatar_url']?.toString().trim();
    return CryptoAuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName?.isNotEmpty == true
          ? displayName!
          : (user.email ?? '').split('@').first,
      avatarUrl: avatarUrl ?? '',
      createdAt: user.createdAt,
    );
  }

  void _validateEmail(String email) {
    _throwIfInvalid(Validators.email(email));
  }

  void _throwIfInvalid(String? message) {
    if (message != null) throw CryptoAuthException(message);
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email first';
    }
    if (message.contains('already registered')) {
      return 'Email is already registered';
    }
    if (message.toLowerCase().contains('network')) {
      return 'Network error. Check your connection.';
    }
    return message;
  }
}

class CryptoAuthException extends AppException {
  const CryptoAuthException(super.message);
}
