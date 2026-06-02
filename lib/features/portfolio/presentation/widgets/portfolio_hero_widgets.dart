part of '../screens/portfolio_screen.dart';

class _PortfolioHero extends StatefulWidget {
  const _PortfolioHero({required this.summary});

  final _PortfolioSummary summary;

  @override
  State<_PortfolioHero> createState() => _PortfolioHeroState();
}

class _PortfolioHeroState extends State<_PortfolioHero> {
  String _range = '24H';

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final isProfit = summary.pnl >= 0;
    final isDayUp = summary.dayChange >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Text(
              'USD',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Allocation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          formatPrice(summary.totalValue),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _signedMoney(summary.pnl),
              style: TextStyle(
                color: isProfit ? AppColors.green : AppColors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isProfit ? AppColors.greenSurface : AppColors.redSurface,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                formatPercent(summary.pnlPercent),
                style: TextStyle(
                  color: isProfit ? AppColors.green : AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 228,
          width: double.infinity,
          child: CustomPaint(
            painter: _PortfolioChartPainter(
              values: summary.chartValues,
              color: isDayUp ? AppColors.green : AppColors.red,
            ),
          ),
        ),
        _RangeSelector(
          selected: _range,
          onChanged: (value) => setState(() => _range = value),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Metric(label: 'Invested', value: formatPrice(summary.invested)),
            _Metric(
              label: 'Unrealized',
              value: _signedMoney(summary.unrealized),
              valueColor: summary.unrealized >= 0
                  ? AppColors.green
                  : AppColors.red,
              align: TextAlign.center,
            ),
            _Metric(
              label: 'Realized',
              value: _signedMoney(summary.realized),
              valueColor: summary.realized >= 0
                  ? AppColors.green
                  : AppColors.red,
              align: TextAlign.end,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Metric(label: 'Fees', value: formatPrice(summary.fees)),
            _Metric(
              label: '24H',
              value:
                  '${_signedMoney(summary.dayChange)} / ${formatPercent(summary.dayChangePercent)}',
              valueColor: isDayUp ? AppColors.green : AppColors.red,
              align: TextAlign.center,
            ),
            _Metric(
              label: 'Assets',
              value: '${summary.assetCount}',
              align: TextAlign.end,
            ),
          ],
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const ranges = ['24H', '1W', '1M', '1Y', 'ALL'];
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final range in ranges)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(range),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == range
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      color: selected == range
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.align = TextAlign.start,
  });

  final String label;
  final String value;
  final Color valueColor;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: switch (align) {
          TextAlign.end => CrossAxisAlignment.end,
          TextAlign.center => CrossAxisAlignment.center,
          _ => CrossAxisAlignment.start,
        },
        children: [
          Text(
            label,
            textAlign: align,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: align,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
