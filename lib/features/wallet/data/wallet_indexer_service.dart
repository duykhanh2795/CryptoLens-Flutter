import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';

class WalletIndexerService {
  WalletIndexerService({http.Client? client})
    : _client = client ?? http.Client();

  static const _moralisApiKey = String.fromEnvironment('MORALIS_API_KEY');
  static const _alchemyApiKey = String.fromEnvironment('ALCHEMY_API_KEY');

  final http.Client _client;

  bool get hasMoralisKey => _moralisApiKey.trim().isNotEmpty;
  bool get hasAlchemyKey => _alchemyApiKey.trim().isNotEmpty;

  Future<IndexedWalletData> fetchDetail({
    required TrendingWallet wallet,
    required List<Coin> coins,
  }) async {
    final notes = <String>[];
    final assets = <WalletAsset>[];
    final history = <WalletTransaction>[];

    if (wallet.chain == WalletChain.bitcoin) {
      notes.add('Bitcoin detail uses local fallback in this Flutter build.');
      return IndexedWalletData(
        assets: assets,
        history: history,
        note: notes.join('\n'),
      );
    }

    if (hasMoralisKey) {
      try {
        assets.addAll(await _fetchMoralisAssets(wallet: wallet, coins: coins));
      } catch (error) {
        notes.add('Moralis assets unavailable: $error');
      }
    } else {
      notes.add('Add MORALIS_API_KEY to enable indexed token assets.');
    }

    if (hasAlchemyKey && wallet.chain.alchemyNetwork != null) {
      try {
        history.addAll(
          await _fetchAlchemyHistory(wallet: wallet, coins: coins),
        );
      } catch (error) {
        notes.add('Alchemy history unavailable: $error');
      }
    } else {
      notes.add('Add ALCHEMY_API_KEY to enable EVM transfer history.');
    }

    return IndexedWalletData(
      assets: _mergeAssets(assets),
      history: history,
      note: notes.isEmpty ? null : notes.join('\n'),
    );
  }

  Future<List<WalletAsset>> _fetchMoralisAssets({
    required TrendingWallet wallet,
    required List<Coin> coins,
  }) async {
    final uri = Uri.https(
      'deep-index.moralis.io',
      '/api/v2.2/wallets/${wallet.address}/tokens',
      {'chain': wallet.chain.moralisChain, 'exclude_spam': 'true'},
    );
    final response = await _client.get(
      uri,
      headers: {'X-API-Key': _moralisApiKey},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw 'HTTP ${response.statusCode}';
    }
    final decoded = jsonDecode(response.body);
    final rawItems = decoded is Map<String, dynamic>
        ? decoded['result']
        : decoded;
    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final symbol = _string(json['symbol']).toUpperCase();
          final decimals = _int(json['decimals'], fallback: 18).clamp(0, 36);
          final rawBalance = _string(json['balance']);
          final quantity = _parseTokenQuantity(rawBalance, decimals);
          final price = _number(json['usd_price']);
          final value = _number(json['usd_value']);
          final coin = _coinBySymbol(symbol, coins);
          return WalletAsset(
            symbol: symbol.isEmpty ? 'TOKEN' : symbol,
            name: _string(json['name']).isEmpty
                ? symbol
                : _string(json['name']),
            quantity: quantity,
            priceUsd: price > 0 ? price : coin?.currentPrice,
            valueUsd: value > 0
                ? value
                : (coin == null ? null : coin.currentPrice * quantity),
            changePercent24h: coin?.priceChangePercent24h ?? 0,
            chain: wallet.chain,
            networkLabel: wallet.chain.label,
            contractAddress: _string(json['token_address']),
            coinId: coin?.id,
            logoUrl: _string(json['logo']).isEmpty
                ? coin?.imageUrl
                : _string(json['logo']),
          );
        })
        .where((asset) => asset.quantity > 0)
        .toList();
  }

  Future<List<WalletTransaction>> _fetchAlchemyHistory({
    required TrendingWallet wallet,
    required List<Coin> coins,
  }) async {
    final network = wallet.chain.alchemyNetwork;
    if (network == null) return const [];
    final uri = Uri.https('$network.g.alchemy.com', '/v2/$_alchemyApiKey');
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'alchemy_getAssetTransfers',
      'params': [
        {
          'fromBlock': '0x0',
          'toBlock': 'latest',
          'toAddress': wallet.address,
          'category': ['external', 'erc20', 'erc721', 'erc1155', 'internal'],
          'withMetadata': true,
          'excludeZeroValue': true,
          'maxCount': '0x32',
          'order': 'desc',
        },
      ],
    });
    final response = await _client.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw 'HTTP ${response.statusCode}';
    }
    final decoded = jsonDecode(response.body);
    final result = decoded is Map<String, dynamic>
        ? decoded['result'] as Map<String, dynamic>?
        : null;
    final transfers = result?['transfers'];
    if (transfers is! List) return const [];

    return transfers.whereType<Map<String, dynamic>>().map((json) {
      final from = _string(json['from']);
      final to = _string(json['to']);
      final symbol = _string(json['asset']).toUpperCase();
      final amount = _number(json['value']);
      final coin = _coinBySymbol(symbol, coins);
      final hash = _string(json['hash']);
      final rawTime =
          (json['metadata'] as Map<String, dynamic>?)?['blockTimestamp']
              ?.toString();
      final timestamp = DateTime.tryParse(rawTime ?? '') ?? DateTime.now();
      final incoming = to.toLowerCase() == wallet.address.toLowerCase();
      return WalletTransaction(
        id: hash.isEmpty
            ? '${wallet.address}_${timestamp.microsecondsSinceEpoch}'
            : hash,
        type: incoming
            ? WalletTransactionType.received
            : WalletTransactionType.sent,
        symbol: symbol.isEmpty ? wallet.chain.nativeSymbol : symbol,
        amount: amount,
        valueUsd: coin == null ? null : coin.currentPrice * max(amount, 0),
        counterparty: incoming ? from : to,
        timestamp: timestamp,
        networkLabel: wallet.chain.label,
      );
    }).toList();
  }

  List<WalletAsset> _mergeAssets(List<WalletAsset> assets) {
    final byKey = <String, WalletAsset>{};
    for (final asset in assets) {
      final key =
          '${asset.displayNetwork}:${asset.contractAddress ?? asset.symbol}';
      final current = byKey[key];
      if (current == null || (asset.valueUsd ?? 0) > (current.valueUsd ?? 0)) {
        byKey[key] = asset;
      }
    }
    return byKey.values.toList()
      ..sort((a, b) => (b.valueUsd ?? 0).compareTo(a.valueUsd ?? 0));
  }

  Coin? _coinBySymbol(String symbol, List<Coin> coins) {
    for (final coin in coins) {
      if (coin.symbol.toUpperCase() == symbol.toUpperCase()) return coin;
    }
    return null;
  }

  double _parseTokenQuantity(String raw, int decimals) {
    if (raw.isEmpty) return 0;
    final integer = BigInt.tryParse(raw);
    if (integer == null) return double.tryParse(raw) ?? 0;
    return integer.toDouble() / pow(10, decimals);
  }

  String _string(Object? value) => value?.toString() ?? '';

  int _int(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class IndexedWalletData {
  const IndexedWalletData({
    required this.assets,
    required this.history,
    required this.note,
  });

  final List<WalletAsset> assets;
  final List<WalletTransaction> history;
  final String? note;
}
