import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/core/widgets/empty_state.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

enum _WatchlistFilter { all, gainers, losers }

enum _WatchlistSortOrder {
  defaultOrder,
  nameAsc,
  changeDesc,
  changeAsc,
  priceDesc,
  priceAsc,
}

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _showSearch = false;
  _WatchlistFilter _filter = _WatchlistFilter.all;
  _WatchlistSortOrder _sortOrder = _WatchlistSortOrder.defaultOrder;

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.searchQuery.trim().toLowerCase();
    final coins = _applySort(
      _applyFilter(widget.controller.watchlistCoins, query),
    );
    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _WatchlistTopBar(
            controller: widget.controller,
            isSearchVisible: _showSearch || query.isNotEmpty,
            onSearchToggle: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) widget.controller.setSearchQuery('');
            },
            onSort: _showSortSheet,
          ),
          _WatchlistTabsAndFilters(
            controller: widget.controller,
            showSearch: _showSearch || query.isNotEmpty,
            filter: _filter,
            sortOrder: _sortOrder,
            onFilterChanged: (filter) => setState(() => _filter = filter),
            onSortChanged: (sortOrder) =>
                setState(() => _sortOrder = sortOrder),
          ),
          if (coins.isEmpty)
            const SizedBox(
              height: 520,
              child: EmptyState(
                icon: Icons.star_border_rounded,
                title: 'Your watchlist is empty',
                message:
                    'Go to Markets and tap the star icon on any coin to add it here.',
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Column(
                children: [
                  for (final coin in coins)
                    _WatchlistCoinRow(
                      coin: coin,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CoinDetailScreen(
                            controller: widget.controller,
                            coin: coin,
                          ),
                        ),
                      ),
                      onRemove: () async {
                        await widget.controller.toggleWatchlist(coin.id);
                        if (mounted) setState(() {});
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Coin> _applyFilter(List<Coin> source, String query) {
    final searched = source
        .where(
          (coin) =>
              query.isEmpty ||
              coin.name.toLowerCase().contains(query) ||
              coin.symbol.toLowerCase().contains(query),
        )
        .where((coin) {
          return switch (_filter) {
            _WatchlistFilter.all => true,
            _WatchlistFilter.gainers => coin.priceChangePercent24h >= 0,
            _WatchlistFilter.losers => coin.priceChangePercent24h < 0,
          };
        })
        .toList();
    return searched;
  }

  List<Coin> _applySort(List<Coin> source) {
    final coins = [...source];
    switch (_sortOrder) {
      case _WatchlistSortOrder.defaultOrder:
        return coins;
      case _WatchlistSortOrder.nameAsc:
        coins.sort((a, b) => a.name.compareTo(b.name));
      case _WatchlistSortOrder.changeDesc:
        coins.sort(
          (a, b) => b.priceChangePercent24h.compareTo(a.priceChangePercent24h),
        );
      case _WatchlistSortOrder.changeAsc:
        coins.sort(
          (a, b) => a.priceChangePercent24h.compareTo(b.priceChangePercent24h),
        );
      case _WatchlistSortOrder.priceDesc:
        coins.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
      case _WatchlistSortOrder.priceAsc:
        coins.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
    }
    return coins;
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              for (final order in _WatchlistSortOrder.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(order.label),
                  trailing: _sortOrder == order
                      ? const Icon(Icons.check_rounded, color: AppColors.accent)
                      : null,
                  onTap: () {
                    setState(() => _sortOrder = order);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistCoinRow extends StatelessWidget {
  const _WatchlistCoinRow({
    required this.coin,
    required this.onTap,
    required this.onRemove,
  });

  final Coin coin;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final positive = coin.priceChangePercent24h >= 0;
    return InkWell(
      onTap: onTap,
      onLongPress: onRemove,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.currency_bitcoin_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(coin.currentPrice),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: positive
                        ? AppColors.greenSurface
                        : AppColors.redSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        positive
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        color: positive ? AppColors.green : AppColors.red,
                        size: 16,
                      ),
                      Text(
                        formatPercent(
                          coin.priceChangePercent24h.abs(),
                        ).replaceFirst('+', ''),
                        style: TextStyle(
                          color: positive ? AppColors.green : AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remove from watchlist',
              onPressed: onRemove,
              icon: const Icon(
                Icons.star_border_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistTopBar extends StatelessWidget {
  const _WatchlistTopBar({
    required this.controller,
    required this.isSearchVisible,
    required this.onSearchToggle,
    required this.onSort,
  });

  final MarketController controller;
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Text(
              'CL',
              style: TextStyle(
                color: AppColors.background,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.circle, size: 9, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                controller.isRefreshing ? 'SYNC' : 'LIVE',
                style: TextStyle(
                  color: controller.isRefreshing
                      ? AppColors.textTertiary
                      : AppColors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Search',
                onPressed: onSearchToggle,
                icon: Icon(
                  Icons.search_rounded,
                  size: 27,
                  color: isSearchVisible
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Sort',
                onPressed: onSort,
                icon: const Icon(
                  Icons.sort_rounded,
                  size: 27,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.refresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 27,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WatchlistTabsAndFilters extends StatelessWidget {
  const _WatchlistTabsAndFilters({
    required this.controller,
    required this.showSearch,
    required this.filter,
    required this.sortOrder,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final MarketController controller;
  final bool showSearch;
  final _WatchlistFilter filter;
  final _WatchlistSortOrder sortOrder;
  final ValueChanged<_WatchlistFilter> onFilterChanged;
  final ValueChanged<_WatchlistSortOrder> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _WatchlistChipData(
        label: 'Popular',
        selected:
            filter == _WatchlistFilter.all &&
            sortOrder == _WatchlistSortOrder.defaultOrder,
        onTap: () {
          onFilterChanged(_WatchlistFilter.all);
          onSortChanged(_WatchlistSortOrder.defaultOrder);
        },
      ),
      _WatchlistChipData(
        label: 'Gainers',
        selected: filter == _WatchlistFilter.gainers,
        onTap: () => onFilterChanged(_WatchlistFilter.gainers),
      ),
      _WatchlistChipData(
        label: 'Losers',
        selected: filter == _WatchlistFilter.losers,
        onTap: () => onFilterChanged(_WatchlistFilter.losers),
      ),
      _WatchlistChipData(
        label: 'Price',
        selected:
            sortOrder == _WatchlistSortOrder.priceDesc ||
            sortOrder == _WatchlistSortOrder.priceAsc,
        sortIcon: true,
        onTap: () => onSortChanged(
          sortOrder == _WatchlistSortOrder.priceDesc
              ? _WatchlistSortOrder.priceAsc
              : _WatchlistSortOrder.priceDesc,
        ),
      ),
      _WatchlistChipData(
        label: '24h Change',
        selected:
            sortOrder == _WatchlistSortOrder.changeDesc ||
            sortOrder == _WatchlistSortOrder.changeAsc,
        sortIcon: true,
        onTap: () => onSortChanged(
          sortOrder == _WatchlistSortOrder.changeDesc
              ? _WatchlistSortOrder.changeAsc
              : _WatchlistSortOrder.changeDesc,
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                'Watchlist',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 22),
              Text(
                'Coins',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 14),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: controller.setSearchQuery,
                      cursorColor: AppColors.accent,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Search symbol or name',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (controller.searchQuery.isNotEmpty)
                    IconButton(
                      onPressed: () => controller.setSearchQuery(''),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final chip = chips[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: chip.onTap,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: chip.selected
                          ? AppColors.surfaceVariant
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: chip.selected ? 10 : 0,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Text(
                            chip.label,
                            style: TextStyle(
                              color: chip.selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (chip.sortIcon) ...[
                            const SizedBox(width: 2),
                            Icon(
                              sortOrder == _WatchlistSortOrder.priceAsc ||
                                      sortOrder == _WatchlistSortOrder.changeAsc
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
