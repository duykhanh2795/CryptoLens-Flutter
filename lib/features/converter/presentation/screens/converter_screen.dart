import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

part '../widgets/converter_asset_picker.dart';
part '../widgets/converter_rate_widgets.dart';
part '../widgets/converter_coin_picker_sheet.dart';
part '../widgets/converter_theme_helpers.dart';

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
