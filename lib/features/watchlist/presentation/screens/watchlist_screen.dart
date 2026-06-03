import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/widgets/app_bottom_sheet.dart';
import 'package:cryptolens_flutter/core/widgets/empty_state.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/watchlist/presentation/widgets/watchlist_coin_row.dart';
import 'package:cryptolens_flutter/features/watchlist/presentation/widgets/watchlist_filter_widgets.dart';
import 'package:cryptolens_flutter/features/watchlist/domain/watchlist_filters.dart';
import 'package:cryptolens_flutter/features/watchlist/presentation/widgets/watchlist_top_bar.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _showSearch = false;
  WatchlistFilter _filter = WatchlistFilter.all;
  WatchlistSortOrder _sortOrder = WatchlistSortOrder.defaultOrder;

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.searchQuery.trim().toLowerCase();
    final coins = filterAndSortWatchlistCoins(
      coins: widget.controller.watchlistCoins,
      query: query,
      filter: _filter,
      sortOrder: _sortOrder,
    );
    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          WatchlistTopBar(
            controller: widget.controller,
            isSearchVisible: _showSearch || query.isNotEmpty,
            onSearchToggle: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) widget.controller.setSearchQuery('');
            },
            onSort: _showSortSheet,
          ),
          WatchlistTabsAndFilters(
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
                    WatchlistCoinRow(
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

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: AppBottomSheetScaffold(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final order in WatchlistSortOrder.values)
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
