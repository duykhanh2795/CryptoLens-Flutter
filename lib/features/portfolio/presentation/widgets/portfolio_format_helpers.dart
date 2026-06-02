import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';

TextStyle portfolioAssetMetaStyle(Color color) {
  return TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700);
}

String signedPortfolioMoney(double value) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${formatPrice(value.abs())}';
}

String trimPortfolioValue(double value) {
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
