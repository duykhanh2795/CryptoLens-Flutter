import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/coin.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../market/coin_detail_screen.dart';
import '../market/market_controller.dart';

enum _PortfolioTab { assets, transactions }

enum _TransactionType { buy, sell }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  static const _storageKey = 'cryptolens.portfolio.transactions_csv';

  final List<_PortfolioTransaction> _transactions = [];
  _PortfolioTab _selectedTab = _PortfolioTab.assets;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final assets = _buildAssets();
    final summary = _PortfolioSummary.fromAssets(assets, _transactions);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _PortfolioTopBar(
            isBusy: widget.controller.isRefreshing,
            onImport: _showImportDialog,
            onExport: _showExportDialog,
            onConnect: () =>
                _showMessage('Exchange sync is still Kotlin-only.'),
            onAdd: _showAddTransactionSheet,
          ),
          const SizedBox(height: 10),
          _PortfolioHero(summary: summary),
          const SizedBox(height: 12),
          _PortfolioTabs(
            selectedTab: _selectedTab,
            onChanged: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: 10),
          if (_selectedTab == _PortfolioTab.assets)
            _AssetsTab(
              assets: assets,
              onCoinTap: (asset) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CoinDetailScreen(
                    controller: widget.controller,
                    coin: asset.coin,
                  ),
                ),
              ),
              onDelete: _deleteAsset,
            )
          else
            _TransactionsTab(
              transactions: _transactions,
              onDelete: _deleteTransaction,
            ),
        ],
      ),
    );
  }

  List<_PortfolioAsset> _buildAssets() {
    final byCoin = <String, List<_PortfolioTransaction>>{};
    for (final tx in _transactions) {
      byCoin.putIfAbsent(tx.coin.id, () => []).add(tx);
    }

    final assets = <_PortfolioAsset>[];
    for (final entry in byCoin.entries) {
      final txs = [...entry.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      var quantity = 0.0;
      var costBasis = 0.0;
      var realized = 0.0;
      var fees = 0.0;

      for (final tx in txs) {
        fees += tx.fee;
        if (tx.type == _TransactionType.buy) {
          quantity += tx.quantity;
          costBasis += tx.quantity * tx.price + tx.fee;
        } else {
          final avgCost = quantity <= 0 ? 0.0 : costBasis / quantity;
          final sellQuantity = math.min(quantity, tx.quantity);
          realized += sellQuantity * (tx.price - avgCost) - tx.fee;
          quantity -= sellQuantity;
          costBasis -= avgCost * sellQuantity;
        }
      }

      if (quantity > 0.00000001) {
        final liveCoin = _findLiveCoin(entry.key);
        assets.add(
          _PortfolioAsset(
            coin: liveCoin ?? txs.last.coin,
            quantity: quantity,
            costBasis: costBasis,
            realizedPnl: realized,
            fees: fees,
          ),
        );
      }
    }

    assets.sort((a, b) => b.currentValue.compareTo(a.currentValue));
    return assets;
  }

  Coin? _findLiveCoin(String coinId) {
    for (final coin in widget.controller.coins) {
      if (coin.id == coinId) return coin;
    }
    return null;
  }

  void _addTransaction(_PortfolioTransaction transaction) {
    setState(() {
      _transactions.insert(0, transaction);
      _selectedTab = _PortfolioTab.assets;
    });
    unawaited(_saveTransactions());
    _showMessage('${transaction.type.label} ${transaction.coin.symbol} added.');
  }

  void _deleteTransaction(_PortfolioTransaction transaction) {
    setState(
      () => _transactions.removeWhere((item) => item.id == transaction.id),
    );
    unawaited(_saveTransactions());
  }

  void _deleteAsset(_PortfolioAsset asset) {
    setState(
      () => _transactions.removeWhere((tx) => tx.coin.id == asset.coin.id),
    );
    unawaited(_saveTransactions());
  }

  void _showAddTransactionSheet() {
    final coins = widget.controller.coins.isNotEmpty
        ? widget.controller.coins.take(40).toList()
        : widget.controller.watchlistCoins;
    if (coins.isEmpty) {
      _showMessage('Market data is still loading. Try again in a moment.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AddTransactionSheet(
        coins: coins,
        availableQuantityByCoin: {
          for (final asset in _buildAssets()) asset.coin.id: asset.quantity,
        },
        onConfirm: _addTransaction,
      ),
    );
  }

  void _showExportDialog() {
    final csv = _exportCsv();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Portfolio CSV'),
        content: SizedBox(
          width: 520,
          child: SelectableText(
            csv.isEmpty ? 'No transactions to export.' : csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final input = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Portfolio CSV'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: input,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Paste CSV exported from CryptoLens Flutter here.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final imported = _parseCsv(input.text);
              if (imported.isEmpty) {
                _showMessage('No valid transactions found.');
                return;
              }
              setState(
                () => _transactions
                  ..clear()
                  ..addAll(imported),
              );
              unawaited(_saveTransactions());
              Navigator.of(context).pop();
              _showMessage('Imported ${imported.length} transactions.');
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  String _exportCsv() {
    if (_transactions.isEmpty) return '';
    final rows = [
      'id,coinId,symbol,name,imageUrl,type,quantity,price,fee,timestamp,note',
      for (final tx in _transactions)
        [
          tx.id,
          tx.coin.id,
          tx.coin.symbol,
          tx.coin.name,
          tx.coin.imageUrl,
          tx.type.name,
          tx.quantity.toStringAsFixed(12),
          tx.price.toStringAsFixed(8),
          tx.fee.toStringAsFixed(8),
          tx.timestamp.millisecondsSinceEpoch.toString(),
          tx.note,
        ].map(_escapeCsv).join(','),
    ];
    return rows.join('\n');
  }

  List<_PortfolioTransaction> _parseCsv(String input) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];
    final imported = <_PortfolioTransaction>[];
    for (final line in lines.skip(1)) {
      final columns = _splitCsv(line);
      if (columns.length < 11) continue;
      final coin = _coinFromImport(
        coinId: columns[1],
        symbol: columns[2],
        name: columns[3],
        imageUrl: columns[4],
      );
      imported.add(
        _PortfolioTransaction(
          id: columns[0].isEmpty ? _newId() : columns[0],
          coin: coin,
          type: columns[5] == 'sell'
              ? _TransactionType.sell
              : _TransactionType.buy,
          quantity: double.tryParse(columns[6]) ?? 0,
          price: double.tryParse(columns[7]) ?? coin.currentPrice,
          fee: double.tryParse(columns[8]) ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(columns[9]) ?? DateTime.now().millisecondsSinceEpoch,
          ),
          note: columns[10],
        ),
      );
    }
    return imported.where((tx) => tx.quantity > 0 && tx.price >= 0).toList();
  }

  Coin _coinFromImport({
    required String coinId,
    required String symbol,
    required String name,
    required String imageUrl,
  }) {
    return widget.controller.coins.firstWhere(
      (coin) => coin.id == coinId,
      orElse: () => Coin(
        id: coinId,
        symbol: symbol,
        name: name,
        imageUrl: imageUrl,
        currentPrice: 0,
        priceChangePercent24h: 0,
        priceChange24h: 0,
        marketCap: 0,
        volume24h: 0,
        high24h: 0,
        low24h: 0,
        circulatingSupply: 0,
        rank: 0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final csv = prefs.getString(_storageKey);
    if (!mounted || csv == null || csv.trim().isEmpty) return;
    final imported = _parseCsv(csv);
    if (imported.isEmpty) return;
    setState(() => _transactions.addAll(imported));
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final csv = _exportCsv();
    if (csv.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, csv);
    }
  }
}

class _PortfolioTopBar extends StatelessWidget {
  const _PortfolioTopBar({
    required this.isBusy,
    required this.onImport,
    required this.onExport,
    required this.onConnect,
    required this.onAdd,
  });

  final bool isBusy;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onConnect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Portfolio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isBusy) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        _HeaderIcon(
          icon: Icons.upload_file_rounded,
          tooltip: 'Import',
          onTap: onImport,
        ),
        _HeaderIcon(
          icon: Icons.file_download_rounded,
          tooltip: 'Export',
          onTap: onExport,
        ),
        _HeaderIcon(
          icon: Icons.account_balance_rounded,
          tooltip: 'Connect Exchange',
          onTap: onConnect,
        ),
        _HeaderIcon(icon: Icons.add_rounded, tooltip: 'Add', onTap: onAdd),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 38, height: 40),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textSecondary, size: 22),
    );
  }
}

