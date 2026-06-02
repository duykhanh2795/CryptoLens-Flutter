import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'percent_chip.dart';

class CoinRow extends StatelessWidget {
  const CoinRow({
    required this.coin,
    required this.isWatchlisted,
    required this.onTap,
    required this.onToggleWatchlist,
    super.key,
  });

  final Coin coin;
  final bool isWatchlisted;
  final VoidCallback onTap;
  final VoidCallback onToggleWatchlist;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 34,
                height: 34,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.currency_bitcoin, size: 18),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#${coin.rank} ${coin.symbol}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                PercentChip(coin.priceChangePercent24h),
              ],
            ),
            IconButton(
              tooltip: isWatchlisted
                  ? 'Remove from Watchlist'
                  : 'Add to Watchlist',
              onPressed: onToggleWatchlist,
              icon: Icon(
                isWatchlisted ? Icons.star_rounded : Icons.star_border_rounded,
                color: isWatchlisted
                    ? AppColors.accent
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketCoinRow extends StatelessWidget {
  const MarketCoinRow({required this.coin, required this.onTap, super.key});

  final Coin coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.currency_bitcoin, size: 22),
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
                      height: 1.05,
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
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vol ${formatCompactUsd(coin.volume24h).replaceFirst(r'$', '')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(
                formatPrice(coin.currentPrice),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _MarketChangePill(value: coin.priceChangePercent24h),
          ],
        ),
      ),
    );
  }
}

class _MarketChangePill extends StatelessWidget {
  const _MarketChangePill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    return SizedBox(
      width: 80,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: positive ? AppColors.greenSurface : AppColors.redSurface,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                positive
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: positive ? AppColors.green : AppColors.red,
                size: 16,
              ),
              Flexible(
                child: Text(
                  formatPercent(value).replaceFirst('+', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: positive ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
