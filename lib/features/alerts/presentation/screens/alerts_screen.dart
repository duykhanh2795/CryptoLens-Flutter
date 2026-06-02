import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/alerts/domain/alert_rule.dart';
import 'package:cryptolens_flutter/core/services/alert_realtime_service.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

import 'package:cryptolens_flutter/features/alerts/presentation/widgets/alert_common_widgets.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/widgets/alert_create_sheet.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/widgets/alert_tile.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({required this.controller, this.prefill, super.key});

  final MarketController controller;
  final AlertCoinPrefill? prefill;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class AlertCoinPrefill {
  const AlertCoinPrefill({required this.coin, required this.metric});

  final Coin coin;
  final AlertMetric metric;
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const _storageKey = 'cryptolens.alerts.rules';

  final List<AlertRule> _rules = [];
  final Set<String> _notifiedRuleIds = {};
  Timer? _refreshTimer;
  bool _shownPrefill = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleMarketUpdate);
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || widget.controller.isRefreshing) return;
      unawaited(widget.controller.refresh());
    });
    unawaited(_loadRules());
    if (widget.prefill != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _shownPrefill) return;
        _shownPrefill = true;
        _showCreateDialog(prefill: widget.prefill);
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    widget.controller.removeListener(_handleMarketUpdate);
    super.dispose();
  }

  void _handleMarketUpdate() {
    if (!mounted) return;
    setState(() {});
    _checkTriggeredRules();
  }

  @override
  Widget build(BuildContext context) {
    return DarkScaffold(
      title: 'Alerts',
      action: IconButton(
        tooltip: 'Create alert',
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add_rounded, color: AlertColors.yellow),
      ),
      child: _rules.isEmpty
          ? const EmptyPanel(
              icon: Icons.notifications_none_rounded,
              title: 'No alerts yet',
              message: 'Create a price, volume, or market cap rule.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              itemCount: _rules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rule = _rules[index];
                final liveCoin = widget.controller.coins.firstWhere(
                  (coin) => coin.id == rule.coin.id,
                  orElse: () => rule.coin,
                );
                return AlertTile(
                  rule: rule,
                  liveCoin: liveCoin,
                  onToggle: (enabled) {
                    setState(() {
                      rule.enabled = enabled;
                      rule.status = enabled
                          ? AlertStatus.active
                          : AlertStatus.paused;
                      if (enabled) _notifiedRuleIds.remove(rule.id);
                    });
                    unawaited(_saveRules());
                    unawaited(AlertRealtimeService.runImmediateCheck());
                  },
                  onDelete: () {
                    setState(() => _rules.removeAt(index));
                    unawaited(_saveRules());
                  },
                );
              },
            ),
    );
  }

  void _showCreateDialog({AlertCoinPrefill? prefill}) {
    final coins = <Coin>[
      if (prefill != null) prefill.coin,
      ...widget.controller.coins
          .where((coin) => coin.id != prefill?.coin.id)
          .take(40),
    ];
    if (coins.isEmpty) {
      _message('Market data is still loading.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AlertColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => CreateAlertSheet(
        coins: coins,
        initialCoin: prefill?.coin,
        initialMetric: prefill?.metric,
        onCreate: (rule) {
          setState(() => _rules.insert(0, rule));
          unawaited(_saveRules());
          unawaited(AlertRealtimeService.runImmediateCheck());
          _message('Alert created for ${rule.coin.symbol}.');
        },
      ),
    );
  }

  Future<void> _loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    setState(() {
      _rules
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, Object?>>()
              .map(AlertRule.fromJson)
              .whereType<AlertRule>(),
        );
    });
  }

  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rules.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(
        _storageKey,
        jsonEncode(_rules.map((rule) => rule.toJson()).toList()),
      );
    }
    unawaited(AlertRealtimeService.schedulePeriodicCheck());
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void _checkTriggeredRules() {
    for (final rule in _rules) {
      if (!rule.enabled || _notifiedRuleIds.contains(rule.id)) continue;
      if (rule.status != AlertStatus.active) continue;
      final liveCoin = widget.controller.coins.firstWhere(
        (coin) => coin.id == rule.coin.id,
        orElse: () => rule.coin,
      );
      final current = rule.metric.valueOf(liveCoin);
      final triggered = rule.isTriggered(current);
      if (!triggered) continue;
      _notifiedRuleIds.add(rule.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${liveCoin.symbol} ${rule.metric.label} triggered at ${rule.metric.format(current)}',
          ),
        ),
      );
    }
  }
}
