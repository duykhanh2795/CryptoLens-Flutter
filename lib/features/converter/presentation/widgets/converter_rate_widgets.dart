import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/converter/presentation/widgets/converter_coin_picker_sheet.dart';
import 'package:cryptolens_flutter/features/converter/presentation/widgets/converter_theme_helpers.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class ConverterQuickPairs extends StatelessWidget {
  const ConverterQuickPairs({
    required this.coins,
    required this.onSelected,
    super.key,
  });

  final List<Coin> coins;
  final void Function(String fromId, String toId) onSelected;

  @override
  Widget build(BuildContext context) {
    final ids = coins.map((coin) => coin.id).toSet();
    final pairs =
        [
              ('BTC/ETH', 'bitcoin', 'ethereum'),
              ('ETH/SOL', 'ethereum', 'solana'),
              ('BTC/USD', 'bitcoin', 'usd'),
              ('ETH/USD', 'ethereum', 'usd'),
              ('SOL/USD', 'solana', 'usd'),
            ]
            .where(
              (pair) =>
                  (pair.$2 == 'usd' || ids.contains(pair.$2)) &&
                  (pair.$3 == 'usd' || ids.contains(pair.$3)),
            )
            .toList();
    if (pairs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick pairs',
          style: TextStyle(
            color: ConverterColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pairs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final pair = pairs[index];
              return OutlinedButton(
                onPressed: () => onSelected(pair.$2, pair.$3),
                child: Text(pair.$1),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ConverterRateCard extends StatelessWidget {
  const ConverterRateCard({
    required this.fromLabel,
    required this.toLabel,
    required this.directRate,
    required this.inverseRate,
    super.key,
  });

  final String fromLabel;
  final String toLabel;
  final double directRate;
  final double inverseRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConverterColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate',
            style: TextStyle(
              color: ConverterColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ConverterRateRow(
            '1 $fromLabel',
            '${trimConverterValue(directRate)} $toLabel',
          ),
          const Divider(color: ConverterColors.surfaceVariant),
          ConverterRateRow(
            '1 $toLabel',
            '${trimConverterValue(inverseRate)} $fromLabel',
          ),
        ],
      ),
    );
  }
}

class ConverterRateRow extends StatelessWidget {
  const ConverterRateRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: ConverterColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: ConverterColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class ConverterMarketContext extends StatelessWidget {
  const ConverterMarketContext({required this.coins, super.key});

  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    if (coins.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ConverterColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Market context',
              style: TextStyle(
                color: ConverterColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final coin in coins) ConverterMarketContextRow(coin: coin),
        ],
      ),
    );
  }
}

class ConverterMarketContextRow extends StatelessWidget {
  const ConverterMarketContextRow({required this.coin, super.key});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final positive = coin.priceChangePercent24h >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ConverterCoinIcon(coin: coin, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.symbol,
                  style: const TextStyle(
                    color: ConverterColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  coin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ConverterColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(coin.currentPrice),
                style: const TextStyle(
                  color: ConverterColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                formatPercent(coin.priceChangePercent24h),
                style: TextStyle(
                  color: positive ? ConverterColors.green : ConverterColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
