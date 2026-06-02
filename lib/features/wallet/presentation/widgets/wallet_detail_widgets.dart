part of '../screens/trending_wallets_screen.dart';

class _WalletDetailHero extends StatelessWidget {
  const _WalletDetailHero({
    required this.detail,
    required this.selectedTab,
    required this.isAdding,
    required this.isLoading,
    required this.onBack,
    required this.onAddToWatchlist,
    required this.onTabChanged,
  });

  final TrendingWalletDetail detail;
  final WalletDetailTab selectedTab;
  final bool isAdding;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onAddToWatchlist;
  final ValueChanged<WalletDetailTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final wallet = detail.wallet;
    final total = detail.totalValueUsd ?? wallet.valueUsd;
    return Container(
      color: _Dark.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 14, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: _Dark.textPrimary,
                ),
                const Text('USD', style: _Dark.topCurrency),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _Dark.surfaceVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(wallet.displayName, style: _Dark.topAddress),
                ),
                const Spacer(),
                WalletAvatar(
                  chain: wallet.chain,
                  seed: wallet.avatarSeed,
                  size: 42,
                ),
              ],
            ),
          ),
          Text(wallet.chain.label, style: _Dark.chainLabel),
          const SizedBox(height: 16),
          Text(
            total == null ? 'Value unavailable' : formatCompactUsd(total),
            style: _Dark.heroValue,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_formatNative(wallet.nativeBalance)} ${wallet.chain.nativeSymbol}',
                style: _Dark.sub,
              ),
              const SizedBox(width: 8),
              ChangePill(percent: wallet.changePercent24h),
              if (isLoading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _Dark.yellow,
                  ),
                ),
              ],
            ],
          ),
          WalletMiniChart(isPositive: wallet.isPositive),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isAdding ? null : onAddToWatchlist,
                    icon: const Icon(Icons.star_border_rounded, size: 18),
                    label: Text(isAdding ? 'Adding...' : 'Add to Watchlist'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Dark.textPrimary,
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: _Dark.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _Dark.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: _Dark.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text('${wallet.txCount} tx', style: _Dark.sub),
                    ],
                  ),
                ),
              ],
            ),
          ),
          WalletTabs(selectedTab: selectedTab, onChanged: onTabChanged),
        ],
      ),
    );
  }
}

class _AssetsTab extends StatelessWidget {
  const _AssetsTab({required this.detail});

  final TrendingWalletDetail detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (detail.historyNote != null)
          WalletInfoNotice(
            message: detail.historyNote!,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text('Qty. Total', style: _Dark.columnHeader)),
              Expanded(
                child: Text(
                  '24h',
                  style: _Dark.columnHeader,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Price',
                  style: _Dark.columnHeader,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        for (final asset in detail.assets) ...[
          AssetRow(asset: asset),
          const Divider(
            color: _Dark.divider,
            height: 1,
            indent: 76,
            endIndent: 20,
          ),
        ],
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.detail,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.onQueryChanged,
  });

  final TrendingWalletDetail detail;
  final TextEditingController query;
  final WalletHistoryFilter filter;
  final ValueChanged<WalletHistoryFilter> onFilterChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final needle = query.text.trim().toLowerCase();
    final filtered = detail.history.where((tx) {
      final matchesFilter = switch (filter) {
        WalletHistoryFilter.all => true,
        WalletHistoryFilter.received =>
          tx.type == WalletTransactionType.received,
        WalletHistoryFilter.sent => tx.type == WalletTransactionType.sent,
        WalletHistoryFilter.executed =>
          tx.type == WalletTransactionType.executed,
        WalletHistoryFilter.token =>
          tx.symbol != detail.wallet.chain.nativeSymbol,
      };
      final matchesQuery =
          needle.isEmpty ||
          tx.symbol.toLowerCase().contains(needle) ||
          tx.id.toLowerCase().contains(needle) ||
          (tx.counterparty ?? '').toLowerCase().contains(needle) ||
          tx.networkLabel.toLowerCase().contains(needle);
      return matchesFilter && matchesQuery;
    }).toList();
    final groups = _groupByDay(filtered);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        if (detail.historyNote != null)
          WalletInfoNotice(
            message: detail.historyNote!,
            margin: const EdgeInsets.only(bottom: 12),
          ),
        SizedBox(
          height: 52,
          child: TextField(
            controller: query,
            onChanged: onQueryChanged,
            style: _Dark.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: _Dark.surfaceVariant,
              hintText: 'Search token, hash, address',
              hintStyle: _Dark.sub,
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in WalletHistoryFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: filter == item,
                    label: Text(item.label),
                    onSelected: (_) => onFilterChanged(item),
                    selectedColor: _Dark.yellow.withValues(alpha: 0.16),
                    checkmarkColor: _Dark.yellow,
                    labelStyle: TextStyle(
                      color: filter == item
                          ? _Dark.yellow
                          : _Dark.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: _Dark.surface,
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text(
              'No transactions match this filter.',
              style: _Dark.sub,
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(entry.key, style: _Dark.dayHeader),
            ),
            Container(
              decoration: BoxDecoration(
                color: _Dark.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    TransactionRow(
                      tx: entry.value[i],
                      onTap: () =>
                          _showTransactionSheet(context, entry.value[i]),
                    ),
                    if (i < entry.value.length - 1)
                      const Divider(
                        color: _Dark.divider,
                        height: 1,
                        indent: 72,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class WalletAvatar extends StatelessWidget {
  const WalletAvatar({
    required this.chain,
    required this.seed,
    required this.size,
    super.key,
  });

  final WalletChain chain;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    const colors = [
      _Dark.yellow,
      Color(0xFF8A8F98),
      Color(0xFF7C6FE8),
      Color(0xFF56606B),
      Color(0xFFFF7182),
    ];
    final base = colors[seed.abs() % colors.length];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _AvatarPainter(seed: seed, base: base, colors: colors),
          ),
          Container(
            width: size * 0.37,
            height: size * 0.37,
            decoration: const BoxDecoration(
              color: _Dark.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              chain.nativeSymbol.substring(0, 1),
              style: TextStyle(
                color: _Dark.yellow,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
