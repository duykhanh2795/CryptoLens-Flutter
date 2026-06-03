import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class ConverterQuickPairRepository {
  const ConverterQuickPairRepository();

  List<ConverterQuickPair> availablePairs(List<Coin> coins) {
    final ids = coins.map((coin) => coin.id).toSet();
    return _seedPairs
        .where(
          (pair) =>
              (pair.fromId == 'usd' || ids.contains(pair.fromId)) &&
              (pair.toId == 'usd' || ids.contains(pair.toId)),
        )
        .toList();
  }
}

class ConverterQuickPair {
  const ConverterQuickPair({
    required this.label,
    required this.fromId,
    required this.toId,
  });

  final String label;
  final String fromId;
  final String toId;
}

const _seedPairs = [
  ConverterQuickPair(label: 'BTC/ETH', fromId: 'bitcoin', toId: 'ethereum'),
  ConverterQuickPair(label: 'ETH/SOL', fromId: 'ethereum', toId: 'solana'),
  ConverterQuickPair(label: 'BTC/USD', fromId: 'bitcoin', toId: 'usd'),
  ConverterQuickPair(label: 'ETH/USD', fromId: 'ethereum', toId: 'usd'),
  ConverterQuickPair(label: 'SOL/USD', fromId: 'solana', toId: 'usd'),
];
