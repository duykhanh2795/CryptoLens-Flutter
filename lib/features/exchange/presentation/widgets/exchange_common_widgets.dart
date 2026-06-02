import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/exchange/domain/exchange.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({required this.result, super.key});

  final SyncResult? result;

  @override
  Widget build(BuildContext context) {
    final syncResult = result;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ExchangeColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        syncResult == null
            ? 'Read-only exchange sync imports trades into your local Portfolio.'
            : 'Last sync imported ${syncResult.tradesImported} trades and skipped ${syncResult.tradesSkipped} duplicates.',
        style: const TextStyle(
          color: ExchangeColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ExchangeColors {
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
