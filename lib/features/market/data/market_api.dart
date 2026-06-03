import 'package:http/http.dart' as http;

import 'package:cryptolens_flutter/core/errors/network_exception.dart';
import 'package:cryptolens_flutter/core/network/api_client.dart';
import 'package:cryptolens_flutter/core/network/network_config.dart';
import 'package:cryptolens_flutter/core/utils/json_readers.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/kline.dart';

class MarketApi {
  MarketApi({http.Client? client}) : _client = ApiClient(client: client);

  static final Uri _coinGeckoBase = NetworkConfig.coinGeckoBase;
  static final Uri _binanceBase = NetworkConfig.binanceSpotBase;
  static final Uri _binanceFuturesBase = NetworkConfig.binanceFuturesBase;

  final ApiClient _client;

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
    final body = (await _client.getJson(uri, label: 'CoinGecko markets')).data;
    if (body is! List) {
      throw NetworkException.invalidPayload('markets');
    }
    return body.cast<Map<String, dynamic>>().map(Coin.fromCoinGecko).toList();
  }

  Future<Map<String, PriceTicker>> fetchSpotTickers() async {
    final uri = _binanceBase.replace(path: '${_binanceBase.path}ticker/24hr');
    final body = (await _client.getJson(uri, label: 'Binance tickers')).data;
    if (body is! List) throw NetworkException.invalidPayload('ticker');
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
    final body = (await _client.getJson(
      uri,
      label: 'CoinGecko coin detail',
    )).data;
    if (body is! Map<String, dynamic>) {
      throw NetworkException.invalidPayload('coin detail');
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
    final body = (await _client.getJson(uri, label: 'Binance klines')).data;
    if (body is! List) throw NetworkException.invalidPayload('kline');
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
    final body = (await _client.getJson(
      uri,
      label: 'Binance futures klines',
    )).data;
    if (body is! List) throw NetworkException.invalidPayload('kline');
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
    final premiumBody = (await _client.getJson(
      premiumUri,
      label: 'Binance futures premium',
    )).data;
    final openInterestBody = (await _client.getJson(
      openInterestUri,
      label: 'Binance futures open interest',
    )).data;
    if (premiumBody is! Map<String, dynamic> ||
        openInterestBody is! Map<String, dynamic>) {
      throw NetworkException.invalidPayload('futures metrics');
    }
    return FuturesMetrics.fromBinance(premiumBody, openInterestBody);
  }

  void dispose() => _client.close();
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
    final nextFundingMillis = readInt(premium['nextFundingTime']);
    return FuturesMetrics(
      markPrice: readDouble(premium['markPrice']),
      indexPrice: readDouble(premium['indexPrice']),
      lastFundingRate: readDouble(premium['lastFundingRate']),
      nextFundingTime: nextFundingMillis <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(nextFundingMillis),
      openInterest: readDouble(openInterest['openInterest']),
    );
  }
}
