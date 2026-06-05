import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_resolver.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_calculator.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_models.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/screens/manage_exchange_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/screens/coin_detail_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/screens/portfolio_allocation_screen.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/state/portfolio_tab.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_header_widgets.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_hero_widgets.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_import_widgets.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_tab_widgets.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/widgets/portfolio_transaction_sheet.dart';

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
  PortfolioTab _selectedTab = PortfolioTab.assets;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final assets = PortfolioCalculator.buildAssets(
      transactions: _transactions,
      liveCoins: widget.controller.coins,
    );
    final summary = PortfolioSummary.fromAssets(
      assets,
      _transactions,
      snapshots: _snapshots,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          PortfolioTopBar(
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
          PortfolioHero(
            summary: summary,
            onOpenAllocation: () => _openAllocation(assets),
          ),
          const SizedBox(height: 12),
          PortfolioTabs(
            selectedTab: _selectedTab,
            onChanged: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: 10),
          if (_selectedTab == PortfolioTab.assets)
            AssetsTab(
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
            TransactionsTab(
              transactions: _transactions,
              onDelete: _deleteTransaction,
            ),
        ],
      ),
    );
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
      _selectedTab = PortfolioTab.assets;
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

  void _deleteAsset(PortfolioAsset asset) {
    setState(
      () => _transactions.removeWhere((tx) => tx.coin.id == asset.coin.id),
    );
    unawaited(_saveTransactions());
  }

  void _openAllocation(List<PortfolioAsset> assets) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PortfolioAllocationScreen(assets: assets),
      ),
    );
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
      builder: (_) => AddTransactionSheet(
        coins: coins,
        availableQuantityByCoin: {
          for (final asset in PortfolioCalculator.buildAssets(
            transactions: _transactions,
            liveCoins: widget.controller.coins,
          ))
            asset.coin.id: asset.quantity,
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
                    ImportPreviewPanel(preview: preview!, mode: mode)
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
    return CoinResolver(widget.controller.coins).resolveSnapshot(
      coinId: coinId,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
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
    final assets = PortfolioCalculator.buildAssets(
      transactions: _transactions,
      liveCoins: widget.controller.coins,
    );
    final summary = PortfolioSummary.fromAssets(assets, _transactions);
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
