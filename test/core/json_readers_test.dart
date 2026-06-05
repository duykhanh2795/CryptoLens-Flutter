import 'package:flutter_test/flutter_test.dart';

import 'package:cryptolens_flutter/core/utils/json_readers.dart';

enum _ReaderTestEnum { priceLimit, marketCap }

void main() {
  group('json readers', () {
    test('reads primitive values with fallbacks', () {
      expect(readDouble('12.5'), 12.5);
      expect(readDouble('bad', fallback: 7), 7);
      expect(readInt('42'), 42);
      expect(readInt(null, fallback: 9), 9);
      expect(readString(null, fallback: 'n/a'), 'n/a');
      expect(readString(123), '123');
    });

    test('reads maps, lists, dates, and normalized enum names', () {
      final millis = DateTime(2026, 1, 2).millisecondsSinceEpoch;

      expect(readObjectMap({'a': 1})['a'], 1);
      expect(readObjectList([1, 2]), [1, 2]);
      expect(readDateTime(millis).millisecondsSinceEpoch, millis);
      expect(readDateTime('2026-01-02').year, 2026);
      expect(
        readEnum(_ReaderTestEnum.values, 'market_cap'),
        _ReaderTestEnum.marketCap,
      );
      expect(
        readEnum(_ReaderTestEnum.values, 'priceLimit'),
        _ReaderTestEnum.priceLimit,
      );
    });
  });
}
