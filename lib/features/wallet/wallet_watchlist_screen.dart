import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/wallet_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../market/market_controller.dart';
import 'trending_wallets_screen.dart';

class WalletWatchlistScreen extends StatefulWidget {
  const WalletWatchlistScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<WalletWatchlistScreen> createState() => _WalletWatchlistScreenState();
}

class _WalletWatchlistScreenState extends State<WalletWatchlistScreen> {
  final _store = WalletStore();
  final List<WatchedWallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadWallets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Dark.background,
      appBar: AppBar(
        title: const Text('Wallet Watchlist'),
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
        actions: [
          IconButton(
            onPressed: _loadWallets,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded, color: _Dark.yellow),
          ),
        ],
      ),
      body: _wallets.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: _wallets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final wallet = _wallets[index];
                final detail = buildTrendingWalletDetail(
                  TrendingWallet(
                    chain: wallet.chain,
                    address: wallet.address,
                    label: wallet.label,
                    nativeBalance: 0.04,
                    txCount: 0,
                    valueUsd: _estimatedValue,
                    changePercent24h: _averageChange,
                    avatarSeed: wallet.address.hashCode,
                  ),
                  widget.controller.coins,
                );
                return _WatchedWalletCard(
                  wallet: wallet,
                  estimatedValue: detail.assets.fold<double>(
                    0,
                    (sum, asset) => sum + (asset.valueUsd ?? 0),
                  ),
                  assetCount: detail.assets.length,
                  onDetails: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrendingWalletDetailScreen(
                        controller: widget.controller,
                        wallet: detail.wallet,
                      ),
                    ),
                  ),
                  onDelete: () => _delete(wallet),
                );
              },
            ),
    );
  }

  double get _estimatedValue => widget.controller.coins
      .take(3)
      .fold<double>(0, (sum, coin) => sum + coin.currentPrice * 0.01);

  double get _averageChange {
    final coins = widget.controller.coins.take(5).toList();
    if (coins.isEmpty) return 0;
    return coins.fold<double>(
          0,
          (sum, coin) => sum + coin.priceChangePercent24h,
        ) /
        coins.length;
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: _Dark.textTertiary,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No watched wallets',
              style: _Dark.hero,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add an address manually or save one from Trending Wallets.',
              style: TextStyle(color: _Dark.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TrendingWalletsScreen(controller: widget.controller),
                ),
              ),
              icon: const Icon(Icons.trending_up_rounded),
              label: const Text('Explore Trending Wallets'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final label = TextEditingController(text: 'Main wallet');
    final address = TextEditingController();
    var chain = WalletChain.ethereum;
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
              DropdownButtonFormField<WalletChain>(
                initialValue: chain,
                items: [
                  for (final value in WalletChain.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
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
              onPressed: () async {
                final cleanAddress = address.text.trim();
                if (cleanAddress.length < 8) return;
                await _store.add(
                  WatchedWallet(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    label: label.text.trim().isEmpty
                        ? 'Wallet'
                        : label.text.trim(),
                    chain: chain,
                    address: cleanAddress,
                    createdAt: DateTime.now(),
                  ),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                await _loadWallets();
              },
              child: const Text('Watch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadWallets() async {
    final wallets = await _store.load();
    if (!mounted) return;
    setState(() {
      _wallets
        ..clear()
        ..addAll(wallets);
    });
  }

  Future<void> _delete(WatchedWallet wallet) async {
    setState(() => _wallets.removeWhere((item) => item.id == wallet.id));
    await _store.save(_wallets);
  }
}

class _WatchedWalletCard extends StatelessWidget {
  const _WatchedWalletCard({
    required this.wallet,
    required this.estimatedValue,
    required this.assetCount,
    required this.onDetails,
    required this.onDelete,
  });

  final WatchedWallet wallet;
  final double estimatedValue;
  final int assetCount;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
                Expanded(child: Text(wallet.label, style: _Dark.title)),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            Text(wallet.chain.label, style: _Dark.sub),
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
                  child: _WalletMetric(label: 'Assets', value: '$assetCount'),
                ),
                const Expanded(
                  child: _WalletMetric(label: 'Status', value: 'Watching'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
