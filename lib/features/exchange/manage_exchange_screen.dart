import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageExchangeScreen extends StatefulWidget {
  const ManageExchangeScreen({super.key});

  @override
  State<ManageExchangeScreen> createState() => _ManageExchangeScreenState();
}

class _ManageExchangeScreenState extends State<ManageExchangeScreen> {
  static const _storageKey = 'cryptolens.exchange.connections';

  final List<_ExchangeConnection> _connections = const [
    _ExchangeConnection(
      exchange: 'Binance',
      label: 'Demo connection',
      status: 'Read-only',
    ),
  ].toList();

  @override
  void initState() {
    super.initState();
    unawaited(_loadConnections());
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
            onPressed: _showConnectDialog,
            icon: const Icon(Icons.add_rounded, color: _Dark.yellow),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: _connections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final connection = _connections[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _Dark.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: _Dark.yellow,
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF1A1400),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(connection.exchange, style: _Dark.title),
                      Text(connection.label, style: _Dark.sub),
                      Text(
                        connection.status,
                        style: const TextStyle(
                          color: _Dark.yellow,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _connections.removeAt(index));
                    unawaited(_saveConnections());
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF7182),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showConnectDialog() {
    final label = TextEditingController(text: 'Binance main');
    final apiKey = TextEditingController();
    final secret = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Connect Binance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: apiKey,
              decoration: const InputDecoration(labelText: 'API key'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: secret,
              decoration: const InputDecoration(labelText: 'Secret key'),
              obscureText: true,
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
              final valid =
                  apiKey.text.trim().length >= 8 &&
                  secret.text.trim().length >= 8;
              setState(() {
                _connections.insert(
                  0,
                  _ExchangeConnection(
                    exchange: 'Binance',
                    label: label.text.trim().isEmpty
                        ? 'Binance account'
                        : label.text.trim(),
                    status: valid ? 'Validated locally' : 'Needs valid keys',
                  ),
                );
              });
              unawaited(_saveConnections());
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    setState(() {
      _connections
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, Object?>>()
              .map(_ExchangeConnection.fromJson)
              .whereType<_ExchangeConnection>(),
        );
    });
  }

  Future<void> _saveConnections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _connections.map((connection) => connection.toJson()).toList(),
      ),
    );
  }
}

class _ExchangeConnection {
  const _ExchangeConnection({
    required this.exchange,
    required this.label,
    required this.status,
  });

  final String exchange;
  final String label;
  final String status;

  Map<String, Object?> toJson() => {
    'exchange': exchange,
    'label': label,
    'status': status,
  };

  static _ExchangeConnection? fromJson(Map<String, Object?> json) {
    final exchange = json['exchange']?.toString();
    if (exchange == null || exchange.isEmpty) return null;
    return _ExchangeConnection(
      exchange: exchange,
      label: json['label']?.toString() ?? exchange,
      status: json['status']?.toString() ?? 'Read-only',
    );
  }
}

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const yellow = Color(0xFFF0B90B);
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
