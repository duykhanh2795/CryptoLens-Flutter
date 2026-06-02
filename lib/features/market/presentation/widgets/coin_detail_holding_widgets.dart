import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_holding.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_misc_widgets.dart';

class YourHoldingSection extends StatelessWidget {
  const YourHoldingSection({
    required this.holding,
    required this.onOpenPortfolio,
    super.key,
  });

  final CoinHolding holding;
  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    final profit = holding.profitLoss >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoinDetailColors.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Holdings',
                  style: TextStyle(
                    color: CoinDetailColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenPortfolio,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Portfolio',
                      style: TextStyle(
                        color: CoinDetailColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: CoinDetailColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: HoldingMetric(
                  label: 'Value',
                  value: formatCompactUsd(holding.currentValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HoldingMetric(
                  label: 'Quantity',
                  value:
                      '${trimHoldingValue(holding.quantity)} ${holding.coin.symbol}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: HoldingMetric(
                  label: 'Avg Buy',
                  value: formatPrice(holding.averagePrice),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HoldingMetric(
                  label: 'P&L',
                  value:
                      '${holding.profitLoss >= 0 ? '+' : '-'}${formatCompactUsd(holding.profitLoss.abs())} (${holding.profitLossPercent.abs().toStringAsFixed(2)}%)',
                  valueColor: profit
                      ? CoinDetailColors.green
                      : CoinDetailColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HoldingMetric(
            label: 'Portfolio Allocation',
            value: '${holding.allocationPercent.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }
}

class HoldingMetric extends StatelessWidget {
  const HoldingMetric({
    required this.label,
    required this.value,
    this.valueColor = CoinDetailColors.textPrimary,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CoinDetailColors.selected,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CoinDetailColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BuySellBar extends StatelessWidget {
  const BuySellBar({required this.onOpenPortfolio, super.key});

  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          MediaQuery.paddingOf(context).bottom + 10,
        ),
        color: CoinDetailColors.background,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: onOpenPortfolio,
                  style: FilledButton.styleFrom(
                    backgroundColor: CoinDetailColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Track Buy',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: onOpenPortfolio,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CoinDetailColors.red,
                    backgroundColor: CoinDetailColors.panel,
                    side: const BorderSide(color: CoinDetailColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  label: const Text(
                    'Track Sell',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
