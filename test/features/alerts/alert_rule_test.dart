import 'package:flutter_test/flutter_test.dart';

import 'package:cryptolens_flutter/features/alerts/domain/alert_rule.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

void main() {
  group('AlertRule', () {
    final coin = Coin.snapshot(
      id: 'bitcoin',
      symbol: 'BTC',
      name: 'Bitcoin',
      imageUrl: '',
      currentPrice: 73000,
    );

    test('triggers number thresholds in the selected direction', () {
      final rule = AlertRule(
        id: 'rule_1',
        coin: coin,
        metric: AlertMetric.price,
        direction: AlertDirection.above,
        target: 74000,
        baselineValue: 73000,
        valueType: AlertValueType.number,
        frequency: AlertFrequency.oneTime,
        status: AlertStatus.active,
        note: '',
        enabled: true,
      );

      expect(rule.isTriggered(73999), isFalse);
      expect(rule.isTriggered(74000), isTrue);
    });

    test('calculates percent thresholds from baseline', () {
      final rule = AlertRule(
        id: 'rule_2',
        coin: coin,
        metric: AlertMetric.price,
        direction: AlertDirection.below,
        target: 10,
        baselineValue: 100,
        valueType: AlertValueType.percent,
        frequency: AlertFrequency.oneTime,
        status: AlertStatus.active,
        note: '',
        enabled: true,
      );

      expect(rule.thresholdValue(), 90);
      expect(rule.isTriggered(91), isFalse);
      expect(rule.isTriggered(90), isTrue);
    });

    test('loads legacy storage enum names', () {
      final rule = AlertRule.fromJson({
        'id': 'rule_3',
        'coin': {
          'id': 'bitcoin',
          'symbol': 'BTC',
          'name': 'Bitcoin',
          'imageUrl': '',
          'currentPrice': 73000,
        },
        'metric': 'market_cap',
        'direction': 'above',
        'target': 1000000,
        'baselineValue': 900000,
        'valueType': 'number',
        'frequency': 'one_time',
        'status': 'ACTIVE',
        'enabled': true,
      });

      expect(rule, isNotNull);
      expect(rule!.metric, AlertMetric.marketCap);
      expect(rule.frequency, AlertFrequency.oneTime);
      expect(rule.enabled, isTrue);
    });
  });
}
