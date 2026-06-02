import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amount = TextEditingController(text: '1');
  Coin? _from;
  Coin? _to;
  bool _fromUsd = true;
  bool _toUsd = false;

  @override
  void initState() {
    super.initState();
    final coins = widget.controller.coins;
    _from = coins.isNotEmpty ? coins.first : null;
    _to = coins.length > 1 ? coins[1] : _from;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = widget.controller.coins.take(80).toList();
    final amount = double.tryParse(_amount.text) ?? 0;
    final double fromUsdValue = _fromUsd
        ? amount
        : amount * (_from?.currentPrice ?? 0);
    final double result = _toUsd
        ? fromUsdValue
        : (_to == null || _to!.currentPrice <= 0
              ? 0.0
              : fromUsdValue / _to!.currentPrice);

    return Scaffold(
      backgroundColor: _Dark.background,
      appBar: AppBar(
        title: const Text('Converter'),
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Convert', style: _Dark.hero),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _AssetPicker(
            title: 'From',
            isUsd: _fromUsd,
            coin: _from,
            onUsdChanged: (value) => setState(() => _fromUsd = value),
            onCoinTap: () => _showCoinPicker(
              title: 'Select source',
              selected: _from,
              onSelected: (coin) => setState(() => _from = coin),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: IconButton(
              onPressed: () => setState(() {
                final usd = _fromUsd;
                final coin = _from;
                _fromUsd = _toUsd;
                _from = _to;
                _toUsd = usd;
                _to = coin;
              }),
              icon: const Icon(
                Icons.swap_vert_rounded,
                color: _Dark.yellow,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AssetPicker(
            title: 'To',
            isUsd: _toUsd,
            coin: _to,
            onUsdChanged: (value) => setState(() => _toUsd = value),
            onCoinTap: () => _showCoinPicker(
              title: 'Select target',
              selected: _to,
              onSelected: (coin) => setState(() => _to = coin),
            ),
          ),
          const SizedBox(height: 18),
          _QuickPairs(coins: coins, onSelected: _selectPair),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _Dark.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Result',
                  style: TextStyle(
                    color: _Dark.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _toUsd
                      ? formatPrice(result)
                      : '${_trim(result)} ${_to?.symbol ?? ''}',
                  style: const TextStyle(
                    color: _Dark.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Source: live market prices',
                  style: const TextStyle(
                    color: _Dark.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RateCard(
            fromLabel: _fromUsd ? 'USD' : (_from?.symbol ?? '--'),
            toLabel: _toUsd ? 'USD' : (_to?.symbol ?? '--'),
            directRate: _directRate(),
            inverseRate: _inverseRate(),
          ),
          const SizedBox(height: 14),
          _MarketContext(
            coins: [
              if (!_fromUsd && _from != null) _from!,
              if (!_toUsd && _to != null && _to!.id != _from?.id) _to!,
            ],
          ),
        ],
      ),
    );
  }

  void _selectPair(String fromId, String toId) {
    final coins = widget.controller.coins;
    Coin? find(String id) {
      for (final coin in coins) {
        if (coin.id == id) return coin;
      }
      return null;
    }

    setState(() {
      _fromUsd = fromId == 'usd';
      _toUsd = toId == 'usd';
      if (!_fromUsd) _from = find(fromId) ?? _from;
      if (!_toUsd) _to = find(toId) ?? _to;
    });
  }

  double _directRate() {
    final fromValue = _fromUsd ? 1.0 : (_from?.currentPrice ?? 0);
    final toValue = _toUsd ? 1.0 : (_to?.currentPrice ?? 0);
    if (fromValue <= 0 || toValue <= 0) return 0;
    return fromValue / toValue;
  }

  double _inverseRate() {
    final rate = _directRate();
    return rate <= 0 ? 0 : 1 / rate;
  }

  void _showCoinPicker({
    required String title,
    required Coin? selected,
    required ValueChanged<Coin> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Dark.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _CoinPickerSheet(
        title: title,
        coins: widget.controller.coins.take(160).toList(),
        selected: selected,
        onSelected: (coin) {
          onSelected(coin);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _AssetPicker extends StatelessWidget {
  const _AssetPicker({
    required this.title,
    required this.isUsd,
    required this.coin,
    required this.onUsdChanged,
    required this.onCoinTap,
  });

  final String title;
  final bool isUsd;
  final Coin? coin;
  final ValueChanged<bool> onUsdChanged;
  final VoidCallback onCoinTap;

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
          Text(
            title,
            style: const TextStyle(
              color: _Dark.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('USD')),
              ButtonSegment(value: false, label: Text('Crypto')),
            ],
            selected: {isUsd},
            onSelectionChanged: (value) => onUsdChanged(value.first),
          ),
          if (!isUsd) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onCoinTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _Dark.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _CoinIcon(coin: coin, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        coin == null
                            ? 'Select coin'
                            : '${coin!.symbol} - ${coin!.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _Dark.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _Dark.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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

class _CoinPickerSheet extends StatefulWidget {
  const _CoinPickerSheet({
    required this.title,
    required this.coins,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<Coin> coins;
  final Coin? selected;
  final ValueChanged<Coin> onSelected;

  @override
  State<_CoinPickerSheet> createState() => _CoinPickerSheetState();
}

class _CoinPickerSheetState extends State<_CoinPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final coins = widget.coins.where((coin) {
      return query.isEmpty ||
          coin.symbol.toLowerCase().contains(query) ||
          coin.name.toLowerCase().contains(query);
    }).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.title, style: _Dark.title)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search coin or symbol',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 420,
              child: ListView.separated(
                itemCount: coins.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: _Dark.surfaceVariant, height: 1),
                itemBuilder: (context, index) {
                  final coin = coins[index];
                  final selected = coin.id == widget.selected?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _CoinIcon(coin: coin, size: 36),
                    title: Text(coin.symbol),
                    subtitle: Text(coin.name),
                    trailing: selected
                        ? const Text(
                            'Selected',
                            style: TextStyle(color: _Dark.yellow),
                          )
                        : Text(
                            '#${coin.rank}',
                            style: const TextStyle(color: _Dark.textTertiary),
                          ),
                    onTap: () => widget.onSelected(coin),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.coin, required this.size});

  final Coin? coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (coin == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: _Dark.yellow,
        child: const Text(r'$', style: TextStyle(color: Colors.black)),
      );
    }
    return ClipOval(
      child: Image.network(
        coin!.imageUrl,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: size / 2,
          backgroundColor: _Dark.surfaceVariant,
          child: Text(coin!.symbol.isEmpty ? '?' : coin!.symbol[0]),
        ),
      ),
    );
  }
}

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const green = Color(0xFF00C087);
  static const red = Color(0xFFF6465D);
  static const title = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const hero = TextStyle(
    color: textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w900,
  );
}

String _trim(double value) {
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
