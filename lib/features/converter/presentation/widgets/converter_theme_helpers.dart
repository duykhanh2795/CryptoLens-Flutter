part of '../screens/converter_screen.dart';

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const green = Color(0xFF00C087);
  static const red = Color(0xFFF6465D);
  static const title = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const hero = TextStyle(
    color: textPrimary,
    fontSize: 32,
    fontWeight: FontWeight.w900,
  );
}

String _trim(double value) {
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
