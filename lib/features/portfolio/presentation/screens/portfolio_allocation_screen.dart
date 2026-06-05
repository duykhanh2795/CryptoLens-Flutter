import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_models.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_allocation_widgets.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_shared_widgets.dart';

class PortfolioAllocationScreen extends StatelessWidget {
  const PortfolioAllocationScreen({required this.assets, super.key});

  final List<PortfolioAsset> assets;

  @override
  Widget build(BuildContext context) {
    final total = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    final sorted = [...assets]
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Allocation'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: assets.isEmpty
          ? const PortfolioEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No allocation yet',
              message: 'Add assets to see portfolio distribution.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                AllocationSummaryCard(assets: sorted, total: total),
                const SizedBox(height: 14),
                const Text(
                  'Assets',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < sorted.length; index++)
                  AllocationAssetRow(
                    asset: sorted[index],
                    color: allocationColor(index),
                    percent: total <= 0
                        ? 0
                        : sorted[index].currentValue / total * 100,
                  ),
              ],
            ),
    );
  }
}
