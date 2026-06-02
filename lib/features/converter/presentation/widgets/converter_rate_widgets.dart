part of '../screens/converter_screen.dart';

class _QuickPairs extends StatelessWidget {
  const _QuickPairs({required this.coins, required this.onSelected});

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
            color: _Dark.textSecondary,
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

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.fromLabel,
    required this.toLabel,
    required this.directRate,
    required this.inverseRate,
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
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate',
            style: TextStyle(
              color: _Dark.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _RateRow('1 $fromLabel', '${_trim(directRate)} $toLabel'),
          const Divider(color: _Dark.surfaceVariant),
          _RateRow('1 $toLabel', '${_trim(inverseRate)} $fromLabel'),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: _Dark.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _Dark.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MarketContext extends StatelessWidget {
  const _MarketContext({required this.coins});

  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    if (coins.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _Dark.surface,
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
                color: _Dark.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final coin in coins) _MarketContextRow(coin: coin),
        ],
      ),
    );
  }
}

class _MarketContextRow extends StatelessWidget {
  const _MarketContextRow({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final positive = coin.priceChangePercent24h >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _CoinIcon(coin: coin, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.symbol,
                  style: const TextStyle(
                    color: _Dark.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  coin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _Dark.textSecondary),
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
                  color: _Dark.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                formatPercent(coin.priceChangePercent24h),
                style: TextStyle(
                  color: positive ? _Dark.green : _Dark.red,
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
