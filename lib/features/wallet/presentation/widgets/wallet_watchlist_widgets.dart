part of '../screens/wallet_watchlist_screen.dart';

class _WatchedWalletCard extends StatelessWidget {
  const _WatchedWalletCard({
    required this.wallet,
    required this.estimatedValue,
    required this.assetCount,
    required this.onDetails,
    required this.onDelete,
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
          color: _Dark.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wallet_rounded, color: _Dark.yellow),
                const SizedBox(width: 10),
                Expanded(child: Text(wallet.label, style: _Dark.title)),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
            Text(wallet.chain.label, style: _Dark.sub),
            const SizedBox(height: 4),
            Text(
              wallet.shortAddress,
              style: const TextStyle(
                color: _Dark.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(color: _Dark.surfaceVariant, height: 24),
            Row(
              children: [
                Expanded(
                  child: _WalletMetric(
                    label: 'Estimated',
                    value: formatPrice(estimatedValue),
                  ),
                ),
                Expanded(
                  child: _WalletMetric(label: 'Assets', value: '$assetCount'),
                ),
                const Expanded(
                  child: _WalletMetric(label: 'Status', value: 'Watching'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletMetric extends StatelessWidget {
  const _WalletMetric({required this.label, required this.value});

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
            color: _Dark.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _Dark.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Dark {
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
