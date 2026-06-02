import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/kline.dart';
import 'package:cryptolens_flutter/features/market/data/market_api.dart';
import 'package:cryptolens_flutter/features/watchlist/data/watchlist_store.dart';

enum MarketTab { all, gainers, losers, newListings }

class MarketController extends ChangeNotifier {
  MarketController({required this.api, required this.watchlistStore});

  final MarketApi api;
  final WatchlistStore watchlistStore;

  bool isLoading = true;
  bool isRefreshing = false;
  String? error;
  List<Coin> coins = const [];
  Set<String> watchlistedIds = const {};
  MarketTab selectedTab = MarketTab.all;
  String searchQuery = '';

  List<Coin> get visibleCoins {
    var result = coins;
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result
          .where(
            (coin) =>
                coin.name.toLowerCase().contains(query) ||
                coin.symbol.toLowerCase().contains(query),
          )
          .toList();
    }
    return switch (selectedTab) {
      MarketTab.all => result,
      MarketTab.gainers =>
        result.where((coin) => coin.priceChangePercent24h > 0).toList()..sort(
          (a, b) => b.priceChangePercent24h.compareTo(a.priceChangePercent24h),
        ),
      MarketTab.losers =>
        result.where((coin) => coin.priceChangePercent24h < 0).toList()..sort(
          (a, b) => a.priceChangePercent24h.compareTo(b.priceChangePercent24h),
        ),
      MarketTab.newListings => [
        ...result,
      ]..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated)),
    };
  }

  List<Coin> get watchlistCoins =>
      coins.where((coin) => watchlistedIds.contains(coin.id)).toList();

  List<Coin> get topGainers {
    final result =
        coins.where((coin) => coin.priceChangePercent24h > 0).toList()..sort(
          (a, b) => b.priceChangePercent24h.compareTo(a.priceChangePercent24h),
        );
    return result.take(5).toList();
  }

  List<Coin> get topLosers {
    final result =
        coins.where((coin) => coin.priceChangePercent24h < 0).toList()..sort(
          (a, b) => a.priceChangePercent24h.compareTo(b.priceChangePercent24h),
        );
    return result.take(5).toList();
  }

  Future<void> initialize() async {
    unawaited(_loadWatchlist());
    await refresh();
  }

  Future<void> _loadWatchlist() async {
    try {
      watchlistedIds = await watchlistStore.load();
    } catch (_) {
      watchlistedIds = const {};
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    isRefreshing = coins.isNotEmpty;
    isLoading = coins.isEmpty;
    error = null;
    notifyListeners();
    try {
      final market = await api.fetchTopCoins(perPage: 100);
      coins = market;
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
      unawaited(_refreshSpotTickers(market));
    } catch (exception) {
      error = exception.toString();
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSpotTickers(List<Coin> market) async {
    try {
      Map<String, PriceTicker> tickers = const {};
      try {
        tickers = await api.fetchSpotTickers();
      } catch (_) {
        tickers = const {};
      }
      coins = market.map((coin) {
        final ticker = tickers[coin.spotSymbol];
        return ticker == null ? coin : coin.applyTicker(ticker);
      }).toList();
      notifyListeners();
    } catch (_) {
      // CoinGecko data is already visible; Binance live ticker enrichment is optional.
    }
  }

  void setTab(MarketTab tab) {
    selectedTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<void> toggleWatchlist(String coinId) async {
    watchlistedIds = await watchlistStore.toggle(coinId);
    notifyListeners();
  }

  Future<List<Kline>> loadChart(Coin coin) async {
    return api.fetchSpotKlines(
      symbol: coin.spotSymbol,
      interval: '1d',
      limit: 60,
    );
  }

  Future<List<Kline>> loadChartForInterval(Coin coin, String interval) {
    return api.fetchSpotKlines(
      symbol: coin.spotSymbol,
      interval: interval,
      limit: 80,
    );
  }

  Future<List<Kline>> loadFuturesChartForInterval(Coin coin, String interval) {
    return api.fetchFuturesKlines(
      symbol: coin.spotSymbol,
      interval: interval,
      limit: 80,
    );
  }

  Future<CoinDetail> loadCoinDetail(Coin coin) => api.fetchCoinDetail(coin.id);

  Future<FuturesMetrics> loadFuturesMetrics(Coin coin) {
    return api.fetchFuturesMetrics(symbol: coin.spotSymbol);
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
