import 'package:intl/intl.dart';

final _compact = NumberFormat.compactCurrency(symbol: r'$', decimalDigits: 2);
final _compactNumber = NumberFormat.compact();
final _money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _smallMoney = NumberFormat.currency(symbol: r'$', decimalDigits: 6);

String formatPrice(double value) {
  if (value == 0) return r'$0.00';
  if (value.abs() < 1) return _smallMoney.format(value);
  return _money.format(value);
}

String formatCompactUsd(double value) => _compact.format(value);

String formatCompactNumber(double value) => _compactNumber.format(value);

String formatPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}
