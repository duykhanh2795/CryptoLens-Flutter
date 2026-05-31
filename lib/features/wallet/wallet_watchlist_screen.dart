import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../market/market_controller.dart';

class WalletWatchlistScreen extends StatefulWidget {
  const WalletWatchlistScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<WalletWatchlistScreen> createState() => _WalletWatchlistScreenState();
}

class _WalletWatchlistScreenState extends State<WalletWatchlistScreen> {
  static const _storageKey = 'cryptolens.wallet.watchlist';

  final List<_WatchedWallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadWallets());
  }

  @override
  Widget build(BuildContext context) {
    final topCoins = widget.controller.coins.take(3).toList();
    final estimatedValue = topCoins.fold<double>(
      0,
      (sum, coin) => sum + coin.currentPrice * 0.01,
    );

    return Scaffold(
      backgroundColor: _Dark.background,
      appBar: AppBar(
        title: const Text('Wallet Watchlist'),
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded, color: _Dark.yellow),
          ),
        ],
      ),
      body: _wallets.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _Dark.textTertiary,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No watched wallets',
                      style: _Dark.hero,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add an address to track activity locally.',
                      style: TextStyle(color: _Dark.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: _wallets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final wallet = _wallets[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _Dark.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wallet_rounded, color: _Dark.yellow),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(wallet.label, style: _Dark.title),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _wallets.removeAt(index));
                              unawaited(_saveWallets());
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                      Text(wallet.chain, style: _Dark.sub),
                      const SizedBox(height: 4),
                      Text(
                        wallet.shortAddress,
                        style: const TextStyle(
                          color: _Dark.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Divider(color: _Dark.surfaceVariant, height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _WalletMetric(
                              label: 'Estimated',
                              value: formatPrice(estimatedValue),
                            ),
                          ),
                          Expanded(
                            child: _WalletMetric(
                              label: 'Assets',
                              value: '${topCoins.length}',
                            ),
                          ),
                          const Expanded(
                            child: _WalletMetric(
                              label: 'Status',
                              value: 'Watching',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddDialog() {
    final label = TextEditingController(text: 'Main wallet');
    final address = TextEditingController();
    var chain = 'Ethereum';
    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: chain,
                items: const [
                  DropdownMenuItem(value: 'Ethereum', child: Text('Ethereum')),
                  DropdownMenuItem(value: 'BSC', child: Text('BSC')),
                  DropdownMenuItem(value: 'Polygon', child: Text('Polygon')),
                ],
                onChanged: (value) =>
                    setDialogState(() => chain = value ?? chain),
                decoration: const InputDecoration(labelText: 'Chain'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final cleanAddress = address.text.trim();
                if (cleanAddress.length < 8) return;
                setState(() {
                  _wallets.insert(
                    0,
                    _WatchedWallet(
                      label: label.text.trim().isEmpty
                          ? 'Wallet'
                          : label.text.trim(),
                      chain: chain,
                      address: cleanAddress,
                    ),
                  );
                });
                unawaited(_saveWallets());
                Navigator.of(context).pop();
              },
              child: const Text('Watch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    setState(() {
      _wallets
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, Object?>>()
              .map(_WatchedWallet.fromJson)
              .whereType<_WatchedWallet>(),
        );
    });
  }

  Future<void> _saveWallets() async {
    final prefs = await SharedPreferences.getInstance();
    if (_wallets.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(
        _storageKey,
        jsonEncode(_wallets.map((wallet) => wallet.toJson()).toList()),
      );
    }
  }
}

class _WalletMetric extends StatelessWidget {
  const _WalletMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _Dark.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _Dark.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WatchedWallet {
  const _WatchedWallet({
    required this.label,
    required this.chain,
    required this.address,
  });

  final String label;
  final String chain;
  final String address;

  String get shortAddress {
    if (address.length <= 14) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  Map<String, Object?> toJson() => {
    'label': label,
    'chain': chain,
    'address': address,
  };

  static _WatchedWallet? fromJson(Map<String, Object?> json) {
    final address = json['address']?.toString();
    if (address == null || address.length < 8) return null;
    return _WatchedWallet(
      label: json['label']?.toString() ?? 'Wallet',
      chain: json['chain']?.toString() ?? 'Ethereum',
      address: address,
    );
  }
}

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
  static const hero = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const title = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );
  static const sub = TextStyle(
    color: textSecondary,
    fontWeight: FontWeight.w700,
  );
}
