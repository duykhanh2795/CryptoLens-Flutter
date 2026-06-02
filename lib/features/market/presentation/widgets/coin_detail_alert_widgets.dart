import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/alerts/domain/alert_rule.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';

class AlertTypePickerSheet extends StatelessWidget {
  const AlertTypePickerSheet({
    required this.coin,
    required this.onSelected,
    super.key,
  });

  final Coin coin;
  final ValueChanged<AlertMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: CoinDetailColors.textTertiary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Create ${coin.symbol} alert',
              style: const TextStyle(
                color: CoinDetailColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            AlertTypeSheetRow(
              title: 'Price Limit',
              subtitle: 'Notify when price crosses your target',
              icon: Icons.attach_money_rounded,
              onTap: () => onSelected(AlertMetric.price),
            ),
            AlertTypeSheetRow(
              title: 'Volume',
              subtitle: 'Track unusual 24h trading volume changes',
              icon: Icons.bar_chart_rounded,
              onTap: () => onSelected(AlertMetric.volume),
            ),
            AlertTypeSheetRow(
              title: 'Market Cap',
              subtitle: 'Watch valuation moves by number or percent',
              icon: Icons.pie_chart_rounded,
              onTap: () => onSelected(AlertMetric.marketCap),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertTypeSheetRow extends StatelessWidget {
  const AlertTypeSheetRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: CoinDetailColors.selected,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: CoinDetailColors.textPrimary.withValues(
                  alpha: 0.10,
                ),
                child: Icon(
                  icon,
                  color: CoinDetailColors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: CoinDetailColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CoinDetailColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CoinDetailColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
