part of '../screens/trending_wallets_screen.dart';

class _TrendingTopBar extends StatelessWidget {
  const _TrendingTopBar({
    required this.query,
    required this.onBack,
    required this.onRefresh,
    required this.onChanged,
  });

  final TextEditingController query;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Dark.surface,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _Dark.textPrimary,
          ),
          Expanded(
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: query,
                onChanged: onChanged,
                style: _Dark.body,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _Dark.surfaceVariant,
                  hintText: 'Explore any address',
                  hintStyle: _Dark.sub,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: _Dark.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _TrendingWalletRow extends StatelessWidget {
  const _TrendingWalletRow({required this.wallet, required this.onTap});

  final TrendingWallet wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            WalletAvatar(
              chain: wallet.chain,
              seed: wallet.avatarSeed,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.displayName,
                    style: _Dark.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(wallet.chain.label, style: _Dark.sub),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  wallet.valueUsd == null
                      ? 'Syncing'
                      : formatCompactUsd(wallet.valueUsd!),
                  style: _Dark.rowValue.copyWith(
                    color: wallet.isPositive ? AppColors.green : AppColors.red,
                  ),
                ),
                const SizedBox(height: 4),
                ChangePill(percent: wallet.changePercent24h),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
