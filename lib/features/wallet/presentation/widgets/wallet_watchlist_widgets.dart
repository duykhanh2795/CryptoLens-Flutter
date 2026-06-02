import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';

class WatchedWalletCard extends StatelessWidget {
  const WatchedWalletCard({
    required this.wallet,
    required this.estimatedValue,
    required this.assetCount,
    required this.onDetails,
    required this.onDelete,
    super.key,
  });

  final WatchedWallet wallet;
  final double estimatedValue;
  final int assetCount;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WalletWatchlistColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wallet_rounded,
                  color: WalletWatchlistColors.yellow,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(wallet.label, style: WalletWatchlistColors.title),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            Text(wallet.chain.label, style: WalletWatchlistColors.sub),
            const SizedBox(height: 4),
            Text(
              wallet.shortAddress,
              style: const TextStyle(
                color: WalletWatchlistColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(
              color: WalletWatchlistColors.surfaceVariant,
              height: 24,
            ),
            Row(
              children: [
                Expanded(
                  child: WalletMetric(
                    label: 'Estimated',
                    value: formatPrice(estimatedValue),
                  ),
                ),
                Expanded(
                  child: WalletMetric(label: 'Assets', value: '$assetCount'),
                ),
                const Expanded(
                  child: WalletMetric(label: 'Status', value: 'Watching'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WalletMetric extends StatelessWidget {
  const WalletMetric({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: WalletWatchlistColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: WalletWatchlistColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class WalletWatchlistColors {
  const WalletWatchlistColors._();

  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
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
