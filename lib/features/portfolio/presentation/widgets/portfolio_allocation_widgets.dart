import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_models.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_format_helpers.dart';

class AllocationScreenHeader extends StatelessWidget {
  const AllocationScreenHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              iconSize: 25,
            ),
          ),
          const Text(
            'Portfolio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AllocationPortfolioChip extends StatelessWidget {
  const AllocationPortfolioChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Portfolio',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
            size: 17,
          ),
        ],
      ),
    );
  }
}

class AllocationHero extends StatelessWidget {
  const AllocationHero({
    required this.assets,
    required this.totalValue,
    required this.totalPnl,
    required this.totalPnlPercent,
    super.key,
  });

  final List<PortfolioAsset> assets;
  final double totalValue;
  final double totalPnl;
  final double totalPnlPercent;

  @override
  Widget build(BuildContext context) {
    final isProfit = totalPnl >= 0;
    return SizedBox(
      height: 326,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(292),
            painter: AllocationDonutPainter(assets: assets),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Allocation',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatPrice(totalValue),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  height: 1.12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    signedPortfolioMoney(totalPnl),
                    style: TextStyle(
                      color: isProfit ? AppColors.green : AppColors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatPercent(totalPnlPercent),
                    style: TextStyle(
                      color: isProfit ? AppColors.green : AppColors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AllocationRangeSelector extends StatelessWidget {
  const AllocationRangeSelector({
    required this.selectedRange,
    required this.onRangeSelected,
    super.key,
  });

  final String selectedRange;
  final ValueChanged<String> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    const ranges = ['24H', '1W', '1M', '3M', '1Y', 'ALL'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 46),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final range in ranges)
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onRangeSelected(range),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      range,
                      style: TextStyle(
                        color: selectedRange == range
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        fontSize: 13,
                        fontWeight: selectedRange == range
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 2,
                      color: selectedRange == range
                          ? AppColors.textPrimary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AllocationAssetsPanel extends StatelessWidget {
  const AllocationAssetsPanel({
    required this.assets,
    required this.totalValue,
    super.key,
  });

  final List<PortfolioAsset> assets;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.36),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Assets',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Text(
                  'By value',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (assets.isEmpty)
            const EmptyAllocationState()
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return AllocationAssetRow(
                    asset: asset,
                    percent: totalValue <= 0
                        ? 0
                        : asset.currentValue / totalValue * 100,
                    color: allocationColor(index),
                  );
                },
                separatorBuilder: (_, _) => Divider(
                  color: AppColors.divider.withValues(alpha: 0.36),
                  thickness: 0.6,
                  height: 1,
                ),
                itemCount: assets.length,
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyAllocationState extends StatelessWidget {
  const EmptyAllocationState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            color: AppColors.textTertiary,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No allocation yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add assets to see portfolio distribution.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
    final shortest = math.min(size.width, size.height);
    final strokeWidth = shortest * 0.082;
    final chartPadding = strokeWidth / 2 + 3;
    final arcSize = shortest - chartPadding * 2;
    final rect = Rect.fromLTWH(
      (size.width - arcSize) / 2,
      (size.height - arcSize) / 2,
      arcSize,
      arcSize,
    );

    if (total <= 0) {
      final paint = Paint()
        ..color = AppColors.surfaceVariant.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    var startAngle = -92 * math.pi / 180;
    for (var index = 0; index < assets.length; index++) {
      final rawSweep = assets[index].currentValue / total * math.pi * 2;
      final gap = 3.5 * math.pi / 180;
      final minSweep = rawSweep > 0 ? 1.5 * math.pi / 180 : 0.0;
      final sweep = math.max(rawSweep - gap, minSweep);
      final paint = Paint()
        ..color = allocationColor(index)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += rawSweep;
    }
  }

  @override
  bool shouldRepaint(covariant AllocationDonutPainter oldDelegate) {
    return oldDelegate.assets != assets;
  }
}

class AllocationAssetRow extends StatelessWidget {
  const AllocationAssetRow({
    required this.asset,
    required this.percent,
    required this.color,
    super.key,
  });

  final PortfolioAsset asset;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          ClipOval(
            child: Image.network(
              asset.coin.imageUrl,
              width: 30,
              height: 30,
              errorBuilder: (_, _, _) => const CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(Icons.currency_bitcoin, size: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.coin.symbol.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  asset.coin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
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
                '${percent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatPrice(asset.currentValue),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatPercent(asset.unrealizedPnlPercent),
                    style: TextStyle(
                      color: asset.unrealizedPnlPercent >= 0
                          ? AppColors.green
                          : AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color allocationColor(int index) {
  const colors = [
    Color(0xFF20C989),
    Color(0xFF7A3DFF),
    Color(0xFFFF5C5C),
    Color(0xFF28C7C9),
    Color(0xFF8D9BB0),
    Color(0xFFFFC74D),
  ];
  return colors[index % colors.length];
}
