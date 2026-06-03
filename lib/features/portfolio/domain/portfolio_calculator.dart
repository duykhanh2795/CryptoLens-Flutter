import 'dart:math' as math;

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_resolver.dart';
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
    final coinResolver = CoinResolver(liveCoins);
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
        assets.add(
          PortfolioAsset(
            coin: coinResolver.findById(entry.key) ?? txs.last.coin,
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
}
