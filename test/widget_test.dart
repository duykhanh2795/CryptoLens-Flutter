import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats signed percent values', () {
    expect(formatPercent(1.234), '+1.23%');
    expect(formatPercent(-2), '-2.00%');
    expect(formatPercent(0), '0.00%');
  });
}
