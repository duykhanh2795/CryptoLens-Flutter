import 'dart:math' as math;

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_models.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

class PortfolioCalculator {
  const PortfolioCalculator._();

  static List<PortfolioAsset> buildAssets({
    required List<PortfolioTransaction> transactions,
    required List<Coin> liveCoins,
  }) {
    final byCoin = <String, List<PortfolioTransaction>>{};
    for (final tx in transactions) {
      byCoin.putIfAbsent(tx.coin.id, () => []).add(tx);
    }

    final assets = <PortfolioAsset>[];
    for (final entry in byCoin.entries) {
      final txs = [...entry.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      var quantity = 0.0;
      var costBasis = 0.0;
      var realized = 0.0;
      var fees = 0.0;

      for (final tx in txs) {
        fees += tx.fee;
        if (tx.type == PortfolioTransactionType.buy) {
          quantity += tx.quantity;
          costBasis += tx.quantity * tx.price + tx.fee;
        } else {
          final avgCost = quantity <= 0 ? 0.0 : costBasis / quantity;
          final sellQuantity = math.min(quantity, tx.quantity);
          realized += sellQuantity * (tx.price - avgCost) - tx.fee;
          quantity -= sellQuantity;
          costBasis -= avgCost * sellQuantity;
        }
      }

      if (quantity > 0.00000001) {
        final liveCoin = _findLiveCoin(entry.key, liveCoins);
        assets.add(
          PortfolioAsset(
            coin: liveCoin ?? txs.last.coin,
            quantity: quantity,
            costBasis: costBasis,
            realizedPnl: realized,
            fees: fees,
          ),
        );
      }
    }

    assets.sort((a, b) => b.currentValue.compareTo(a.currentValue));
    return assets;
  }

  static Coin? _findLiveCoin(String coinId, List<Coin> coins) {
    for (final coin in coins) {
      if (coin.id == coinId) return coin;
    }
    return null;
  }
}
