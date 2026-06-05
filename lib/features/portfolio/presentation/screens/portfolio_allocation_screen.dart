import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_models.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_allocation_widgets.dart';

class PortfolioAllocationScreen extends StatefulWidget {
  const PortfolioAllocationScreen({required this.assets, super.key});

  final List<PortfolioAsset> assets;

  @override
  State<PortfolioAllocationScreen> createState() =>
      _PortfolioAllocationScreenState();
}

class _PortfolioAllocationScreenState extends State<PortfolioAllocationScreen> {
  String _selectedRange = '24H';

  @override
  Widget build(BuildContext context) {
    final assets = [...widget.assets]
      ..removeWhere((asset) => asset.currentValue <= 0 && asset.quantity <= 0)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
    final displayAssets = assets.take(6).toList();
    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    final totalPnl = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.unrealizedPnl + asset.realizedPnl,
    );
    final totalCost = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.costBasis,
    );
    final totalPnlPercent = totalCost <= 0 ? 0.0 : totalPnl / totalCost * 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AllocationScreenHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              const AllocationPortfolioChip(),
              const SizedBox(height: 18),
              AllocationHero(
                assets: displayAssets,
                totalValue: totalValue,
                totalPnl: totalPnl,
                totalPnlPercent: totalPnlPercent,
              ),
              AllocationRangeSelector(
                selectedRange: _selectedRange,
                onRangeSelected: (range) =>
                    setState(() => _selectedRange = range),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: AllocationAssetsPanel(
                  assets: displayAssets,
                  totalValue: totalValue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
