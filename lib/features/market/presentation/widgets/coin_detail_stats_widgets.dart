part of '../screens/coin_detail_screen.dart';

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.intervals,
    required this.selected,
    required this.onSelected,
    this.compact = false,
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
                        ? _DetailColors.selected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: selected == entry.key
                          ? _DetailColors.textPrimary
                          : _DetailColors.textTertiary,
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

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: _QuickStat(
              label: '24h High',
              value: formatPrice(coin.high24h),
              color: _DetailColors.green,
            ),
          ),
          const SizedBox(
            height: 38,
            child: VerticalDivider(color: _DetailColors.divider),
          ),
          Expanded(
            child: _QuickStat(
              label: '24h Low',
              value: formatPrice(coin.low24h),
              color: _DetailColors.red,
            ),
          ),
          const SizedBox(
            height: 38,
            child: VerticalDivider(color: _DetailColors.divider),
          ),
          Expanded(
            child: _QuickStat(
              label: 'Volume',
              value: formatCompactUsd(coin.volume24h).replaceFirst(r'$', ''),
              color: _DetailColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.coin});

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
          bottom: BorderSide(color: _DetailColors.divider, width: 0.8),
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
                      color: _DetailColors.textTertiary,
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
                          ? _DetailColors.green.withValues(alpha: 0.78)
                          : _DetailColors.red.withValues(alpha: 0.78),
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