class _PortfolioHero extends StatefulWidget {
  const _PortfolioHero({required this.summary});

  final _PortfolioSummary summary;

  @override
  State<_PortfolioHero> createState() => _PortfolioHeroState();
}

class _PortfolioHeroState extends State<_PortfolioHero> {
  String _range = '24H';

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final isProfit = summary.pnl >= 0;
    final isDayUp = summary.dayChange >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Text(
              'USD',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Allocation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          formatPrice(summary.totalValue),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _signedMoney(summary.pnl),
              style: TextStyle(
                color: isProfit ? AppColors.green : AppColors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isProfit ? AppColors.greenSurface : AppColors.redSurface,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                formatPercent(summary.pnlPercent),
                style: TextStyle(
                  color: isProfit ? AppColors.green : AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 228,
          width: double.infinity,
          child: CustomPaint(
            painter: _PortfolioChartPainter(
              values: summary.chartValues,
              color: isDayUp ? AppColors.green : AppColors.red,
            ),
          ),
        ),
        _RangeSelector(
          selected: _range,
          onChanged: (value) => setState(() => _range = value),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Metric(label: 'Invested', value: formatPrice(summary.invested)),
            _Metric(
              label: 'Unrealized',
              value: _signedMoney(summary.unrealized),
              valueColor: summary.unrealized >= 0
                  ? AppColors.green
                  : AppColors.red,
              align: TextAlign.center,
            ),
            _Metric(
              label: 'Realized',
              value: _signedMoney(summary.realized),
              valueColor: summary.realized >= 0
                  ? AppColors.green
                  : AppColors.red,
              align: TextAlign.end,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Metric(label: 'Fees', value: formatPrice(summary.fees)),
            _Metric(
              label: '24H',
              value:
                  '${_signedMoney(summary.dayChange)} / ${formatPercent(summary.dayChangePercent)}',
              valueColor: isDayUp ? AppColors.green : AppColors.red,
              align: TextAlign.center,
            ),
            _Metric(
              label: 'Assets',
              value: '${summary.assetCount}',
              align: TextAlign.end,
            ),
          ],
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const ranges = ['24H', '1W', '1M', '1Y', 'ALL'];
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final range in ranges)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(range),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == range
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      color: selected == range
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.align = TextAlign.start,
  });

