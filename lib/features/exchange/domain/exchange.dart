import 'dart:convert';

enum ExchangeType {
  binance('Binance'),
  okx('OKX'),
  bybit('Bybit');

  const ExchangeType(this.displayName);

  final String displayName;
}

class ExchangeConnection {
  const ExchangeConnection({
    required this.id,
    required this.exchangeType,
    required this.label,
    required this.apiKey,
    required this.secret,
    required this.isActive,
    required this.createdAt,
    this.lastSyncAt,
  });

  final String id;
  final ExchangeType exchangeType;
  final String label;
  final String apiKey;
  final String secret;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSyncAt;

  String get maskedApiKey {
    if (apiKey.length <= 8) return 'â€¢â€¢â€¢â€¢';
    return '${apiKey.substring(0, 4)}â€¢â€¢â€¢â€¢${apiKey.substring(apiKey.length - 4)}';
  }

  ExchangeConnection copyWith({bool? isActive, DateTime? lastSyncAt}) {
    return ExchangeConnection(
      id: id,
      exchangeType: exchangeType,
      label: label,
      apiKey: apiKey,
      secret: secret,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'exchangeType': exchangeType.name,
    'label': label,
    'apiKey': _obfuscate(apiKey),
    'secret': _obfuscate(secret),
    'isActive': isActive,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
  };

  static ExchangeConnection? fromJson(Map<String, Object?> json) {
    final id = json['id']?.toString();
    final apiKey = _deobfuscate(json['apiKey']?.toString() ?? '');
    final secret = _deobfuscate(json['secret']?.toString() ?? '');
    if (id == null || id.isEmpty || apiKey.isEmpty || secret.isEmpty) {
      return null;
    }
    return ExchangeConnection(
      id: id,
      exchangeType:
          _enumValue(ExchangeType.values, json['exchangeType']) ??
          ExchangeType.binance,
      label: json['label']?.toString() ?? 'Binance account',
      apiKey: apiKey,
      secret: secret,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      lastSyncAt: (json['lastSyncAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (json['lastSyncAt'] as num).toInt(),
            ),
    );
  }
}

class ApiKeyValidation {
  const ApiKeyValidation({
    required this.isValid,
    this.accountType = '',
    this.canRead = false,
    this.canTrade = false,
    this.errorMessage,
  });

  final bool isValid;
  final String accountType;
  final bool canRead;
  final bool canTrade;
  final String? errorMessage;
}

class SyncResult {
  const SyncResult({
    required this.exchangeType,
    required this.tradesImported,
    required this.tradesSkipped,
    required this.symbolsScanned,
    required this.balanceAssetsFound,
    required this.syncedAt,
  });

  final ExchangeType exchangeType;
  final int tradesImported;
  final int tradesSkipped;
  final int symbolsScanned;
  final int balanceAssetsFound;
  final DateTime syncedAt;
}

String _obfuscate(String value) {
  if (value.isEmpty) return '';
  return base64UrlEncode(utf8.encode(value.split('').reversed.join()));
}

String _deobfuscate(String value) {
  if (value.isEmpty) return '';
  try {
    return utf8.decode(base64Url.decode(value)).split('').reversed.join();
  } catch (_) {
    return '';
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
