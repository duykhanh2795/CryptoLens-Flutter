import 'package:cryptolens_flutter/features/market/domain/coin.dart';

enum WatchlistFilter { all, gainers, losers }

enum WatchlistSortOrder {
  defaultOrder,
  nameAsc,
  changeDesc,
  changeAsc,
  priceDesc,
  priceAsc,
}

extension WatchlistSortOrderX on WatchlistSortOrder {
  String get label => switch (this) {
    WatchlistSortOrder.defaultOrder => 'Popular',
    WatchlistSortOrder.nameAsc => 'Name A-Z',
    WatchlistSortOrder.changeDesc => '24h Change high to low',
    WatchlistSortOrder.changeAsc => '24h Change low to high',
    WatchlistSortOrder.priceDesc => 'Price high to low',
    WatchlistSortOrder.priceAsc => 'Price low to high',
  };
}

List<Coin> filterAndSortWatchlistCoins({
  required List<Coin> coins,
  required String query,
  required WatchlistFilter filter,
  required WatchlistSortOrder sortOrder,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final searched = coins
      .where(
        (coin) =>
            normalizedQuery.isEmpty ||
            coin.name.toLowerCase().contains(normalizedQuery) ||
            coin.symbol.toLowerCase().contains(normalizedQuery),
      )
      .where((coin) {
        return switch (filter) {
          WatchlistFilter.all => true,
          WatchlistFilter.gainers => coin.priceChangePercent24h >= 0,
          WatchlistFilter.losers => coin.priceChangePercent24h < 0,
        };
      })
      .toList();

  switch (sortOrder) {
    case WatchlistSortOrder.defaultOrder:
      return searched;
    case WatchlistSortOrder.nameAsc:
      searched.sort((a, b) => a.name.compareTo(b.name));
    case WatchlistSortOrder.changeDesc:
      searched.sort(
        (a, b) => b.priceChangePercent24h.compareTo(a.priceChangePercent24h),
      );
    case WatchlistSortOrder.changeAsc:
      searched.sort(
        (a, b) => a.priceChangePercent24h.compareTo(b.priceChangePercent24h),
      );
    case WatchlistSortOrder.priceDesc:
      searched.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    case WatchlistSortOrder.priceAsc:
      searched.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
  }
  return searched;
}
