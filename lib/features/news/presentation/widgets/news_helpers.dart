part of '../screens/news_screen.dart';

String _relativeTime(DateTime date) {
  final delta = DateTime.now().difference(date);
  if (delta.inMinutes < 1) return 'now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return '${(delta.inDays / 7).floor()}w ago';
}

extension on Iterable<String> {
  String joinToString(String separator) => join(separator);
}

class _NewsColors {
  static const background = Color(0xFF050607);
  static const surfaceElevated = Color(0xFF121419);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const divider = Color(0xFF222831);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
}
