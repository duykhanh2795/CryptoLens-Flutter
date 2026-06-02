part of '../screens/watchlist_screen.dart';

class _WatchlistChipData {
  const _WatchlistChipData({
    required this.label,
    required this.selected,
    required this.onTap,
    this.sortIcon = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool sortIcon;
}

extension on _WatchlistSortOrder {
  String get label => switch (this) {
    _WatchlistSortOrder.defaultOrder => 'Popular',
    _WatchlistSortOrder.nameAsc => 'Name A-Z',
    _WatchlistSortOrder.changeDesc => '24h Change high to low',
    _WatchlistSortOrder.changeAsc => '24h Change low to high',
    _WatchlistSortOrder.priceDesc => 'Price high to low',
    _WatchlistSortOrder.priceAsc => 'Price low to high',
  };
}
