import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/exchange/domain/exchange.dart';

class ExchangeStore {
  static const storageKey = 'cryptolens.exchange.connections.v2';

  Future<List<ExchangeConnection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(ExchangeConnection.fromJson)
        .whereType<ExchangeConnection>()
        .toList();
  }

  Future<void> save(List<ExchangeConnection> connections) async {
    final prefs = await SharedPreferences.getInstance();
    if (connections.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(
      storageKey,
      jsonEncode(connections.map((connection) => connection.toJson()).toList()),
    );
  }

  Future<ExchangeConnection> add({
    required ExchangeType exchangeType,
    required String label,
    required String apiKey,
    required String secret,
  }) async {
    final connections = await load();
    final connection = ExchangeConnection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      exchangeType: exchangeType,
      label: label.trim().isEmpty
          ? '${exchangeType.displayName} account'
          : label.trim(),
      apiKey: apiKey.trim(),
      secret: secret.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );
    await save([connection, ...connections]);
    return connection;
  }
}

class BinanceExchangeService {
  BinanceExchangeService({http.Client? client})
    : _client = client ?? http.Client();

  static final Uri _base = Uri.parse('https://api.binance.com/api/v3/');
  final http.Client _client;

  Future<ApiKeyValidation> validate(String apiKey, String secret) async {
    if (apiKey.trim().isEmpty || secret.trim().isEmpty) {
      return const ApiKeyValidation(
        isValid: false,
        errorMessage: 'API Key and API Secret are required',
      );
    }
    try {
      final response = await _signedGet(
        path: 'account',
        apiKey: apiKey,
        secret: secret,
        query: const {},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final permissions = body is Map ? body['permissions'] : null;
        final canTrade = body is Map && body['canTrade'] == true;
        return ApiKeyValidation(
          isValid: true,
          accountType: permissions is List && permissions.isNotEmpty
              ? permissions.join(', ')
              : 'Spot',
          canRead: true,
          canTrade: canTrade,
        );
      }
      return ApiKeyValidation(
        isValid: false,
        errorMessage: _binanceError(response),
      );
    } catch (error) {
      return ApiKeyValidation(isValid: false, errorMessage: error.toString());
    }
  }

  Future<SyncResult> syncTrades({
    required ExchangeConnection connection,
    required List<Coin> coins,
    required PortfolioStore portfolioStore,
  }) async {
    if (connection.exchangeType != ExchangeType.binance) {
      throw Exception(
        '${connection.exchangeType.displayName} sync not yet supported',
      );
    }
    final symbols = _symbolsToSync(coins);
    final imported = <PortfolioTransaction>[];
    var skipped = 0;

    for (final symbol in symbols) {
      final response = await _signedGet(
        path: 'myTrades',
        apiKey: connection.apiKey,
        secret: connection.secret,
        query: {'symbol': symbol},
      );
      if (response.statusCode == 400 || response.statusCode == 404) continue;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_binanceError(response));
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) continue;
      final coin = _coinForSymbol(symbol, coins);
      if (coin == null) continue;
      for (final raw in decoded.whereType<Map<String, dynamic>>()) {
        final id = raw['id']?.toString();
        if (id == null || id.isEmpty) continue;
        final quantity = double.tryParse(raw['qty']?.toString() ?? '') ?? 0;
        final price = double.tryParse(raw['price']?.toString() ?? '') ?? 0;
        if (quantity <= 0 || price <= 0) continue;
        final fee = double.tryParse(raw['commission']?.toString() ?? '') ?? 0;
        final isBuyer = raw['isBuyer'] == true;
        imported.add(
          PortfolioTransaction(
            id: 'binance_${connection.id}_${symbol}_$id',
            coin: coin,
            type: isBuyer
                ? PortfolioTransactionType.buy
                : PortfolioTransactionType.sell,
            quantity: quantity,
            price: price,
            fee: fee,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              (raw['time'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
            note: 'Imported from Binance Â· $symbol',
            sourceConnectionId: connection.id,
          ),
        );
      }
    }

    final before = await portfolioStore.load(
      coinResolver: (coinId, symbol, name, imageUrl) =>
          _resolveCoin(coinId, symbol, name, imageUrl, coins),
    );
    final added = await portfolioStore.mergeImported(
      imported,
      coinResolver: (coinId, symbol, name, imageUrl) =>
          _resolveCoin(coinId, symbol, name, imageUrl, coins),
    );
    skipped = math.max(imported.length - added, 0);
    return SyncResult(
      exchangeType: ExchangeType.binance,
      tradesImported: added,
      tradesSkipped: skipped,
      symbolsScanned: symbols.length,
      balanceAssetsFound: before.map((tx) => tx.coin.symbol).toSet().length,
      syncedAt: DateTime.now(),
    );
  }

  void dispose() => _client.close();

  Future<http.Response> _signedGet({
    required String path,
    required String apiKey,
    required String secret,
    required Map<String, String> query,
  }) async {
    final params = {
      ...query,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'recvWindow': '5000',
    };
    final queryString = params.entries
        .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    final signature = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(queryString)).toString();
    final uri = _base.replace(
      path: '${_base.path}$path',
      query: '$queryString&signature=$signature',
    );
    return _client
        .get(uri, headers: {'X-MBX-APIKEY': apiKey})
        .timeout(const Duration(seconds: 20));
  }
}

List<String> _symbolsToSync(List<Coin> coins) {
  final priority = [
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'XRPUSDT',
    'DOGEUSDT',
    'ADAUSDT',
    'AVAXUSDT',
    'DOTUSDT',
    'LINKUSDT',
  ];
  final fromMarket = coins.take(16).map((coin) => coin.spotSymbol);
  return {...priority, ...fromMarket}.toList();
}

Coin? _coinForSymbol(String binanceSymbol, List<Coin> coins) {
  final base = binanceSymbol.replaceFirst(RegExp(r'(USDT|BUSD|USDC)$'), '');
  for (final coin in coins) {
    if (coin.symbol.toUpperCase() == base) return coin;
  }
  return null;
}

Coin _resolveCoin(
  String coinId,
  String symbol,
  String name,
  String imageUrl,
  List<Coin> coins,
) {
  for (final coin in coins) {
    if (coin.id == coinId ||
        coin.symbol.toUpperCase() == symbol.toUpperCase()) {
      return coin;
    }
  }
  return Coin(
    id: coinId,
    symbol: symbol,
    name: name,
    imageUrl: imageUrl,
    currentPrice: 0,
    priceChangePercent24h: 0,
    priceChange24h: 0,
    marketCap: 0,
    volume24h: 0,
    high24h: 0,
    low24h: 0,
    circulatingSupply: 0,
    rank: 0,
    lastUpdated: DateTime.now(),
  );
}

String _binanceError(http.Response response) {
  try {
    final body = jsonDecode(response.body);
    if (body is Map && body['msg'] != null) {
      return 'Binance HTTP ${response.statusCode}: ${body['msg']}';
    }
  } catch (_) {
    // Fall through to generic message.
  }
  return 'Binance HTTP ${response.statusCode}';
}
