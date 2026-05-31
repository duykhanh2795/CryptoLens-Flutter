import 'package:flutter/material.dart';

import '../../core/models/coin.dart';
import '../../core/utils/formatters.dart';
import '../market/market_controller.dart';

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
            coins: coins,
            onUsdChanged: (value) => setState(() => _fromUsd = value),
            onCoinChanged: (coin) => setState(() => _from = coin),
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
            coins: coins,
            onUsdChanged: (value) => setState(() => _toUsd = value),
            onCoinChanged: (coin) => setState(() => _to = coin),
          ),
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
        ],
      ),
    );
  }
}

class _AssetPicker extends StatelessWidget {
  const _AssetPicker({
    required this.title,
    required this.isUsd,
    required this.coin,
    required this.coins,
    required this.onUsdChanged,
    required this.onCoinChanged,
  });

  final String title;
  final bool isUsd;
  final Coin? coin;
  final List<Coin> coins;
  final ValueChanged<bool> onUsdChanged;
  final ValueChanged<Coin?> onCoinChanged;

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
            DropdownButtonFormField<Coin>(
              initialValue: coin,
              dropdownColor: _Dark.surface,
              decoration: const InputDecoration(labelText: 'Coin'),
              items: [
                for (final item in coins)
                  DropdownMenuItem(
                    value: item,
                    child: Text('${item.symbol} - ${item.name}'),
                  ),
              ],
              onChanged: onCoinChanged,
            ),
          ],
        ],
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
