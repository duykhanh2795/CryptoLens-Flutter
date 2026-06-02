import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/shared/widgets/coin_row.dart';
import 'package:cryptolens_flutter/shared/widgets/empty_state.dart';
import 'coin_detail_screen.dart';
import 'market_controller.dart';

class MarketsScreen extends StatelessWidget {
  const MarketsScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    final coins = controller.visibleCoins;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          _MarketsHeader(controller: controller),
          const SizedBox(height: 12),
          _MarketSearchField(controller: controller),
          const SizedBox(height: 14),
          _MarketTabs(controller: controller),
          const SizedBox(height: 10),
          const _MarketTableHeader(),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 170),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (coins.isEmpty)
            const SizedBox(
              height: 420,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No coins found',
                message: 'Try another symbol or reset market filters.',
              ),
            )
          else
            for (final coin in coins)
              MarketCoinRow(
                coin: coin,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CoinDetailScreen(controller: controller, coin: coin),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _MarketsHeader extends StatelessWidget {
  const _MarketsHeader({required this.controller});

  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Markets',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              const Text(
                'Live crypto prices',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Watchlist',
          onPressed: () {},
          icon: const Icon(
            Icons.star_border_rounded,
            size: 25,
            color: AppColors.accent,
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: controller.isRefreshing ? null : controller.refresh,
          icon: controller.isRefreshing
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 25,
                  color: AppColors.textSecondary,
                ),
        ),
      ],
    );
  }
}

class _MarketSearchField extends StatelessWidget {
  const _MarketSearchField({required this.controller});

  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 18,
          ),
          const SizedBox(width: 8),
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
                hintText: 'Search coins...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTabs extends StatelessWidget {
  const _MarketTabs({required this.controller});

  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (MarketTab.all, 'All'),
      (MarketTab.gainers, 'Gainers'),
      (MarketTab.losers, 'Losers'),
      (MarketTab.newListings, 'New'),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (tab, label) in tabs)
            InkWell(
              onTap: () => controller.setTab(tab),
              borderRadius: BorderRadius.circular(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 78,
                    height: 36,
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: controller.selectedTab == tab
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 2,
                    color: controller.selectedTab == tab
                        ? AppColors.accent
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MarketTableHeader extends StatelessWidget {
  const _MarketTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Name',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              'Last Price',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '24h Change',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
