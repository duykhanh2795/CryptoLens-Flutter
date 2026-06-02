import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/screens/manage_exchange_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

part '../widgets/portfolio_header_widgets.dart';
part '../widgets/portfolio_import_widgets.dart';
part '../widgets/portfolio_hero_widgets.dart';
part '../widgets/portfolio_tab_widgets.dart';
part '../widgets/portfolio_transaction_sheet.dart';
part '../widgets/portfolio_shared_widgets.dart';
part '../widgets/portfolio_summary_models.dart';

enum _PortfolioTab { assets, transactions }

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _store = PortfolioStore();
  final List<PortfolioTransaction> _transactions = [];
  final List<PortfolioSnapshot> _snapshots = [];
  _PortfolioTab _selectedTab = _PortfolioTab.assets;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final assets = _buildAssets();
    final summary = _PortfolioSummary.fromAssets(
      assets,
      _transactions,
      snapshots: _snapshots,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _PortfolioTopBar(
            isBusy: widget.controller.isRefreshing,
            onImport: _showImportDialog,
            onExport: _showExportDialog,
            onConnect: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManageExchangeScreen(
                  controller: widget.controller,
                  portfolioStore: _store,
                ),
              ),
            ),
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
    final byCoin = <String, List<PortfolioTransaction>>{};
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
        if (tx.type == PortfolioTransactionType.buy) {
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

  void _addTransaction(PortfolioTransaction transaction) {
    try {
      PortfolioStore.validateHoldings([..._transactions, transaction]);
    } on PortfolioValidationException catch (error) {
      _showMessage(error.message);
      return;
    }
    setState(() {
      _transactions.insert(0, transaction);
      _selectedTab = _PortfolioTab.assets;
    });
    unawaited(_saveTransactions());
    _showMessage('${transaction.type.label} ${transaction.coin.symbol} added.');
  }

  void _deleteTransaction(PortfolioTransaction transaction) {
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
    PortfolioImportPreview? preview;
    PortfolioImportMode mode = PortfolioImportMode.append;
    String? error;
    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Import Portfolio CSV'),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: input,
                    minLines: 7,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Paste CSV exported from CryptoLens here.',
                    ),
                    onChanged: (_) => setDialogState(() {
                      preview = null;
                      error = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PortfolioImportMode>(
                    segments: const [
                      ButtonSegment(
                        value: PortfolioImportMode.append,
                        label: Text('Append'),
                      ),
                      ButtonSegment(
                        value: PortfolioImportMode.replace,
                        label: Text('Replace'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (value) =>
                        setDialogState(() => mode = value.first),
                  ),
                  const SizedBox(height: 12),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (preview != null)
                    _ImportPreviewPanel(preview: preview!, mode: mode)
                  else
                    const Text(
                      'Preview the CSV before importing. Append keeps existing transactions and skips duplicate IDs. Replace clears portfolio history first.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                try {
                  final parsed = _parseCsv(input.text);
                  final nextPreview = PortfolioImportPreview(
                    transactions: parsed,
                  );
                  if (nextPreview.transactions.isEmpty) {
                    throw const PortfolioCsvException(
                      'No valid transactions found.',
                    );
                  }
                  final history = mode == PortfolioImportMode.append
                      ? [
                          ..._transactions.where(
                            (tx) => !parsed.any((item) => item.id == tx.id),
                          ),
                          ...parsed,
                        ]
                      : parsed;
                  PortfolioStore.validateHoldings(history);
                  setDialogState(() {
                    preview = nextPreview;
                    error = null;
                  });
                } catch (exception) {
                  setDialogState(() => error = exception.toString());
                }
              },
              child: const Text('Preview'),
            ),
            FilledButton(
              onPressed: preview == null
                  ? null
                  : () async {
                      try {
                        final count = await _store.importTransactions(
                          preview!.transactions,
                          mode: mode,
                          coinResolver: (coinId, symbol, name, imageUrl) =>
                              _coinFromImport(
                                coinId: coinId,
                                symbol: symbol,
                                name: name,
                                imageUrl: imageUrl,
                              ),
                        );
                        final imported = await _store.load(
                          coinResolver: (coinId, symbol, name, imageUrl) =>
                              _coinFromImport(
                                coinId: coinId,
                                symbol: symbol,
                                name: name,
                                imageUrl: imageUrl,
                              ),
                        );
                        if (!mounted || !context.mounted) return;
                        setState(() {
                          _transactions
                            ..clear()
                            ..addAll(imported..sortByNewest());
                        });
                        await _recordSnapshot();
                        if (!mounted || !context.mounted) return;
                        Navigator.of(context).pop();
                        _showMessage('$count transactions imported.');
                      } catch (exception) {
                        setDialogState(() => error = exception.toString());
                      }
                    },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  String _exportCsv() {
    return PortfolioStore.exportCsv(_transactions);
  }

  List<PortfolioTransaction> _parseCsv(String input) {
    return PortfolioStore.parseCsv(
      input,
      coinResolver: (coinId, symbol, name, imageUrl) => _coinFromImport(
        coinId: coinId,
        symbol: symbol,
        name: name,
        imageUrl: imageUrl,
      ),
    );
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
    final results = await Future.wait<Object>([
      _store.load(
        coinResolver: (coinId, symbol, name, imageUrl) => _coinFromImport(
          coinId: coinId,
          symbol: symbol,
          name: name,
          imageUrl: imageUrl,
        ),
      ),
      _store.loadSnapshots(),
    ]);
    final imported = results[0] as List<PortfolioTransaction>;
    final snapshots = results[1] as List<PortfolioSnapshot>;
    if (!mounted) return;
    setState(() {
      _transactions
        ..clear()
        ..addAll(imported..sortByNewest());
      _snapshots
        ..clear()
        ..addAll(snapshots);
    });
    if (imported.isNotEmpty) {
      unawaited(_recordSnapshot());
    }
  }

  Future<void> _saveTransactions() async {
    _transactions.sortByNewest();
    await _store.save(_transactions);
    await _recordSnapshot();
  }

  Future<void> _recordSnapshot() async {
    final assets = _buildAssets();
    final summary = _PortfolioSummary.fromAssets(assets, _transactions);
    final now = DateTime.now();
    await _store.saveSnapshot(
      PortfolioSnapshot(
        dayStart: DateTime(now.year, now.month, now.day),
        totalValue: summary.totalValue,
        totalInvested: summary.invested,
        totalProfitLoss: summary.pnl,
        totalProfitLossPercent: summary.pnlPercent,
        assetCount: summary.assetCount,
        createdAt: now,
      ),
    );
    final snapshots = await _store.loadSnapshots();
    if (!mounted) return;
    setState(() {
      _snapshots
        ..clear()
        ..addAll(snapshots);
    });
  }
}
