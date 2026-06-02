import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_format_helpers.dart';
import 'package:cryptolens_flutter/features/home/presentation/widgets/home_misc_widgets.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class TrendingSectionHeader extends StatelessWidget {
  const TrendingSectionHeader({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Pulse',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Live prices and momentum',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('See All'),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class TrendingRow extends StatelessWidget {
  const TrendingRow({required this.coins, required this.onCoinTap, super.key});

  final List<Coin> coins;
  final ValueChanged<Coin> onCoinTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 134,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: coins.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final coin = coins[index];
          return TrendingCoinCard(coin: coin, onTap: () => onCoinTap(coin));
        },
      ),
    );
  }
}

class TrendingCoinCard extends StatelessWidget {
  const TrendingCoinCard({required this.coin, required this.onTap, super.key});

  final Coin coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = coin.isPositive ? AppColors.green : AppColors.red;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 146,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151517),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${coin.name}  /  ${coin.symbol}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatPrice(coin.currentPrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  formatPercent(coin.priceChangePercent24h),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '|',
                  style: TextStyle(
                    color: AppColors.textTertiary.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatSignedPriceDelta(coin.priceChange24h),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 42,
              width: double.infinity,
              child: CustomPaint(
                painter: SparklinePainter(
                  values: sparklineValues(coin),
                  color: changeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketMoveSection extends StatelessWidget {
  const MarketMoveSection({
    required this.title,
    required this.coins,
    required this.onSeeAll,
    required this.onCoinTap,
    super.key,
  });

  final String title;
  final List<Coin> coins;
  final VoidCallback onSeeAll;
  final ValueChanged<Coin> onCoinTap;

  @override
  Widget build(BuildContext context) {
    if (coins.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('More'),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        for (final coin in coins)
          MarketMoveRow(coin: coin, onTap: () => onCoinTap(coin)),
      ],
    );
  }
}

class MarketMoveRow extends StatelessWidget {
  const MarketMoveRow({required this.coin, required this.onTap, super.key});

  final Coin coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = coin.isPositive ? AppColors.green : AppColors.red;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.currency_bitcoin_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coin.symbol,
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
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPercent(coin.priceChangePercent24h),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatPrice(coin.currentPrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
