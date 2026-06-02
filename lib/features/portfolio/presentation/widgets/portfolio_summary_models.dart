part of '../screens/portfolio_screen.dart';

TextStyle _assetMetaStyle(Color color) {
  return TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700);
}

String _signedMoney(double value) {
  final sign = value >= 0 ? '+' : '-';
  return '$sign${formatPrice(value.abs())}';
}

String _trim(double value) {
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