  final String label;
  final String value;
  final Color valueColor;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: switch (align) {
          TextAlign.end => CrossAxisAlignment.end,
          TextAlign.center => CrossAxisAlignment.center,
          _ => CrossAxisAlignment.start,
        },
        children: [
          Text(
            label,
            textAlign: align,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: align,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioTabs extends StatelessWidget {
  const _PortfolioTabs({required this.selectedTab, required this.onChanged});

  final _PortfolioTab selectedTab;
  final ValueChanged<_PortfolioTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PortfolioTabButton(
            label: 'Assets',
            selected: selectedTab == _PortfolioTab.assets,
            onTap: () => onChanged(_PortfolioTab.assets),
          ),
          _PortfolioTabButton(
            label: 'Transactions',
            selected: selectedTab == _PortfolioTab.transactions,
            onTap: () => onChanged(_PortfolioTab.transactions),
          ),
        ],
      ),
    );
  }
}

class _PortfolioTabButton extends StatelessWidget {
  const _PortfolioTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 2,
              color: selected ? AppColors.textPrimary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetsTab extends StatelessWidget {
  const _AssetsTab({
    required this.assets,
    required this.onCoinTap,
    required this.onDelete,
  });

  final List<_PortfolioAsset> assets;
  final ValueChanged<_PortfolioAsset> onCoinTap;
  final ValueChanged<_PortfolioAsset> onDelete;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const _PortfolioEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No assets yet',
        message: 'Tap + to record your first buy.',
      );
    }

    final total = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    return Column(
      children: [
        for (final asset in assets)
          _AssetRow(
            asset: asset,
            allocation: total <= 0 ? 0 : asset.currentValue / total * 100,
            onTap: () => onCoinTap(asset),
            onDelete: () => onDelete(asset),
          ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.allocation,
    required this.onTap,
    required this.onDelete,
  });

  final _PortfolioAsset asset;
  final double allocation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isProfit = asset.unrealizedPnl >= 0;
    final coin = asset.coin;
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.currency_bitcoin, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Qty: ${_trim(asset.quantity)}',
                    style: _assetMetaStyle(AppColors.textSecondary),
                  ),
                  Text(
                    'Avg: ${formatPrice(asset.averagePrice)}',
                    style: _assetMetaStyle(AppColors.textTertiary),
                  ),
                  Text(
                    '${allocation.toStringAsFixed(1)}% allocation',
                    style: _assetMetaStyle(AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(asset.currentValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _signedMoney(asset.unrealizedPnl),
                  style: TextStyle(
                    color: isProfit ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '(${formatPercent(asset.unrealizedPnlPercent)})',
                  style: TextStyle(
                    color: isProfit ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '24h ${_signedMoney(coin.priceChange24h * asset.quantity)}',
                  style: TextStyle(
                    color: coin.priceChange24h >= 0
                        ? AppColors.green
                        : AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.transactions, required this.onDelete});

  final List<_PortfolioTransaction> transactions;
  final ValueChanged<_PortfolioTransaction> onDelete;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _PortfolioEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions',
        message: 'Your buy/sell history will appear here.',
      );
    }
    return Column(
      children: [
        for (final tx in transactions)
          _TransactionRow(transaction: tx, onDelete: () => onDelete(tx)),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.onDelete});

  final _PortfolioTransaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction.type == _TransactionType.buy;
    return InkWell(
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isBuy
                  ? AppColors.greenSurface
                  : AppColors.redSurface,
              child: Icon(
                isBuy ? Icons.add_rounded : Icons.remove_rounded,
                color: isBuy ? AppColors.green : AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: transaction.type.label,
                          style: TextStyle(
                            color: isBuy ? AppColors.green : AppColors.red,
                          ),
                        ),
                        TextSpan(text: ' ${transaction.coin.symbol}'),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(transaction.timestamp),
                    style: _assetMetaStyle(AppColors.textTertiary),
                  ),
                  if (transaction.note.isNotEmpty)
                    Text(
                      transaction.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _assetMetaStyle(AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_trim(transaction.quantity)} ${transaction.coin.symbol}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '@ ${formatPrice(transaction.price)}',
                  style: _assetMetaStyle(AppColors.textSecondary),
                ),
                Text(
                  formatPrice(transaction.total),
                  style: TextStyle(
                    color: isBuy ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet({
    required this.coins,
    required this.availableQuantityByCoin,
    required this.onConfirm,
  });

  final List<Coin> coins;
  final Map<String, double> availableQuantityByCoin;
  final ValueChanged<_PortfolioTransaction> onConfirm;

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  late Coin _coin = widget.coins.first;
  _TransactionType _type = _TransactionType.buy;
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _fee = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _price.text = _coin.currentPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _fee.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(_quantity.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    final fee = double.tryParse(_fee.text) ?? 0;
    final total = quantity * price + fee;
    final availableQuantity = widget.availableQuantityByCoin[_coin.id] ?? 0;
    final sellTooMuch =
        _type == _TransactionType.sell && quantity > availableQuantity;
    final canSubmit =
        quantity > 0 &&
        price >= 0 &&
        (_type == _TransactionType.buy || !sellTooMuch);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Transaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TypeButton(
                  label: 'BUY',
                  selected: _type == _TransactionType.buy,
                  color: AppColors.green,
                  onTap: () => setState(() => _type = _TransactionType.buy),
                ),
                const SizedBox(width: 8),
                _TypeButton(
                  label: 'SELL',
                  selected: _type == _TransactionType.sell,
                  color: AppColors.red,
                  onTap: () => setState(() => _type = _TransactionType.sell),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<Coin>(
              initialValue: _coin,
              decoration: const InputDecoration(labelText: 'Coin'),
              items: [
                for (final coin in widget.coins)
                  DropdownMenuItem(
                    value: coin,
                    child: Text('${coin.symbol} - ${coin.name}'),
                  ),
              ],
              onChanged: (coin) {
                if (coin == null) return;
                setState(() {
                  _coin = coin;
                  _price.text = coin.currentPrice.toStringAsFixed(2);
                });
              },
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: _quantity,
              label: 'Quantity',
              hint: 'e.g. 0.5',
              onChanged: (_) => setState(() {}),
            ),
            if (_type == _TransactionType.sell) ...[
              const SizedBox(height: 6),
              Text(
                'Available: ${_trim(availableQuantity)} ${_coin.symbol}',
                style: TextStyle(
                  color: sellTooMuch ? AppColors.red : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SheetField(
              controller: _price,
              label: 'Price per coin (USD)',
              hint: 'e.g. 65000',
              prefix: r'$',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _SheetField(
              controller: _fee,
              label: 'Fee (optional)',
              hint: 'e.g. 1.5',
              prefix: r'$',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. DCA strategy',
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(total),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _type == _TransactionType.buy
                      ? AppColors.green
                      : AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: !canSubmit
                    ? null
                    : () {
                        widget.onConfirm(
                          _PortfolioTransaction(
                            id: _newId(),
                            coin: _coin,
                            type: _type,
                            quantity: quantity,
                            price: price,
                            fee: fee,
                            timestamp: DateTime.now(),
                            note: _note.text.trim(),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                child: Text(
                  'Confirm ${_type.label.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.prefix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? prefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
      ),
    );
  }
}

class _PortfolioEmptyState extends StatelessWidget {
  const _PortfolioEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PortfolioChartPainter extends CustomPainter {
  const _PortfolioChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.01);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          size.height -
              ((values[i] - minValue) / range * size.height * 0.72) -
              28,
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PortfolioChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _PortfolioSummary {
  const _PortfolioSummary({
    required this.totalValue,
    required this.invested,
    required this.pnl,
    required this.pnlPercent,
    required this.unrealized,
    required this.realized,
    required this.fees,
    required this.dayChange,
    required this.dayChangePercent,
    required this.assetCount,
    required this.chartValues,
  });

  final double totalValue;
  final double invested;
  final double pnl;
  final double pnlPercent;
  final double unrealized;
  final double realized;
  final double fees;
  final double dayChange;
  final double dayChangePercent;
  final int assetCount;
  final List<double> chartValues;

  factory _PortfolioSummary.fromAssets(
    List<_PortfolioAsset> assets,
    List<_PortfolioTransaction> transactions,
  ) {
    final totalValue = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    final invested = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.costBasis,
    );
    final unrealized = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.unrealizedPnl,
    );
    final realized = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.realizedPnl,
    );
    final fees = transactions.fold<double>(0, (sum, tx) => sum + tx.fee);
    final dayChange = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.coin.priceChange24h * asset.quantity,
    );
    final previousValue = math.max(totalValue - dayChange, 0.01);
    final pnl = unrealized + realized;
    final pnlPercent = invested == 0 ? 0.0 : pnl / invested * 100;
    final seed = totalValue == 0 ? 1000.0 : previousValue;
    final chartValues = List<double>.generate(32, (index) {
      final t = index / 31;
      final wave = math.sin(t * math.pi * 3) * seed * 0.018;
      return seed + (totalValue - seed) * t + wave;
    });
    return _PortfolioSummary(
      totalValue: totalValue,
      invested: invested,
      pnl: pnl,
      pnlPercent: pnlPercent,
      unrealized: unrealized,
      realized: realized,
      fees: fees,
      dayChange: dayChange,
      dayChangePercent: dayChange / previousValue * 100,
      assetCount: assets.length,
      chartValues: chartValues,
    );
  }
}

class _PortfolioAsset {
  const _PortfolioAsset({
    required this.coin,
    required this.quantity,
    required this.costBasis,
    required this.realizedPnl,
    required this.fees,
  });

  final Coin coin;
  final double quantity;
  final double costBasis;
  final double realizedPnl;
  final double fees;

  double get averagePrice => quantity <= 0 ? 0 : costBasis / quantity;
  double get currentValue => coin.currentPrice * quantity;
  double get unrealizedPnl => currentValue - costBasis;
  double get unrealizedPnlPercent =>
      costBasis == 0 ? 0 : unrealizedPnl / costBasis * 100;
}

class _PortfolioTransaction {
  const _PortfolioTransaction({
    required this.id,
    required this.coin,
    required this.type,
    required this.quantity,
    required this.price,
    required this.fee,
    required this.timestamp,
    required this.note,
  });

  final String id;
  final Coin coin;
  final _TransactionType type;
  final double quantity;
  final double price;
  final double fee;
  final DateTime timestamp;
  final String note;

  double get total => quantity * price + fee;
}

extension on _TransactionType {
  String get label => switch (this) {
    _TransactionType.buy => 'Buy',
    _TransactionType.sell => 'Sell',
  };
}

TextStyle _assetMetaStyle(Color color) {
  return TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700);
}

String _signedMoney(double value) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${formatPrice(value.abs())}';
}

String _trim(double value) {
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

String _escapeCsv(String value) {
  if (!value.contains(RegExp('[,"\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}

List<String> _splitCsv(String row) {
  final values = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var i = 0; i < row.length; i++) {
    final char = row[i];
    if (char == '"') {
      if (quoted && i + 1 < row.length && row[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      values.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  values.add(buffer.toString());
  return values;
}
