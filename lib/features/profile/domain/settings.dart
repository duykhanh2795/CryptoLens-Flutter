enum AppCurrency {
  usd(r'$ USD', 'US Dollar'),
  eur('EUR', 'Euro'),
  jpy('JPY', 'Japanese Yen'),
  vnd('VND', 'Vietnamese Dong');

  const AppCurrency(this.label, this.displayName);

  final String label;
  final String displayName;
}

enum AppThemeMode {
  system('System'),
  dark('Dark'),
  light('Light');

  const AppThemeMode(this.label);

  final String label;
}

enum AppLanguage {
  english('English'),
  vietnamese('Vietnamese');

  const AppLanguage(this.label);

  final String label;
}

enum PriceDisplayFormat {
  compact('Compact'),
  fullPrecision('Full precision'),
  rounded('Rounded');

  const PriceDisplayFormat(this.label);

  final String label;
}

class AppSettings {
  const AppSettings({
    this.currency = AppCurrency.usd,
    this.theme = AppThemeMode.system,
    this.language = AppLanguage.english,
    this.priceFormat = PriceDisplayFormat.compact,
    this.showPortfolioValue = true,
    this.biometricLock = false,
    this.enableNotifications = true,
  });

  final AppCurrency currency;
  final AppThemeMode theme;
  final AppLanguage language;
  final PriceDisplayFormat priceFormat;
  final bool showPortfolioValue;
  final bool biometricLock;
  final bool enableNotifications;

  AppSettings copyWith({
    AppCurrency? currency,
    AppThemeMode? theme,
    AppLanguage? language,
    PriceDisplayFormat? priceFormat,
    bool? showPortfolioValue,
    bool? biometricLock,
    bool? enableNotifications,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      priceFormat: priceFormat ?? this.priceFormat,
      showPortfolioValue: showPortfolioValue ?? this.showPortfolioValue,
      biometricLock: biometricLock ?? this.biometricLock,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  Map<String, Object?> toJson() => {
    'currency': currency.name,
    'theme': theme.name,
    'language': language.name,
    'priceFormat': priceFormat.name,
    'showPortfolioValue': showPortfolioValue,
    'biometricLock': biometricLock,
    'enableNotifications': enableNotifications,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    return AppSettings(
      currency:
          _enumValue(AppCurrency.values, json['currency']) ?? AppCurrency.usd,
      theme:
          _enumValue(AppThemeMode.values, json['theme']) ?? AppThemeMode.system,
      language:
          _enumValue(AppLanguage.values, json['language']) ??
          AppLanguage.english,
      priceFormat:
          _enumValue(PriceDisplayFormat.values, json['priceFormat']) ??
          PriceDisplayFormat.compact,
      showPortfolioValue: json['showPortfolioValue'] as bool? ?? true,
      biometricLock: json['biometricLock'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
    );
  }
}

T? _enumValue<T extends Enum>(List<T> values, Object? raw) {
  final name = raw?.toString();
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
