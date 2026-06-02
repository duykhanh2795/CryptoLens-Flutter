import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/news/presentation/screens/news_screen.dart';

part '../widgets/home_navigation.dart';
part '../widgets/home_dashboard_widgets.dart';
part '../widgets/home_market_widgets.dart';
part '../widgets/home_wallet_widgets.dart';
part '../widgets/home_misc_widgets.dart';

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
            _HomeTopBar(
              isRefreshing: controller.isRefreshing,
              onRefresh: controller.refresh,
            ),
            const SizedBox(height: 12),
            if (controller.error != null)
              _ErrorBanner(message: controller.error!),
            _BankingDashboardGrid(
              controller: controller,
              watchlistCount: controller.watchlistedIds.length,
              coverageCount: controller.coins.length,
              onOpenPortfolio: onOpenPortfolio,
            ),
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40, bottom: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const SizedBox(height: 14),
              _TrendingSectionHeader(onTap: onOpenMarkets),
              const SizedBox(height: 8),
              _TrendingRow(
                coins: trending,
                onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
              ),
              const SizedBox(height: 18),
              _MarketMoveSection(
                title: 'Top Gainers',
                coins: controller.topGainers,
                onSeeAll: onOpenMarkets,
                onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
              ),
              const SizedBox(height: 8),
              _MarketMoveSection(
                title: 'Top Losers',
                coins: controller.topLosers,
                onSeeAll: onOpenMarkets,
                onCoinTap: (coin) => _openCoinDetail(context, controller, coin),
              ),
              const SizedBox(height: 8),
              _TrendingWalletsHomeSection(onSeeAll: onOpenWallets),
            ],
            const SizedBox(height: 22),
            NewsPreviewSection(onSeeAll: onOpenNews),
            const SizedBox(height: 14),
            const _AiInsightBanner(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
