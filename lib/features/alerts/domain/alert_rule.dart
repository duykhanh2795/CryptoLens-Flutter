import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

enum AlertMetric { price, volume, marketCap }

enum AlertDirection { above, below }

enum AlertValueType { number, percent }

enum AlertFrequency { oneTime, persistent }

enum AlertStatus { active, triggered, paused }

class AlertRule {
  AlertRule({
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

  static AlertRule? fromJson(Map<String, Object?> json) {
    final coinJson = json['coin'];
    if (coinJson is! Map) return null;
    final coin = _coinFromJson(coinJson.cast<String, Object?>());
    if (coin == null) return null;
    final metric = _enumByName(AlertMetric.values, json['metric']);
    final direction = _enumByName(AlertDirection.values, json['direction']);
    if (metric == null || direction == null) return null;
    final enabled = json['enabled'] == true;
    final status = _statusFromJson(json['status'], enabled: enabled);
    return AlertRule(
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

extension AlertMetricX on AlertMetric {
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

extension AlertDirectionX on AlertDirection {
  String get label => switch (this) {
    AlertDirection.above => 'Above',
    AlertDirection.below => 'Below',
  };
}

extension AlertFrequencyX on AlertFrequency {
  String get label => switch (this) {
    AlertFrequency.oneTime => 'One Time',
    AlertFrequency.persistent => 'Persistent',
  };
}

extension AlertStatusX on AlertStatus {
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
