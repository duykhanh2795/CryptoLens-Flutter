class NetworkConfig {
  const NetworkConfig._();

  static const defaultTimeout = Duration(seconds: 20);
  static const rssTimeout = Duration(seconds: 12);

  static final coinGeckoBase = Uri.parse('https://api.coingecko.com/api/v3/');
  static final coinGeckoNewsBase = Uri.parse(
    'https://pro-api.coingecko.com/api/v3/news',
  );
  static final binanceSpotBase = Uri.parse('https://api.binance.com/api/v3/');
  static final binanceFuturesBase = Uri.parse(
    'https://fapi.binance.com/fapi/v1/',
  );
}
