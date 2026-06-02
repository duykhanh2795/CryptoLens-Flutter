import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

class MarketsHeader extends StatelessWidget {
  const MarketsHeader({required this.controller, super.key});

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

class MarketSearchField extends StatelessWidget {
  const MarketSearchField({required this.controller, super.key});

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

class MarketTabs extends StatelessWidget {
  const MarketTabs({required this.controller, super.key});

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

class MarketTableHeader extends StatelessWidget {
  const MarketTableHeader({super.key});

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
