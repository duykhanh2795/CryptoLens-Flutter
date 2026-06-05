import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_models.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_format_helpers.dart';

class AllocationSummaryCard extends StatelessWidget {
  const AllocationSummaryCard({
    required this.assets,
    required this.total,
    super.key,
  });

  final List<PortfolioAsset> assets;
  final double total;

  @override
  Widget build(BuildContext context) {
    final largest = assets.isEmpty ? null : assets.first;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(188),
                  painter: AllocationDonutPainter(assets: assets),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Value',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatPrice(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (largest != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${largest.coin.symbol} leads',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SummaryMetric(label: 'Assets', value: '${assets.length}'),
              _SummaryMetric(
                label: 'Largest',
                value: largest == null ? '-' : largest.coin.symbol,
                align: TextAlign.center,
              ),
              _SummaryMetric(
                label: 'Top Weight',
                value: largest == null || total <= 0
                    ? '0.0%'
                    : '${(largest.currentValue / total * 100).toStringAsFixed(1)}%',
                align: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AllocationAssetRow extends StatelessWidget {
  const AllocationAssetRow({
    required this.asset,
    required this.color,
    required this.percent,
    super.key,
  });

  final PortfolioAsset asset;
  final Color color;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final isProfit = asset.unrealizedPnl >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              ClipOval(
                child: Image.network(
                  asset.coin.imageUrl,
                  width: 38,
                  height: 38,
                  errorBuilder: (_, _, _) => const CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.currency_bitcoin, size: 19),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.coin.symbol,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${trimPortfolioValue(asset.quantity)} ${asset.coin.symbol}',
                      style: portfolioAssetMetaStyle(AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    formatPrice(asset.currentValue),
                    style: portfolioAssetMetaStyle(AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (percent / 100).clamp(0, 1),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InlineStat(label: 'Avg', value: formatPrice(asset.averagePrice)),
              _InlineStat(
                label: 'P/L',
                value: signedPortfolioMoney(asset.unrealizedPnl),
                valueColor: isProfit ? AppColors.green : AppColors.red,
                align: TextAlign.center,
              ),
              _InlineStat(
                label: '24H',
                value: formatPercent(asset.coin.priceChangePercent24h),
                valueColor: asset.coin.priceChangePercent24h >= 0
                    ? AppColors.green
                    : AppColors.red,
                align: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AllocationDonutPainter extends CustomPainter {
  const AllocationDonutPainter({required this.assets});

  final List<PortfolioAsset> assets;

  @override
  void paint(Canvas canvas, Size size) {
    final total = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.13;
    final basePaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      basePaint,
    );
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (var index = 0; index < assets.length; index++) {
      final sweep = assets[index].currentValue / total * math.pi * 2;
      final paint = Paint()
        ..color = allocationColor(index)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        math.max(0, sweep - 0.035),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant AllocationDonutPainter oldDelegate) {
    return oldDelegate.assets != assets;
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.align = TextAlign.start,
  });

  final String label;
  final String value;
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
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
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
            style: portfolioAssetMetaStyle(AppColors.textTertiary),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Color allocationColor(int index) {
  const colors = [
    AppColors.accent,
    AppColors.green,
    AppColors.red,
    Color(0xFF7C6FE8),
    Color(0xFF3DA5FF),
    Color(0xFFFFA726),
    Color(0xFF26C6DA),
    Color(0xFFAB47BC),
  ];
  return colors[index % colors.length];
}
