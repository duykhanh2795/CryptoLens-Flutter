import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/widgets/coin_row.dart';
import 'package:cryptolens_flutter/core/widgets/empty_state.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/markets_widgets.dart';
import 'coin_detail_screen.dart';
import '../market_controller.dart';

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
          MarketsHeader(controller: controller),
          const SizedBox(height: 12),
          MarketSearchField(controller: controller),
          const SizedBox(height: 14),
          MarketTabs(controller: controller),
          const SizedBox(height: 10),
          const MarketTableHeader(),
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
