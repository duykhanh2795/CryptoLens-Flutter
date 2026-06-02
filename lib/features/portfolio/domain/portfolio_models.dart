import 'dart:math' as math;

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';

class PortfolioSummary {
  const PortfolioSummary({
    required this.totalValue,
    required this.invested,
    required this.pnl,
    required this.pnlPercent,
    required this.unrealized,
    required this.realized,
    required this.fees,
    required this.dayChange,
    required this.dayChangePercent,
    required this.assetCount,
    required this.chartValues,
  });

  final double totalValue;
  final double invested;
  final double pnl;
  final double pnlPercent;
  final double unrealized;
  final double realized;
  final double fees;
  final double dayChange;
  final double dayChangePercent;
  final int assetCount;
  final List<double> chartValues;

  factory PortfolioSummary.fromAssets(
    List<PortfolioAsset> assets,
    List<PortfolioTransaction> transactions, {
    List<PortfolioSnapshot> snapshots = const [],
  }) {
    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    final invested = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.costBasis,
    );
    final unrealized = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.unrealizedPnl,
    );
    final realized = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.realizedPnl,
    );
    final fees = transactions.fold<double>(0, (sum, tx) => sum + tx.fee);
    final dayChange = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.coin.priceChange24h * asset.quantity,
    );
    final previousValue = math.max(totalValue - dayChange, 0.01);
    final pnl = unrealized + realized;
    final pnlPercent = invested == 0 ? 0.0 : pnl / invested * 100;
    final chartValues = _chartValuesFromSnapshots(
      snapshots,
      fallbackCurrent: totalValue,
      fallbackPrevious: previousValue,
    );
    return PortfolioSummary(
      totalValue: totalValue,
      invested: invested,
      pnl: pnl,
      pnlPercent: pnlPercent,
      unrealized: unrealized,
      realized: realized,
      fees: fees,
      dayChange: dayChange,
      dayChangePercent: dayChange / previousValue * 100,
      assetCount: assets.length,
      chartValues: chartValues,
    );
  }

  static List<double> _chartValuesFromSnapshots(
    List<PortfolioSnapshot> snapshots, {
    required double fallbackCurrent,
    required double fallbackPrevious,
  }) {
    final ordered = [...snapshots]
      ..sort((a, b) => a.dayStart.compareTo(b.dayStart));
    final values = ordered
        .map((snapshot) => snapshot.totalValue)
        .where((value) => value >= 0)
        .toList();
    if (values.length >= 2) return values;

    if (fallbackCurrent <= 0 && fallbackPrevious <= 0) {
      return const [0, 0];
    }
    return [fallbackPrevious, fallbackCurrent];
  }
}

class PortfolioAsset {
  const PortfolioAsset({
    required this.coin,
    required this.quantity,
    required this.costBasis,
    required this.realizedPnl,
    required this.fees,
  });

  final Coin coin;
  final double quantity;
  final double costBasis;
  final double realizedPnl;
  final double fees;

  double get averagePrice => quantity <= 0 ? 0 : costBasis / quantity;
  double get currentValue => coin.currentPrice * quantity;
  double get unrealizedPnl => currentValue - costBasis;
  double get unrealizedPnlPercent =>
      costBasis == 0 ? 0 : unrealizedPnl / costBasis * 100;
}
