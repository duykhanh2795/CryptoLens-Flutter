part of '../screens/coin_detail_screen.dart';

class _YourHoldingSection extends StatelessWidget {
  const _YourHoldingSection({
    required this.holding,
    required this.onOpenPortfolio,
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
        color: _DetailColors.panel,
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
                    color: _DetailColors.textPrimary,
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
                        color: _DetailColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _DetailColors.textSecondary,
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
                child: _HoldingMetric(
                  label: 'Value',
                  value: formatCompactUsd(holding.currentValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoldingMetric(
                  label: 'Quantity',
                  value:
                      '${_trimHolding(holding.quantity)} ${holding.coin.symbol}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HoldingMetric(
                  label: 'Avg Buy',
                  value: formatPrice(holding.averagePrice),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoldingMetric(
                  label: 'P&L',
                  value:
                      '${holding.profitLoss >= 0 ? '+' : '-'}${formatCompactUsd(holding.profitLoss.abs())} (${holding.profitLossPercent.abs().toStringAsFixed(2)}%)',
                  valueColor: profit ? _DetailColors.green : _DetailColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HoldingMetric(
            label: 'Portfolio Allocation',
            value: '${holding.allocationPercent.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }
}

class _HoldingMetric extends StatelessWidget {
  const _HoldingMetric({
    required this.label,
    required this.value,
    this.valueColor = _DetailColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _DetailColors.selected,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _DetailColors.textTertiary,
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

class _BuySellBar extends StatelessWidget {
  const _BuySellBar({required this.onOpenPortfolio});

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
        color: _DetailColors.background,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: onOpenPortfolio,
                  style: FilledButton.styleFrom(
                    backgroundColor: _DetailColors.green,
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
                    foregroundColor: _DetailColors.red,
                    backgroundColor: _DetailColors.panel,
                    side: const BorderSide(color: _DetailColors.divider),
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

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _DetailColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
