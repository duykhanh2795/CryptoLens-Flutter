import 'package:flutter_test/flutter_test.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/watchlist/domain/watchlist_filters.dart';

void main() {
  group('watchlist filters', () {
    final coins = [
      Coin.snapshot(
        id: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        imageUrl: '',
        currentPrice: 73000,
      ).copyWith(priceChangePercent24h: 1.5),
      Coin.snapshot(
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        imageUrl: '',
        currentPrice: 3500,
      ).copyWith(priceChangePercent24h: -2.0),
      Coin.snapshot(
        id: 'solana',
        symbol: 'SOL',
        name: 'Solana',
        imageUrl: '',
        currentPrice: 180,
      ).copyWith(priceChangePercent24h: 4.0),
    ];

    test('filters by search query and gainers', () {
      final filtered = filterAndSortWatchlistCoins(
        coins: coins,
        query: 'sol',
        filter: WatchlistFilter.gainers,
        sortOrder: WatchlistSortOrder.defaultOrder,
      );

      expect(filtered.map((coin) => coin.symbol), ['SOL']);
    });

    test('sorts by price and change', () {
      final byPrice = filterAndSortWatchlistCoins(
        coins: coins,
        query: '',
        filter: WatchlistFilter.all,
        sortOrder: WatchlistSortOrder.priceAsc,
      );
      final byChange = filterAndSortWatchlistCoins(
        coins: coins,
        query: '',
        filter: WatchlistFilter.all,
        sortOrder: WatchlistSortOrder.changeDesc,
      );

      expect(byPrice.map((coin) => coin.symbol), ['SOL', 'ETH', 'BTC']);
      expect(byChange.map((coin) => coin.symbol), ['SOL', 'BTC', 'ETH']);
    });
  });
}
