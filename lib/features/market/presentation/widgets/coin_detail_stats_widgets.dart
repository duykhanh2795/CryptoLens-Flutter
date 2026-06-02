import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';

class IntervalSelector extends StatelessWidget {
  const IntervalSelector({
    required this.intervals,
    required this.selected,
    required this.onSelected,
    this.compact = false,
    super.key,
  });

  final Map<String, String> intervals;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: compact ? 0 : 9),
      child: Row(
        children: [
          for (final entry in intervals.entries)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(entry.key),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  height: compact ? 30 : 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == entry.key
                        ? CoinDetailColors.selected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: selected == entry.key
                          ? CoinDetailColors.textPrimary
                          : CoinDetailColors.textTertiary,
                      fontSize: 10,
                      fontWeight: selected == entry.key
                          ? FontWeight.w500
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({required this.coin, super.key});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: QuickStat(
              label: '24h High',
              value: formatPrice(coin.high24h),
              color: CoinDetailColors.green,
            ),
          ),
          const SizedBox(
            height: 38,
            child: VerticalDivider(color: CoinDetailColors.divider),
          ),
          Expanded(
            child: QuickStat(
              label: '24h Low',
              value: formatPrice(coin.low24h),
              color: CoinDetailColors.red,
            ),
          ),
          const SizedBox(
            height: 38,
            child: VerticalDivider(color: CoinDetailColors.divider),
          ),
          Expanded(
            child: QuickStat(
              label: 'Volume',
              value: formatCompactUsd(coin.volume24h).replaceFirst(r'$', ''),
              color: CoinDetailColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class PerformanceRow extends StatelessWidget {
  const PerformanceRow({required this.coin, super.key});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final today = coin.priceChangePercent24h;
    final items = [
      ('Today', today),
      ('7 days', today * 2.4),
      ('30 days', today * 4.8),
      ('90 days', today * -3.2),
      ('180 days', today * 8.4),
      ('1 year', today * -12.0),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 9, 2, 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CoinDetailColors.divider, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CoinDetailColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPercent(item.$2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.$2 >= 0
                          ? CoinDetailColors.green.withValues(alpha: 0.78)
                          : CoinDetailColors.red.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class QuickStat extends StatelessWidget {
  const QuickStat({
    required this.label,
    required this.value,
    required this.color,
    super.key,
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
            color: CoinDetailColors.textSecondary,
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
