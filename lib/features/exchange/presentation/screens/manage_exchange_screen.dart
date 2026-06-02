import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/exchange/data/exchange_store.dart';
import 'package:cryptolens_flutter/features/exchange/domain/exchange.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

import 'package:cryptolens_flutter/features/exchange/presentation/widgets/connect_exchange_flow.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/widgets/exchange_common_widgets.dart';
import 'package:cryptolens_flutter/features/exchange/presentation/widgets/exchange_connection_card.dart';

class ManageExchangeScreen extends StatefulWidget {
  const ManageExchangeScreen({
    required this.controller,
    this.portfolioStore,
    super.key,
  });

  final MarketController controller;
  final PortfolioStore? portfolioStore;

  @override
  State<ManageExchangeScreen> createState() => _ManageExchangeScreenState();
}

class _ManageExchangeScreenState extends State<ManageExchangeScreen> {
  final _store = ExchangeStore();
  late final PortfolioStore _portfolioStore =
      widget.portfolioStore ?? PortfolioStore();
  final _binance = BinanceExchangeService();
  final List<ExchangeConnection> _connections = [];
  SyncResult? _lastSyncResult;
  String? _syncingId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadConnections());
  }

  @override
  void dispose() {
    _binance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExchangeColors.background,
      appBar: AppBar(
        title: const Text('Connected Exchanges'),
        backgroundColor: ExchangeColors.background,
        foregroundColor: ExchangeColors.textPrimary,
        actions: [
          IconButton(
            onPressed: _openConnectFlow,
            icon: const Icon(Icons.add_rounded, color: ExchangeColors.yellow),
          ),
        ],
      ),
      body: _connections.isEmpty ? _emptyState() : _connectionList(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_rounded,
              size: 64,
              color: ExchangeColors.yellow,
            ),
            const SizedBox(height: 14),
            const Text('No connected exchanges', style: ExchangeColors.hero),
            const SizedBox(height: 8),
            const Text(
              'Connect Binance with read-only keys to import trades into Portfolio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ExchangeColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openConnectFlow,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Connect Exchange'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionList() {
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: _connections.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) return InfoBanner(result: _lastSyncResult);
        final connection = _connections[index - 1];
        return ExchangeConnectionCard(
          connection: connection,
          syncing: _syncingId == connection.id,
          onToggle: (value) => _toggleActive(connection, value),
          onDelete: () => _deleteConnection(connection),
          onSync: () => _syncConnection(connection),
        );
      },
    );
  }

  Future<void> _loadConnections() async {
    final connections = await _store.load();
    if (!mounted) return;
    setState(() {
      _connections
        ..clear()
        ..addAll(connections);
    });
  }

  Future<void> _persist() => _store.save(_connections);

  Future<void> _toggleActive(ExchangeConnection connection, bool active) async {
    setState(() {
      final index = _connections.indexWhere((item) => item.id == connection.id);
      if (index >= 0) {
        _connections[index] = connection.copyWith(isActive: active);
      }
    });
    await _persist();
  }

  Future<void> _deleteConnection(ExchangeConnection connection) async {
    setState(
      () => _connections.removeWhere((item) => item.id == connection.id),
    );
    await _persist();
    _showMessage('Connection removed');
  }

  Future<void> _syncConnection(ExchangeConnection connection) async {
    if (!connection.isActive || _syncingId != null) return;
    setState(() => _syncingId = connection.id);
    try {
      final result = await _binance.syncTrades(
        connection: connection,
        coins: widget.controller.coins,
        portfolioStore: _portfolioStore,
      );
      setState(() {
        _syncingId = null;
        _lastSyncResult = result;
        final index = _connections.indexWhere(
          (item) => item.id == connection.id,
        );
        if (index >= 0) {
          _connections[index] = connection.copyWith(
            lastSyncAt: result.syncedAt,
          );
        }
      });
      await _persist();
      if (mounted) _showSyncDialog(result);
    } catch (error) {
      setState(() => _syncingId = null);
      _showMessage(error.toString());
    }
  }

  Future<void> _openConnectFlow() async {
    final connection = await Navigator.of(context).push<ExchangeConnection>(
      MaterialPageRoute(builder: (_) => const ConnectExchangeScreen()),
    );
    if (connection == null) return;
    setState(() => _connections.insert(0, connection));
    await _persist();
  }

  void _showSyncDialog(SyncResult result) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sync Complete'),
        content: Text(
          '${result.tradesImported} trades imported\n'
          '${result.tradesSkipped} duplicates skipped\n'
          '${result.symbolsScanned} pairs scanned',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
