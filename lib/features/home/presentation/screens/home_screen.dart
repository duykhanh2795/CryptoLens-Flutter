import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_dashboard_widgets.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_market_widgets.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_misc_widgets.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_navigation.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_wallet_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/news/presentation/widgets/news_preview_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.controller,
    required this.onOpenMarkets,
    required this.onOpenNews,
    required this.onOpenWallets,
    required this.onOpenPortfolio,
    super.key,
  });

  final MarketController controller;
  final VoidCallback onOpenMarkets;
  final VoidCallback onOpenNews;
  final VoidCallback onOpenWallets;
  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    final trending = controller.coins.take(8).toList();

    return ColoredBox(
      color: const Color(0xFF050607),
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            HomeTopBar(
              isRefreshing: controller.isRefreshing,
              onRefresh: controller.refresh,
            ),
            const SizedBox(height: 12),
            if (controller.error != null)
              ErrorBanner(message: controller.error!),
            BankingDashboardGrid(
              controller: controller,
              watchlistCount: controller.watchlistedIds.length,
              coverageCount: controller.coins.length,
              onOpenPortfolio: onOpenPortfolio,
            ),
            if (controller.isLoading)
              const AppLoadingState(height: 120)
            else ...[
              const SizedBox(height: 14),
              TrendingSectionHeader(onTap: onOpenMarkets),
              const SizedBox(height: 8),
              TrendingRow(
                coins: trending,
                onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
              ),
              const SizedBox(height: 18),
              MarketMoveSection(
                title: 'Top Gainers',
                coins: controller.topGainers,
                onSeeAll: onOpenMarkets,
                onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
              ),
              const SizedBox(height: 8),
              MarketMoveSection(
                title: 'Top Losers',
                coins: controller.topLosers,
                onSeeAll: onOpenMarkets,
                onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
              ),
              const SizedBox(height: 8),
              TrendingWalletsHomeSection(onSeeAll: onOpenWallets),
            ],
            const SizedBox(height: 22),
            NewsPreviewSection(onSeeAll: onOpenNews),
            const SizedBox(height: 14),
            const AiInsightBanner(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _openCoinDetail(
    BuildContext context,
    MarketController controller,
    Coin coin,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoinDetailScreen(controller: controller, coin: coin),
      ),
    );
  }
}
