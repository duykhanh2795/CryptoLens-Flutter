import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptolens_flutter/core/errors/app_exception.dart';
import 'package:cryptolens_flutter/core/network/network_config.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/kline.dart';

class MarketApi {
  MarketApi({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _coinGeckoBase = NetworkConfig.coinGeckoBase;
  static final Uri _binanceBase = NetworkConfig.binanceSpotBase;
  static final Uri _binanceFuturesBase = NetworkConfig.binanceFuturesBase;

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
        .timeout(NetworkConfig.defaultTimeout);
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
        .timeout(NetworkConfig.defaultTimeout);
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
        .timeout(NetworkConfig.defaultTimeout);
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
        .timeout(NetworkConfig.defaultTimeout);
    _throwIfFailed(response, 'Binance klines');
    final body = jsonDecode(response.body);
    if (body is! List) throw const FormatException('Unexpected kline payload');
    return body.cast<List<dynamic>>().map(Kline.fromBinance).toList();
  }

  Future<List<Kline>> fetchFuturesKlines({
    required String symbol,
    String interval = '1d',
    int limit = 60,
  }) async {
    final uri = _binanceFuturesBase.replace(
      path: '${_binanceFuturesBase.path}klines',
      queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': '$limit',
      },
    );
    final response = await _client
        .get(uri)
        .timeout(NetworkConfig.defaultTimeout);
    _throwIfFailed(response, 'Binance futures klines');
    final body = jsonDecode(response.body);
    if (body is! List) throw const FormatException('Unexpected kline payload');
    return body.cast<List<dynamic>>().map(Kline.fromBinance).toList();
  }

  Future<FuturesMetrics> fetchFuturesMetrics({required String symbol}) async {
    final premiumUri = _binanceFuturesBase.replace(
      path: '${_binanceFuturesBase.path}premiumIndex',
      queryParameters: {'symbol': symbol},
    );
    final openInterestUri = _binanceFuturesBase.replace(
      path: '${_binanceFuturesBase.path}openInterest',
      queryParameters: {'symbol': symbol},
    );
    final premium = await _client
        .get(premiumUri)
        .timeout(NetworkConfig.defaultTimeout);
    _throwIfFailed(premium, 'Binance futures premium');
    final openInterest = await _client
        .get(openInterestUri)
        .timeout(NetworkConfig.defaultTimeout);
    _throwIfFailed(openInterest, 'Binance futures open interest');
    final premiumBody = jsonDecode(premium.body);
    final openInterestBody = jsonDecode(openInterest.body);
    if (premiumBody is! Map<String, dynamic> ||
        openInterestBody is! Map<String, dynamic>) {
      throw const FormatException('Unexpected futures metrics payload');
    }
    return FuturesMetrics.fromBinance(premiumBody, openInterestBody);
  }

  void dispose() => _client.close();

  static void _throwIfFailed(http.Response response, String label) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw HttpException('$label failed: HTTP ${response.statusCode}');
  }
}

class HttpException extends AppException {
  const HttpException(super.message);
}

class FuturesMetrics {
  const FuturesMetrics({
    required this.markPrice,
    required this.indexPrice,
    required this.lastFundingRate,
    required this.nextFundingTime,
    required this.openInterest,
  });

  final double markPrice;
  final double indexPrice;
  final double lastFundingRate;
  final DateTime? nextFundingTime;
  final double openInterest;

  double get fundingPercent => lastFundingRate * 100;
  double get premiumPercent =>
      indexPrice == 0 ? 0 : (markPrice - indexPrice) / indexPrice * 100;

  factory FuturesMetrics.fromBinance(
    Map<String, dynamic> premium,
    Map<String, dynamic> openInterest,
  ) {
    final nextFundingMillis =
        (premium['nextFundingTime'] as num?)?.toInt() ?? 0;
    return FuturesMetrics(
      markPrice: _number(premium['markPrice']),
      indexPrice: _number(premium['indexPrice']),
      lastFundingRate: _number(premium['lastFundingRate']),
      nextFundingTime: nextFundingMillis <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(nextFundingMillis),
      openInterest: _number(openInterest['openInterest']),
    );
  }
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
