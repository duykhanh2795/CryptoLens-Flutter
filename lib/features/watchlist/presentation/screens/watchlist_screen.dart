import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/core/widgets/empty_state.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

part '../widgets/watchlist_coin_row.dart';
part '../widgets/watchlist_top_bar.dart';
part '../widgets/watchlist_filter_widgets.dart';
part '../widgets/watchlist_models.dart';

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
