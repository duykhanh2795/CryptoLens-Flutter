part of '../screens/portfolio_screen.dart';

class _PortfolioTabs extends StatelessWidget {
  const _PortfolioTabs({required this.selectedTab, required this.onChanged});

  final _PortfolioTab selectedTab;
  final ValueChanged<_PortfolioTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111112),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PortfolioTabButton(
            label: 'Assets',
            selected: selectedTab == _PortfolioTab.assets,
            onTap: () => onChanged(_PortfolioTab.assets),
          ),
          _PortfolioTabButton(
            label: 'Transactions',
            selected: selectedTab == _PortfolioTab.transactions,
            onTap: () => onChanged(_PortfolioTab.transactions),
          ),
        ],
      ),
    );
  }
}

class _PortfolioTabButton extends StatelessWidget {
  const _PortfolioTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 2,
              color: selected ? AppColors.textPrimary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetsTab extends StatelessWidget {
  const _AssetsTab({
    required this.assets,
    required this.onCoinTap,
    required this.onDelete,
  });

  final List<PortfolioAsset> assets;
  final ValueChanged<PortfolioAsset> onCoinTap;
  final ValueChanged<PortfolioAsset> onDelete;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const _PortfolioEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No assets yet',
        message: 'Tap + to record your first buy.',
      );
    }

    final total = assets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentValue,
    );
    return Column(
      children: [
        for (final asset in assets)
          _AssetRow(
            asset: asset,
            allocation: total <= 0 ? 0 : asset.currentValue / total * 100,
            onTap: () => onCoinTap(asset),
            onDelete: () => onDelete(asset),
          ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.allocation,
    required this.onTap,
    required this.onDelete,
  });

  final PortfolioAsset asset;
  final double allocation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isProfit = asset.unrealizedPnl >= 0;
    final coin = asset.coin;
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                coin.imageUrl,
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.currency_bitcoin, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Qty: ${_trim(asset.quantity)}',
                    style: _assetMetaStyle(AppColors.textSecondary),
                  ),
                  Text(
                    'Avg: ${formatPrice(asset.averagePrice)}',
                    style: _assetMetaStyle(AppColors.textTertiary),
                  ),
                  Text(
                    '${allocation.toStringAsFixed(1)}% allocation',
                    style: _assetMetaStyle(AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(asset.currentValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _signedMoney(asset.unrealizedPnl),
                  style: TextStyle(
                    color: isProfit ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '(${formatPercent(asset.unrealizedPnlPercent)})',
                  style: TextStyle(
                    color: isProfit ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '24h ${_signedMoney(coin.priceChange24h * asset.quantity)}',
                  style: TextStyle(
                    color: coin.priceChange24h >= 0
                        ? AppColors.green
                        : AppColors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.transactions, required this.onDelete});

  final List<PortfolioTransaction> transactions;
  final ValueChanged<PortfolioTransaction> onDelete;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const _PortfolioEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions',
        message: 'Your buy/sell history will appear here.',
      );
    }
    return Column(
      children: [
        for (final tx in transactions)
          _TransactionRow(transaction: tx, onDelete: () => onDelete(tx)),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.onDelete});

  final PortfolioTransaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction.type == PortfolioTransactionType.buy;
    return InkWell(
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isBuy
                  ? AppColors.greenSurface
                  : AppColors.redSurface,
              child: Icon(
                isBuy ? Icons.add_rounded : Icons.remove_rounded,
                color: isBuy ? AppColors.green : AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: transaction.type.label,
                          style: TextStyle(
                            color: isBuy ? AppColors.green : AppColors.red,
                          ),
                        ),
                        TextSpan(text: ' ${transaction.coin.symbol}'),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(transaction.timestamp),
                    style: _assetMetaStyle(AppColors.textTertiary),
                  ),
                  if (transaction.note.isNotEmpty)
                    Text(
                      transaction.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _assetMetaStyle(AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_trim(transaction.quantity)} ${transaction.coin.symbol}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '@ ${formatPrice(transaction.price)}',
                  style: _assetMetaStyle(AppColors.textSecondary),
                ),
                Text(
                  formatPrice(transaction.total),
                  style: TextStyle(
                    color: isBuy ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
