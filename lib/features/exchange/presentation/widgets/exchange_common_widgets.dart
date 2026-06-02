part of '../screens/manage_exchange_screen.dart';

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.result});

  final SyncResult? result;

  @override
  Widget build(BuildContext context) {
    final syncResult = result;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Dark.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        syncResult == null
            ? 'Read-only exchange sync imports trades into your local Portfolio.'
            : 'Last sync imported ${syncResult.tradesImported} trades and skipped ${syncResult.tradesSkipped} duplicates.',
        style: const TextStyle(
          color: _Dark.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const yellow = Color(0xFFF0B90B);
  static const hero = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const title = TextStyle(
    color: textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );
  static const sub = TextStyle(
    color: textSecondary,
    fontWeight: FontWeight.w700,
  );
}
