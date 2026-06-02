import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/coin.dart';
import '../../core/services/alert_realtime_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../market/market_controller.dart';

enum AlertMetric { price, volume, marketCap }

enum AlertDirection { above, below }

enum AlertValueType { number, percent }

enum AlertFrequency { oneTime, persistent }

enum AlertStatus { active, triggered, paused }

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

  final List<_AlertRule> _rules = [];
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
    return _DarkScaffold(
      title: 'Alerts',
      action: IconButton(
        tooltip: 'Create alert',
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add_rounded, color: _Dark.yellow),
      ),
      child: _rules.isEmpty
          ? const _EmptyPanel(
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
                return _AlertTile(
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
      backgroundColor: _Dark.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _CreateAlertSheet(
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
              .map(_AlertRule.fromJson)
              .whereType<_AlertRule>(),
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

class _CreateAlertSheet extends StatefulWidget {
  const _CreateAlertSheet({
    required this.coins,
    required this.onCreate,
    this.initialCoin,
    this.initialMetric,
  });

  final List<Coin> coins;
  final ValueChanged<_AlertRule> onCreate;
  final Coin? initialCoin;
  final AlertMetric? initialMetric;

  @override
  State<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends State<_CreateAlertSheet> {
  late Coin _coin = widget.initialCoin ?? widget.coins.first;
  late AlertMetric _metric = widget.initialMetric ?? AlertMetric.price;
  AlertDirection _direction = AlertDirection.above;
  AlertValueType _valueType = AlertValueType.number;
  AlertFrequency _frequency = AlertFrequency.oneTime;
  final _target = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setDefaultTarget();
  }

  @override
  void dispose() {
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = double.tryParse(_target.text) ?? 0;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Alert', style: _Dark.title),
            const SizedBox(height: 16),
            DropdownButtonFormField<Coin>(
              initialValue: _coin,
              isExpanded: true,
              dropdownColor: _Dark.surface,
              decoration: const InputDecoration(labelText: 'Coin'),
              items: [
                for (final coin in widget.coins)
                  DropdownMenuItem(
                    value: coin,
                    child: Text(
                      '${coin.symbol} - ${coin.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (coin) {
                if (coin == null) return;
                setState(() {
                  _coin = coin;
                  _setDefaultTarget();
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AlertMetric>(
              initialValue: _metric,
              isExpanded: true,
              dropdownColor: _Dark.surface,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: AlertMetric.values
                  .map(
                    (metric) => DropdownMenuItem(
                      value: metric,
                      child: Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (metric) {
                if (metric == null) return;
                setState(() {
                  _metric = metric;
                  _setDefaultTarget();
                });
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<AlertValueType>(
              segments: const [
                ButtonSegment(
                  value: AlertValueType.number,
                  label: Text('Number'),
                ),
                ButtonSegment(
                  value: AlertValueType.percent,
                  label: Text('Percent'),
                ),
              ],
              selected: {_valueType},
              onSelectionChanged: (value) => setState(() {
                _valueType = value.first;
                _setDefaultTarget();
              }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AlertDirection>(
              segments: const [
                ButtonSegment(
                  value: AlertDirection.above,
                  label: Text('Above'),
                ),
                ButtonSegment(
                  value: AlertDirection.below,
                  label: Text('Below'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (value) =>
                  setState(() => _direction = value.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AlertFrequency>(
              segments: const [
                ButtonSegment(
                  value: AlertFrequency.oneTime,
                  label: Text('One Time'),
                ),
                ButtonSegment(
                  value: AlertFrequency.persistent,
                  label: Text('Persistent'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (value) =>
                  setState(() => _frequency = value.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _valueType == AlertValueType.percent
                    ? 'Target move (%)'
                    : 'Target ${_metric.unitLabel}',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Breakout alert',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _previewText(target),
              style: const TextStyle(
                color: _Dark.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: target <= 0
                    ? null
                    : () {
                        widget.onCreate(
                          _AlertRule(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            coin: _coin,
                            metric: _metric,
                            direction: _direction,
                            target: target,
                            baselineValue: _currentMetricValue(),
                            valueType: _valueType,
                            frequency: _frequency,
                            status: AlertStatus.active,
                            note: _note.text.trim(),
                            enabled: true,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                child: const Text('Create Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _currentMetricValue() => switch (_metric) {
    AlertMetric.price => _coin.currentPrice,
    AlertMetric.volume => _coin.volume24h,
    AlertMetric.marketCap => _coin.marketCap,
  };

  void _setDefaultTarget() {
    if (_valueType == AlertValueType.percent) {
      _target.text = '1';
      return;
    }
    final value = _currentMetricValue();
    _target.text = value > 0 ? value.toStringAsFixed(2) : '';
  }

  String _previewText(double target) {
    final baseline = _currentMetricValue();
    if (_valueType == AlertValueType.percent) {
      final threshold = _direction == AlertDirection.above
          ? baseline * (1 + target / 100)
          : baseline * (1 - target / 100);
      return 'Baseline ${_metric.format(baseline)} -> trigger at ${_metric.format(threshold)}';
    }
    return 'Current ${_metric.format(baseline)}';
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.rule,
    required this.liveCoin,
    required this.onToggle,
    required this.onDelete,
  });

  final _AlertRule rule;
  final Coin liveCoin;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final current = rule.metric.valueOf(liveCoin);
    final triggered = rule.isTriggered(current);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              liveCoin.imageUrl,
              width: 38,
              height: 38,
              errorBuilder: (_, _, _) => const CircleAvatar(
                backgroundColor: _Dark.surfaceVariant,
                child: Icon(Icons.currency_bitcoin),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rule.coin.symbol} ${rule.metric.label}',
                  style: _Dark.rowTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  rule.targetLabel,
                  style: const TextStyle(
                    color: _Dark.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Current ${rule.metric.format(current)}',
                  style: TextStyle(
                    color: triggered ? AppColors.green : _Dark.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (rule.status != AlertStatus.active || rule.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      [
                        if (rule.status != AlertStatus.active)
                          rule.status.label,
                        rule.frequency.label,
                        if (rule.note.isNotEmpty) rule.note,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _Dark.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: rule.enabled,
            onChanged: onToggle,
            activeTrackColor: _Dark.yellow,
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRule {
  _AlertRule({
    required this.id,
    required this.coin,
    required this.metric,
    required this.direction,
    required this.target,
    required this.baselineValue,
    required this.valueType,
    required this.frequency,
    required this.status,
    required this.note,
    required this.enabled,
  });

  final String id;
  final Coin coin;
  final AlertMetric metric;
  final AlertDirection direction;
  final double target;
  final double baselineValue;
  final AlertValueType valueType;
  final AlertFrequency frequency;
  AlertStatus status;
  final String note;
  bool enabled;

  Map<String, Object?> toJson() => {
    'id': id,
    'coin': _coinToJson(coin),
    'metric': metric.name,
    'direction': direction.name,
    'target': target,
    'baselineValue': baselineValue,
    'valueType': valueType.name,
    'frequency': frequency.name,
    'status': status.storageName,
    'note': note,
    'enabled': enabled,
  };

  double thresholdValue() {
    if (valueType != AlertValueType.percent || baselineValue <= 0) {
      return target;
    }
    return switch (direction) {
      AlertDirection.above => baselineValue * (1 + target / 100),
      AlertDirection.below => baselineValue * (1 - target / 100),
    };
  }

  bool isTriggered(double current) {
    if (current <= 0) return false;
    if (valueType == AlertValueType.percent && baselineValue <= 0) {
      return false;
    }
    final threshold = thresholdValue();
    return switch (direction) {
      AlertDirection.above => current >= threshold,
      AlertDirection.below => current <= threshold,
    };
  }

  String get targetLabel {
    if (valueType == AlertValueType.percent) {
      return '${direction.label} ${target.toStringAsFixed(2)}% from ${metric.format(baselineValue)}';
    }
    return '${direction.label} ${metric.format(target)}';
  }

  static _AlertRule? fromJson(Map<String, Object?> json) {
    final coinJson = json['coin'];
    if (coinJson is! Map) return null;
    final coin = _coinFromJson(coinJson.cast<String, Object?>());
    if (coin == null) return null;
    final metric = _enumByName(AlertMetric.values, json['metric']);
    final direction = _enumByName(AlertDirection.values, json['direction']);
    if (metric == null || direction == null) return null;
    final enabled = json['enabled'] == true;
    final status = _statusFromJson(json['status'], enabled: enabled);
    return _AlertRule(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      coin: coin,
      metric: metric,
      direction: direction,
      target: (json['target'] as num?)?.toDouble() ?? 0,
      baselineValue: (json['baselineValue'] as num?)?.toDouble() ?? 0,
      valueType:
          _enumByName(AlertValueType.values, json['valueType']) ??
          AlertValueType.number,
      frequency:
          _enumByName(AlertFrequency.values, json['frequency']) ??
          AlertFrequency.oneTime,
      status: status,
      note: json['note']?.toString() ?? '',
      enabled: enabled && status == AlertStatus.active,
    );
  }
}

extension on AlertMetric {
  String get label => switch (this) {
    AlertMetric.price => 'Price Limit',
    AlertMetric.volume => 'Volume',
    AlertMetric.marketCap => 'Market Cap',
  };

  String get unitLabel => this == AlertMetric.price ? '(USD)' : '(USD)';

  double valueOf(Coin coin) => switch (this) {
    AlertMetric.price => coin.currentPrice,
    AlertMetric.volume => coin.volume24h,
    AlertMetric.marketCap => coin.marketCap,
  };

  String format(double value) =>
      this == AlertMetric.price ? formatPrice(value) : formatCompactUsd(value);
}

extension on AlertDirection {
  String get label => switch (this) {
    AlertDirection.above => 'Above',
    AlertDirection.below => 'Below',
  };
}

extension on AlertFrequency {
  String get label => switch (this) {
    AlertFrequency.oneTime => 'One Time',
    AlertFrequency.persistent => 'Persistent',
  };
}

extension on AlertStatus {
  String get label => switch (this) {
    AlertStatus.active => 'Active',
    AlertStatus.triggered => 'Triggered',
    AlertStatus.paused => 'Paused',
  };

  String get storageName => switch (this) {
    AlertStatus.active => 'ACTIVE',
    AlertStatus.triggered => 'TRIGGERED',
    AlertStatus.paused => 'PAUSED',
  };
}

AlertStatus _statusFromJson(Object? value, {required bool enabled}) {
  return switch (value?.toString().toUpperCase()) {
    'ACTIVE' => AlertStatus.active,
    'TRIGGERED' => AlertStatus.triggered,
    'PAUSED' => AlertStatus.paused,
    _ => enabled ? AlertStatus.active : AlertStatus.paused,
  };
}

Map<String, Object?> _coinToJson(Coin coin) => {
  'id': coin.id,
  'symbol': coin.symbol,
  'name': coin.name,
  'imageUrl': coin.imageUrl,
  'currentPrice': coin.currentPrice,
  'priceChangePercent24h': coin.priceChangePercent24h,
  'priceChange24h': coin.priceChange24h,
  'marketCap': coin.marketCap,
  'volume24h': coin.volume24h,
  'high24h': coin.high24h,
  'low24h': coin.low24h,
  'circulatingSupply': coin.circulatingSupply,
  'rank': coin.rank,
  'lastUpdated': coin.lastUpdated.millisecondsSinceEpoch,
};

Coin? _coinFromJson(Map<String, Object?> json) {
  final id = json['id']?.toString();
  if (id == null || id.isEmpty) return null;
  return Coin(
    id: id,
    symbol: json['symbol']?.toString() ?? '',
    name: json['name']?.toString() ?? id,
    imageUrl: json['imageUrl']?.toString() ?? '',
    currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
    priceChangePercent24h:
        (json['priceChangePercent24h'] as num?)?.toDouble() ?? 0,
    priceChange24h: (json['priceChange24h'] as num?)?.toDouble() ?? 0,
    marketCap: (json['marketCap'] as num?)?.toDouble() ?? 0,
    volume24h: (json['volume24h'] as num?)?.toDouble() ?? 0,
    high24h: (json['high24h'] as num?)?.toDouble() ?? 0,
    low24h: (json['low24h'] as num?)?.toDouble() ?? 0,
    circulatingSupply: (json['circulatingSupply'] as num?)?.toDouble() ?? 0,
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(
      (json['lastUpdated'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    ),
  );
}

T? _enumByName<T extends Enum>(Iterable<T> values, Object? name) {
  final normalized = name?.toString().replaceAll('_', '').toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == normalized) return value;
  }
  return null;
}

class _DarkScaffold extends StatelessWidget {
  const _DarkScaffold({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Dark.background,
      appBar: AppBar(
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
        title: Text(title),
        actions: [?action],
      ),
      body: child,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _Dark.textTertiary, size: 64),
            const SizedBox(height: 16),
            Text(title, style: _Dark.title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: _Dark.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
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
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
  static const title = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const rowTitle = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );
}
