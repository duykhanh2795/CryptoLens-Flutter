import 'package:flutter_test/flutter_test.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_csv_codec.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';

void main() {
  group('PortfolioCsvCodec', () {
    const codec = PortfolioCsvCodec();
    final btc = Coin.snapshot(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      imageUrl: 'btc.png',
      currentPrice: 73000,
    );

    test('round-trips transactions including quoted notes', () {
      final tx = PortfolioTransaction(
        id: 'tx1',
        coin: btc,
        type: PortfolioTransactionType.buy,
        quantity: 0.25,
        price: 70000,
        fee: 2.5,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
        note: 'DCA, "weekly"',
        sourceConnectionId: 'binance_1',
      );

      final csv = codec.encode([tx]);
      final decoded = codec.decode(
        csv,
        coinResolver: (coinId, symbol, name, imageUrl) => btc,
      );

      expect(decoded, hasLength(1));
      expect(decoded.single.id, 'tx1');
      expect(decoded.single.type, PortfolioTransactionType.buy);
      expect(decoded.single.quantity, 0.25);
      expect(decoded.single.note, 'DCA, "weekly"');
      expect(decoded.single.sourceConnectionId, 'binance_1');
    });

    test('filters invalid rows and generates ids when missing', () {
      final csv = [
        'id,coinId,symbol,name,imageUrl,type,quantity,price,fee,timestamp,note,sourceConnectionId',
        ',bitcoin,BTC,Bitcoin,btc.png,sell,1,71000,0,1000,,',
        'bad,bitcoin,BTC,Bitcoin,btc.png,buy,0,71000,0,1000,,',
      ].join('\n');

      final decoded = codec.decode(
        csv,
        coinResolver: (coinId, symbol, name, imageUrl) => btc,
      );

      expect(decoded, hasLength(1));
      expect(decoded.single.id, isNotEmpty);
      expect(decoded.single.type, PortfolioTransactionType.sell);
    });
  });
}
