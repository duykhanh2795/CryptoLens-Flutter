import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';

class TopChrome extends StatelessWidget {
  const TopChrome({
    required this.coin,
    required this.controller,
    required this.onRefresh,
    required this.onAlert,
    required this.onWatchlistToggle,
    super.key,
  });

  final Coin coin;
  final MarketController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onAlert;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final watchlisted = controller.watchlistedIds.contains(coin.id);
    return Positioned(
      left: 4,
      right: 4,
      top: 0,
      child: Container(
        height: 44,
        color: CoinDetailColors.background,
        child: Row(
          children: [
            TopIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            TopIconButton(icon: Icons.refresh_rounded, onTap: onRefresh),
            TopIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: onAlert,
            ),
            TopIconButton(
              icon: watchlisted
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: watchlisted
                  ? CoinDetailColors.textPrimary
                  : CoinDetailColors.textSecondary,
              onTap: onWatchlistToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class TopIconButton extends StatelessWidget {
  const TopIconButton({
    required this.icon,
    required this.onTap,
    this.color = CoinDetailColors.textSecondary,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
