import 'package:flutter/material.dart';

import '../../core/models/coin.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../market/coin_detail_screen.dart';
import '../market/market_controller.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.searchQuery.trim().toLowerCase();
    final coins = widget.controller.watchlistCoins
        .where(
          (coin) =>
              query.isEmpty ||
              coin.name.toLowerCase().contains(query) ||
              coin.symbol.toLowerCase().contains(query),
        )
        .toList();
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
          ),
          _WatchlistTabsAndFilters(
            controller: widget.controller,
            showSearch: _showSearch || query.isNotEmpty,
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
  });

  final MarketController controller;
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;

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
                tooltip: 'Scan',
                onPressed: () {},
                icon: const Icon(
                  Icons.crop_free_rounded,
                  size: 27,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: controller.refresh,
                icon: const Icon(
                  Icons.sort_rounded,
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
  });

  final MarketController controller;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    const labels = ['Popular', 'Gainers', 'Losers', 'Price', '24h Change'];
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
              itemCount: labels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final selected = index == 0;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.surfaceVariant
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 10 : 0,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          labels[index],
                          style: TextStyle(
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (labels[index] == 'Price' ||
                            labels[index] == '24h Change') ...[
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.unfold_more_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ],
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
