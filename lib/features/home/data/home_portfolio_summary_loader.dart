import 'dart:math' as math;

import 'package:cryptolens_flutter/features/home/domain/home_portfolio_summary.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

class HomePortfolioSummaryLoader {
  const HomePortfolioSummaryLoader({PortfolioStore? store})
    : _store = store ?? const PortfolioStore();

  final PortfolioStore _store;

  Future<HomePortfolioSummary> load(MarketController controller) async {
    final transactions = await _store.load(
      coinResolver: (coinId, symbol, name, imageUrl) {
        for (final coin in controller.coins) {
          if (coin.id == coinId) return coin;
        }
        return Coin(
          id: coinId,
          symbol: symbol,
          name: name,
          imageUrl: imageUrl,
          currentPrice: 0,
          priceChangePercent24h: 0,
          priceChange24h: 0,
          marketCap: 0,
          volume24h: 0,
          high24h: 0,
          low24h: 0,
          circulatingSupply: 0,
          rank: 0,
          lastUpdated: DateTime.now(),
        );
      },
    );
    if (transactions.isEmpty) return HomePortfolioSummary.empty();

    final byCoin = <String, List<PortfolioTransaction>>{};
    for (final tx in transactions) {
      byCoin.putIfAbsent(tx.coin.id, () => []).add(tx);
    }

    var totalValue = 0.0;
    var invested = 0.0;
    var realized = 0.0;
    var dayChange = 0.0;
    var assetCount = 0;

    for (final entry in byCoin.entries) {
      final txs = [...entry.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      var quantity = 0.0;
      var costBasis = 0.0;
      var coinRealized = 0.0;
      for (final tx in txs) {
        if (tx.type == PortfolioTransactionType.buy) {
          quantity += tx.quantity;
          costBasis += tx.quantity * tx.price + tx.fee;
        } else {
          final average = quantity <= 0 ? 0.0 : costBasis / quantity;
          final sold = math.min(quantity, tx.quantity);
          coinRealized += sold * (tx.price - average) - tx.fee;
          quantity -= sold;
          costBasis -= average * sold;
        }
      }
      if (quantity <= 0.00000001) {
        realized += coinRealized;
        continue;
      }
      final coin = _liveCoin(controller, entry.key) ?? txs.last.coin;
      final value = quantity * coin.currentPrice;
      totalValue += value;
      invested += costBasis;
      realized += coinRealized;
      dayChange += quantity * coin.priceChange24h;
      assetCount++;
    }

    final previousValue = math.max(totalValue - dayChange, 0.01);
    return HomePortfolioSummary(
      totalValue: totalValue,
      dayChange: dayChange,
      dayChangePercent: dayChange / previousValue * 100,
      totalPnl: totalValue - invested + realized,
      assetCount: assetCount,
      transactionCount: transactions.length,
    );
  }

  static Coin? _liveCoin(MarketController controller, String coinId) {
    for (final coin in controller.coins) {
      if (coin.id == coinId) return coin;
    }
    return null;
  }
}
