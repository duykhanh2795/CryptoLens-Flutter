import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/coin.dart';
import '../models/kline.dart';

class MarketApi {
  MarketApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _coinGeckoBase = Uri.parse(
    'https://api.coingecko.com/api/v3/',
  );
  static final Uri _binanceBase = Uri.parse('https://api.binance.com/api/v3/');

  final http.Client _client;

  Future<List<Coin>> fetchTopCoins({
    String currency = 'usd',
    int perPage = 100,
    int page = 1,
  }) async {
    final uri = _coinGeckoBase.replace(
      path: '${_coinGeckoBase.path}coins/markets',
      queryParameters: {
        'vs_currency': currency,
        'order': 'market_cap_desc',
        'per_page': '$perPage',
        'page': '$page',
        'sparkline': 'false',
        'price_change_percentage': '24h',
        'locale': 'en',
        'precision': 'full',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    _throwIfFailed(response, 'CoinGecko markets');
    final body = jsonDecode(response.body);
    if (body is! List) {
      throw const FormatException('Unexpected markets payload');
    }
    return body.cast<Map<String, dynamic>>().map(Coin.fromCoinGecko).toList();
  }

  Future<Map<String, PriceTicker>> fetchSpotTickers() async {
    final uri = _binanceBase.replace(path: '${_binanceBase.path}ticker/24hr');
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    _throwIfFailed(response, 'Binance tickers');
    final body = jsonDecode(response.body);
    if (body is! List) throw const FormatException('Unexpected ticker payload');
    return {
      for (final item in body.cast<Map<String, dynamic>>())
        if (item['symbol'] is String) ...{
          item['symbol'] as String: PriceTicker.fromBinance(item),
        },
    };
  }

  Future<CoinDetail> fetchCoinDetail(String coinId) async {
    final uri = _coinGeckoBase.replace(
      path: '${_coinGeckoBase.path}coins/$coinId',
      queryParameters: {
        'localization': 'false',
        'tickers': 'false',
        'market_data': 'true',
        'community_data': 'false',
        'developer_data': 'false',
        'sparkline': 'false',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    _throwIfFailed(response, 'CoinGecko coin detail');
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected coin detail payload');
    }
    return CoinDetail.fromCoinGecko(body);
  }

  Future<List<Kline>> fetchSpotKlines({
    required String symbol,
    String interval = '1d',
    int limit = 60,
  }) async {
    final uri = _binanceBase.replace(
      path: '${_binanceBase.path}klines',
      queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': '$limit',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));
    _throwIfFailed(response, 'Binance klines');
    final body = jsonDecode(response.body);
    if (body is! List) throw const FormatException('Unexpected kline payload');
    return body.cast<List<dynamic>>().map(Kline.fromBinance).toList();
  }

  void dispose() => _client.close();

  static void _throwIfFailed(http.Response response, String label) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw HttpException('$label failed: HTTP ${response.statusCode}');
  }
}

class HttpException implements Exception {
  const HttpException(this.message);
  final String message;

  @override
  String toString() => message;
}
