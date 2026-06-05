import 'package:flutter_test/flutter_test.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_resolver.dart';

void main() {
  group('CoinResolver', () {
    final btc = Coin.snapshot(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      imageUrl: 'btc.png',
      currentPrice: 73000,
    );

    test('finds coins by id or symbol', () {
      final resolver = CoinResolver([btc]);

      expect(resolver.findById('bitcoin'), btc);
      expect(resolver.findBySymbol('btc'), btc);
      expect(resolver.findBySymbol('ETH'), isNull);
    });

    test('falls back to snapshot when live coin is missing', () {
      final resolver = CoinResolver(const []);
      final fallback = resolver.resolveSnapshot(
        coinId: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        imageUrl: 'eth.png',
        currentPrice: 3500,
      );

      expect(fallback.id, 'ethereum');
      expect(fallback.symbol, 'ETH');
      expect(fallback.currentPrice, 3500);
      expect(fallback.marketCap, 0);
    });
  });
}
