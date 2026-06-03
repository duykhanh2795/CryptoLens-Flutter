import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'package:cryptolens_flutter/core/constants/storage_keys.dart';
import 'package:cryptolens_flutter/core/network/api_client.dart';
import 'package:cryptolens_flutter/core/storage/json_preferences_store.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/core/utils/json_readers.dart';
import 'firebase_messaging_service.dart';

@pragma('vm:entry-point')
void cryptolensAlertWorkDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    return AlertRealtimeService.runAlertCheck();
  });
}

class AlertRealtimeService {
  AlertRealtimeService._();

  static const storageKey = StorageKeys.alertsRules;
  static const _ruleStore = JsonPreferencesStore(storageKey);
  static const periodicWorkName = 'price_alert_check';
  static const immediateWorkName = 'price_alert_check_immediate';
  static const taskName = 'cryptolens_alert_check';

  static Future<void> initialize() async {
    await Workmanager().initialize(cryptolensAlertWorkDispatcher);
    await schedulePeriodicCheck();
  }

  static Future<void> schedulePeriodicCheck() {
    return Workmanager().registerPeriodicTask(
      periodicWorkName,
      taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> runImmediateCheck() {
    return Workmanager().registerOneOffTask(
      immediateWorkName,
      taskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<bool> runAlertCheck({http.Client? client}) async {
    final decoded = await _ruleStore.load();
    if (decoded is! List) return true;

    final rules = decoded
        .whereType<Map>()
        .map((json) => _StoredAlertRule.fromJson(json.cast<String, Object?>()))
        .whereType<_StoredAlertRule>()
        .toList();
    final activeRules = rules.where((rule) => rule.isActive).toList();
    if (activeRules.isEmpty) return true;

    final values = await _fetchMarketValues(activeRules, client: client);
    var changed = false;
    for (final rule in activeRules) {
      final market = values[rule.coinId];
      if (market == null) continue;
      final current = rule.metric.valueOf(market);
      if (current <= 0 || !rule.isTriggered(current)) continue;

      await CryptoFirebaseMessagingService.showNotification(
        title: '${rule.symbol} ${rule.metric.label} alert triggered',
        body: rule.notificationBody(current),
        notificationId: rule.id.hashCode,
      );
      rule.markTriggered(current);
      changed = true;
    }

    if (changed) {
      await _ruleStore.save(rules.map((rule) => rule.toJson()).toList());
    }
    return true;
  }

  static Future<Map<String, _MarketValue>> _fetchMarketValues(
    List<_StoredAlertRule> rules, {
    http.Client? client,
  }) async {
    final ids = rules
        .map((rule) => rule.coinId)
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return const {};
    final httpClient = client ?? http.Client();
    final ownedClient = client == null;
    final apiClient = ApiClient(client: httpClient);
    try {
      final result = <String, _MarketValue>{};
      final chunks = ids.toList();
      for (var start = 0; start < chunks.length; start += 250) {
        final end = start + 250 > chunks.length ? chunks.length : start + 250;
        final batch = chunks.sublist(start, end);
        final uri = Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
          'vs_currency': 'usd',
          'ids': batch.join(','),
          'per_page': '${batch.length}',
          'precision': 'full',
        });
        final response = await apiClient.getJson(
          uri,
          label: 'CoinGecko alert markets',
          throwOnHttpError: false,
        );
        if (!ApiClient.isSuccessStatus(response.statusCode)) continue;
        final body = response.data;
        if (body is! List) continue;
        for (final item in body.whereType<Map<String, dynamic>>()) {
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          result[id] = _MarketValue(
            price: readDouble(item['current_price']),
            volume24h: readDouble(item['total_volume']),
            marketCap: readDouble(item['market_cap']),
          );
        }
      }
      return result;
    } finally {
      if (ownedClient) apiClient.close();
    }
  }
}

class _StoredAlertRule {
  _StoredAlertRule({
    required this.raw,
    required this.id,
    required this.coinId,
    required this.symbol,
    required this.name,
    required this.metric,
    required this.direction,
    required this.target,
    required this.enabled,
    required this.frequency,
    required this.valueType,
    required this.baselineValue,
  });

  final Map<String, Object?> raw;
  final String id;
  final String coinId;
  final String symbol;
  final String name;
  final _AlertMetric metric;
  final _AlertDirection direction;
  final double target;
  bool enabled;
  final _AlertFrequency frequency;
  final _AlertValueType valueType;
  double baselineValue;

  bool get isActive =>
      enabled && raw['status'] != 'TRIGGERED' && raw['status'] != 'PAUSED';

  static _StoredAlertRule? fromJson(Map<String, Object?> json) {
    final coin = (json['coin'] as Map?)?.cast<String, Object?>();
    final coinId = coin?['id']?.toString() ?? json['coinId']?.toString() ?? '';
    if (coinId.isEmpty) return null;
    final metric = _AlertMetric.from(json['metric'] ?? json['type']);
    final direction = _AlertDirection.from(
      json['direction'] ?? json['condition'],
    );
    if (metric == null || direction == null) return null;
    return _StoredAlertRule(
      raw: Map<String, Object?>.from(json),
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      coinId: coinId,
      symbol:
          coin?['symbol']?.toString() ?? json['symbol']?.toString() ?? coinId,
      name: coin?['name']?.toString() ?? json['name']?.toString() ?? coinId,
      metric: metric,
      direction: direction,
      target: readDouble(json['target'] ?? json['targetPrice']),
      enabled: json['enabled'] != false,
      frequency: _AlertFrequency.from(json['frequency']),
      valueType: _AlertValueType.from(json['valueType']),
      baselineValue: readDouble(json['baselineValue']),
    );
  }

  double thresholdValue() {
    if (valueType == _AlertValueType.percent && baselineValue > 0) {
      return switch (direction) {
        _AlertDirection.above => baselineValue * (1 + target / 100),
        _AlertDirection.below => baselineValue * (1 - target / 100),
      };
    }
    return target;
  }

  bool isTriggered(double current) {
    if (current <= 0) return false;
    if (valueType == _AlertValueType.percent && baselineValue <= 0) {
      return false;
    }
    final threshold = thresholdValue();
    return switch (direction) {
      _AlertDirection.above => current >= threshold,
      _AlertDirection.below => current <= threshold,
    };
  }

  void markTriggered(double current) {
    raw['triggeredAt'] = DateTime.now().millisecondsSinceEpoch;
    if (frequency == _AlertFrequency.persistent) {
      baselineValue = current;
      raw['baselineValue'] = current;
      raw['enabled'] = true;
      raw['status'] = 'ACTIVE';
      enabled = true;
    } else {
      raw['enabled'] = false;
      raw['status'] = 'TRIGGERED';
      enabled = false;
    }
  }

  String notificationBody(double current) {
    final targetLabel = valueType == _AlertValueType.percent
        ? '${direction.movementLabel.toLowerCase()} ${target.toStringAsFixed(2)}%'
        : '${direction.label.toLowerCase()} ${metric.format(target)}';
    return '$name ${metric.label} $targetLabel. Current: ${metric.format(current)}'
        '${frequency == _AlertFrequency.persistent ? ' (persistent)' : ''}';
  }

  Map<String, Object?> toJson() => raw;
}

class _MarketValue {
  const _MarketValue({
    required this.price,
    required this.volume24h,
    required this.marketCap,
  });

  final double price;
  final double volume24h;
  final double marketCap;
}

enum _AlertMetric {
  price('Price Limit'),
  volume('Volume'),
  marketCap('Market Cap');

  const _AlertMetric(this.label);

  final String label;

  static _AlertMetric? from(Object? value) {
    return switch (value?.toString()) {
      'price' || 'PRICE_LIMIT' => _AlertMetric.price,
      'volume' || 'VOLUME' => _AlertMetric.volume,
      'marketCap' || 'MARKET_CAP' => _AlertMetric.marketCap,
      _ => null,
    };
  }

  double valueOf(_MarketValue value) => switch (this) {
    _AlertMetric.price => value.price,
    _AlertMetric.volume => value.volume24h,
    _AlertMetric.marketCap => value.marketCap,
  };

  String format(double value) =>
      this == _AlertMetric.price ? formatPrice(value) : formatCompactUsd(value);
}

enum _AlertDirection {
  above('Above', 'Increases'),
  below('Below', 'Decreases');

  const _AlertDirection(this.label, this.movementLabel);

  final String label;
  final String movementLabel;

  static _AlertDirection? from(Object? value) {
    return switch (value?.toString()) {
      'above' || 'ABOVE' => _AlertDirection.above,
      'below' || 'BELOW' => _AlertDirection.below,
      _ => null,
    };
  }
}

enum _AlertValueType {
  number,
  percent;

  static _AlertValueType from(Object? value) {
    return value?.toString() == 'PERCENT'
        ? _AlertValueType.percent
        : _AlertValueType.number;
  }
}

enum _AlertFrequency {
  oneTime,
  persistent;

  static _AlertFrequency from(Object? value) {
    return value?.toString() == 'PERSISTENT'
        ? _AlertFrequency.persistent
        : _AlertFrequency.oneTime;
  }
}
