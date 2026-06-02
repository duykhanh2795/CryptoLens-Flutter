import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class CoinHolding {
  const CoinHolding({
    required this.coin,
    required this.quantity,
    required this.costBasis,
    required this.realizedPnl,
    required this.totalPortfolioValue,
  });

  final Coin coin;
  final double quantity;
  final double costBasis;
  final double realizedPnl;
  final double totalPortfolioValue;

  double get averagePrice => quantity <= 0 ? 0 : costBasis / quantity;
  double get currentValue => quantity * coin.currentPrice;
  double get unrealizedPnl => currentValue - costBasis;
  double get profitLoss => unrealizedPnl + realizedPnl;
  double get profitLossPercent =>
      costBasis <= 0 ? 0 : profitLoss / costBasis * 100;
  double get allocationPercent =>
      totalPortfolioValue <= 0 ? 0 : currentValue / totalPortfolioValue * 100;

  CoinHolding withPrice(double price) {
    return CoinHolding(
      coin: Coin(
        id: coin.id,
        symbol: coin.symbol,
        name: coin.name,
        imageUrl: coin.imageUrl,
        currentPrice: price,
        priceChangePercent24h: coin.priceChangePercent24h,
        priceChange24h: coin.priceChange24h,
        marketCap: coin.marketCap,
        volume24h: coin.volume24h,
        high24h: coin.high24h,
        low24h: coin.low24h,
        circulatingSupply: coin.circulatingSupply,
        rank: coin.rank,
        lastUpdated: coin.lastUpdated,
      ),
      quantity: quantity,
      costBasis: costBasis,
      realizedPnl: realizedPnl,
      totalPortfolioValue: totalPortfolioValue,
    );
  }
}
