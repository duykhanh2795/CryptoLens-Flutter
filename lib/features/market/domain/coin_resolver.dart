import 'package:cryptolens_flutter/features/market/domain/coin.dart';

typedef CoinSnapshotResolver =
    Coin Function(String coinId, String symbol, String name, String imageUrl);

class CoinResolver {
  const CoinResolver(this.coins);

  final List<Coin> coins;

  Coin? findById(String coinId) {
    for (final coin in coins) {
      if (coin.id == coinId) return coin;
    }
    return null;
  }

  Coin? findBySymbol(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    for (final coin in coins) {
      if (coin.symbol.toUpperCase() == normalized) return coin;
    }
    return null;
  }

  Coin resolveSnapshot({
    required String coinId,
    required String symbol,
    required String name,
    required String imageUrl,
    double currentPrice = 0,
  }) {
    return findById(coinId) ??
        findBySymbol(symbol) ??
        Coin.snapshot(
          id: coinId,
          symbol: symbol,
          name: name,
          imageUrl: imageUrl,
          currentPrice: currentPrice,
        );
  }

  CoinSnapshotResolver get snapshotResolver {
    return (coinId, symbol, name, imageUrl) => resolveSnapshot(
      coinId: coinId,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
    );
  }
}
