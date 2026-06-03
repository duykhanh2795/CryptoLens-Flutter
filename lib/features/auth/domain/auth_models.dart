class CryptoAuthUser {
  const CryptoAuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String? createdAt;
}

class LoginPreferences {
  const LoginPreferences({
    required this.rememberLogin,
    required this.rememberedEmail,
  });

  final bool rememberLogin;
  final String rememberedEmail;
}
