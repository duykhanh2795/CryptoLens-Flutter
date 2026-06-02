import 'package:flutter/material.dart';

enum WatchlistFilter { all, gainers, losers }

enum WatchlistSortOrder {
  defaultOrder,
  nameAsc,
  changeDesc,
  changeAsc,
  priceDesc,
  priceAsc,
}

class WatchlistChipData {
  const WatchlistChipData({
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
