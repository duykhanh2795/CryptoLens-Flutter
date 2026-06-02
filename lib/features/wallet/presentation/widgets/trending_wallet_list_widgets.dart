import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_colors.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_visual_painters.dart';

class TrendingTopBar extends StatelessWidget {
  const TrendingTopBar({
    required this.query,
    required this.onBack,
    required this.onRefresh,
    required this.onChanged,
    super.key,
  });

  final TextEditingController query;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WalletColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: WalletColors.textPrimary,
          ),
          Expanded(
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: query,
                onChanged: onChanged,
                style: WalletColors.body,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: WalletColors.surfaceVariant,
                  hintText: 'Explore any address',
                  hintStyle: WalletColors.sub,
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
            color: WalletColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class TrendingWalletRow extends StatelessWidget {
  const TrendingWalletRow({
    required this.wallet,
    required this.onTap,
    super.key,
  });

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
                    style: WalletColors.rowTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(wallet.chain.label, style: WalletColors.sub),
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
                  style: WalletColors.rowValue.copyWith(
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
