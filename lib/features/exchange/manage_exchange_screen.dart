import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/exchange_store.dart';
import '../../core/services/portfolio_store.dart';
import '../../core/theme/app_theme.dart';
import '../market/market_controller.dart';

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
      backgroundColor: _Dark.background,
      appBar: AppBar(
        title: const Text('Connected Exchanges'),
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
        actions: [
          IconButton(
            onPressed: _openConnectFlow,
            icon: const Icon(Icons.add_rounded, color: _Dark.yellow),
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
              color: _Dark.yellow,
            ),
            const SizedBox(height: 14),
            const Text('No connected exchanges', style: _Dark.hero),
            const SizedBox(height: 8),
            const Text(
              'Connect Binance with read-only keys to import trades into Portfolio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _Dark.textSecondary),
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
        if (index == 0) return _InfoBanner(result: _lastSyncResult);
        final connection = _connections[index - 1];
        return _ExchangeConnectionCard(
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
      MaterialPageRoute(builder: (_) => const _ConnectExchangeScreen()),
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

class _ConnectExchangeScreen extends StatefulWidget {
  const _ConnectExchangeScreen();

  @override
  State<_ConnectExchangeScreen> createState() => _ConnectExchangeScreenState();
}

class _ConnectExchangeScreenState extends State<_ConnectExchangeScreen> {
  final _store = ExchangeStore();
  final _binance = BinanceExchangeService();
  final _label = TextEditingController();
  final _apiKey = TextEditingController();
  final _secret = TextEditingController();
  ExchangeType _exchangeType = ExchangeType.binance;
  _ConnectStep _step = _ConnectStep.selectExchange;
  ApiKeyValidation? _validation;
  bool _busy = false;
  bool _showSecret = false;

  @override
  void dispose() {
    _label.dispose();
    _apiKey.dispose();
    _secret.dispose();
    _binance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Dark.background,
      appBar: AppBar(
        title: Text(switch (_step) {
          _ConnectStep.selectExchange => 'Connect Exchange',
          _ConnectStep.enterKeys => 'Enter API Keys',
          _ConnectStep.validated => 'Confirm Connection',
        }),
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _StepIndicator(step: _step),
          const SizedBox(height: 18),
          switch (_step) {
            _ConnectStep.selectExchange => _selectExchangeStep(),
            _ConnectStep.enterKeys => _enterKeysStep(),
            _ConnectStep.validated => _validatedStep(),
          },
        ],
      ),
    );
  }

  Widget _selectExchangeStep() {
    return Column(
      children: [
        for (final type in ExchangeType.values)
          _ExchangeOption(
            type: type,
            onTap: () {
              if (type != ExchangeType.binance) {
                _showMessage('${type.displayName} integration coming soon');
                return;
              }
              setState(() {
                _exchangeType = type;
                _step = _ConnectStep.enterKeys;
                _label.text = '${type.displayName} main';
              });
            },
          ),
      ],
    );
  }

  Widget _enterKeysStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _label,
          decoration: const InputDecoration(labelText: 'Label'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKey,
          decoration: const InputDecoration(labelText: 'API Key'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _secret,
          obscureText: !_showSecret,
          decoration: InputDecoration(
            labelText: 'API Secret',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showSecret = !_showSecret),
              icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _validate,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Validate And Connect'),
        ),
      ],
    );
  }

  Widget _validatedStep() {
    final validation = _validation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Dark.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_exchangeType.displayName, style: _Dark.title),
              const SizedBox(height: 8),
              Text(_label.text.trim(), style: _Dark.sub),
              const SizedBox(height: 8),
              Text(
                validation?.accountType ?? 'Spot',
                style: const TextStyle(
                  color: _Dark.yellow,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                validation?.canTrade == true
                    ? 'Warning: key has trading permission'
                    : 'Read access validated',
                style: TextStyle(
                  color: validation?.canTrade == true
                      ? AppColors.red
                      : AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Save Connection'),
        ),
        TextButton(
          onPressed: () => setState(() => _step = _ConnectStep.enterKeys),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Future<void> _validate() async {
    if (_apiKey.text.trim().isEmpty || _secret.text.trim().isEmpty) {
      _showMessage('API Key and API Secret are required');
      return;
    }
    setState(() => _busy = true);
    final result = await _binance.validate(
      _apiKey.text.trim(),
      _secret.text.trim(),
    );
    setState(() => _busy = false);
    if (!result.isValid) {
      _showMessage(result.errorMessage ?? 'Validation failed');
      return;
    }
    setState(() {
      _validation = result;
      _step = _ConnectStep.validated;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final connection = await _store.add(
      exchangeType: _exchangeType,
      label: _label.text,
      apiKey: _apiKey.text,
      secret: _secret.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop(connection);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ConnectStep { selectExchange, enterKeys, validated }

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _ConnectStep step;

  @override
  Widget build(BuildContext context) {
    final index = _ConnectStep.values.indexOf(step);
    const labels = ['Exchange', 'API Keys', 'Confirm'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: i <= index ? _Dark.yellow : _Dark.surface,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= index
                          ? const Color(0xFF1A1400)
                          : _Dark.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(labels[i], style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          if (i < labels.length - 1)
            const Expanded(child: Divider(color: _Dark.surfaceVariant)),
        ],
      ],
    );
  }
}

class _ExchangeOption extends StatelessWidget {
  const _ExchangeOption({required this.type, required this.onTap});

  final ExchangeType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _Dark.surface,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _Dark.yellow,
          child: Text(
            type.displayName.substring(0, 1),
            style: const TextStyle(color: Color(0xFF1A1400)),
          ),
        ),
        title: Text(type.displayName, style: _Dark.title),
        subtitle: Text(
          type == ExchangeType.binance
              ? 'Read-only trade import'
              : 'Coming soon',
          style: _Dark.sub,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ExchangeConnectionCard extends StatelessWidget {
  const _ExchangeConnectionCard({
    required this.connection,
    required this.syncing,
    required this.onToggle,
    required this.onDelete,
    required this.onSync,
  });

  final ExchangeConnection connection;
  final bool syncing;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final lastSync = connection.lastSyncAt == null
        ? 'Never synced'
        : 'Last sync: ${DateFormat('dd MMM yyyy, HH:mm').format(connection.lastSyncAt!)}';
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
              CircleAvatar(
                backgroundColor: connection.isActive
                    ? _Dark.yellow
                    : _Dark.surfaceVariant,
                child: Text(
                  connection.exchangeType.displayName.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF1A1400),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(connection.label, style: _Dark.title),
                    Text(connection.exchangeType.displayName, style: _Dark.sub),
                  ],
                ),
              ),
              Switch(value: connection.isActive, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 12),
          Text(connection.maskedApiKey, style: _Dark.sub),
          Text(lastSync, style: _Dark.sub),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: !connection.isActive || syncing ? null : onSync,
                  icon: syncing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: const Text('Sync'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.result});

  final SyncResult? result;

  @override
  Widget build(BuildContext context) {
    final syncResult = result;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        syncResult == null
            ? 'Read-only exchange sync imports trades into your local Portfolio.'
            : 'Last sync imported ${syncResult.tradesImported} trades and skipped ${syncResult.tradesSkipped} duplicates.',
        style: const TextStyle(
          color: _Dark.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
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
