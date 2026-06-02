import 'package:cryptolens_flutter/core/utils/formatters.dart';

String signedHomeMoney(double value) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${formatPrice(value.abs())}';
}

String formatSignedPriceDelta(double value) {
  final absolute = value.abs();
  final formatted = formatPrice(absolute);
  return '${value >= 0 ? '+' : '-'}${formatted.replaceFirst(r'$', r'$')}';
}
