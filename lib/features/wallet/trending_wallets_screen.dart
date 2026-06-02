import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/wallet_indexer_service.dart';
import '../../core/services/wallet_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../market/market_controller.dart';

class TrendingWalletsScreen extends StatefulWidget {
  const TrendingWalletsScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<TrendingWalletsScreen> createState() => _TrendingWalletsScreenState();
}

class _TrendingWalletsScreenState extends State<TrendingWalletsScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.text.trim().toLowerCase();
    final wallets = buildTrendingWallets(widget.controller.coins)
        .where(
          (wallet) =>
              needle.isEmpty ||
              wallet.address.toLowerCase().contains(needle) ||
              wallet.label.toLowerCase().contains(needle) ||
              wallet.chain.label.toLowerCase().contains(needle),
        )
        .toList();
    return Scaffold(
      backgroundColor: _Dark.background,
      body: SafeArea(
        child: Column(
          children: [
            _TrendingTopBar(
              query: _query,
              onBack: () => Navigator.of(context).maybePop(),
              onRefresh: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Trending Addresses', style: _Dark.sectionTitle),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return _TrendingWalletRow(
                    wallet: wallet,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrendingWalletDetailScreen(
                          controller: widget.controller,
                          wallet: wallet,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrendingWalletDetailScreen extends StatefulWidget {
  const TrendingWalletDetailScreen({
    required this.controller,
    required this.wallet,
    super.key,
  });

  final MarketController controller;
  final TrendingWallet wallet;

  @override
  State<TrendingWalletDetailScreen> createState() =>
      _TrendingWalletDetailScreenState();
}

class _TrendingWalletDetailScreenState
    extends State<TrendingWalletDetailScreen> {
  final _store = WalletStore();
  final _indexer = WalletIndexerService();
  final _historyQuery = TextEditingController();
  WalletDetailTab _tab = WalletDetailTab.assets;
  WalletHistoryFilter _filter = WalletHistoryFilter.all;
  Future<TrendingWalletDetail>? _detailFuture;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _historyQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Dark.background,
      body: SafeArea(
        child: FutureBuilder<TrendingWalletDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            final fallback = buildTrendingWalletDetail(
              widget.wallet,
              widget.controller.coins,
            );
            final detail = snapshot.data ?? fallback;
            return Column(
              children: [
                _WalletDetailHero(
                  detail: detail,
                  selectedTab: _tab,
                  isAdding: _isAdding,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  onBack: () => Navigator.of(context).maybePop(),
                  onAddToWatchlist: () => unawaited(_addToWatchlist()),
                  onTabChanged: (tab) => setState(() => _tab = tab),
                ),
                Expanded(
                  child: switch (_tab) {
                    WalletDetailTab.assets => _AssetsTab(detail: detail),
                    WalletDetailTab.history => _HistoryTab(
                      detail: detail,
                      query: _historyQuery,
                      filter: _filter,
                      onFilterChanged: (value) =>
                          setState(() => _filter = value),
                      onQueryChanged: (_) => setState(() {}),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<TrendingWalletDetail> _loadDetail() async {
    final indexed = await _indexer.fetchDetail(
      wallet: widget.wallet,
      coins: widget.controller.coins,
    );
    return buildTrendingWalletDetail(
      widget.wallet,
      widget.controller.coins,
      indexedAssets: indexed.assets,
      indexedHistory: indexed.history,
      historyNote: indexed.note,
    );
  }

  Future<void> _addToWatchlist() async {
    setState(() => _isAdding = true);
    await _store.add(
      WatchedWallet(
        id: '${widget.wallet.chain.name}_${widget.wallet.address}',
        label: widget.wallet.label,
        chain: widget.wallet.chain,
        address: widget.wallet.address,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _isAdding = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to wallet watchlist')));
  }
}

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

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter({
    required this.seed,
    required this.base,
    required this.colors,
  });

  final int seed;
  final Color base;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = base;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
    final cell = size.width / 5;
    for (var x = 0; x < 5; x++) {
      for (var y = 0; y < 5; y++) {
        if (((x * 31 + y * 17 + seed) % 3) == 0) {
          paint.color = colors[(x + y + seed).abs() % colors.length].withValues(
            alpha: 0.9,
          );
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.base != base;
}

class WalletMiniChart extends StatelessWidget {
  const WalletMiniChart({required this.isPositive, super.key});

  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 92),
      painter: _MiniChartPainter(
        color: isPositive ? AppColors.green : AppColors.red,
      ),
      child: const SizedBox(height: 92, width: double.infinity),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  const _MiniChartPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      0.18,
      0.34,
      0.28,
      0.48,
      0.26,
      0.62,
      0.42,
      0.55,
      0.72,
      0.50,
      0.66,
      0.78,
    ];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = 28 + (size.width - 56) * i / max(points.length - 1, 1);
      final y = 14 + (size.height - 28) * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) =>
      oldDelegate.color != color;
}

class WalletTabs extends StatelessWidget {
  const WalletTabs({
    required this.selectedTab,
    required this.onChanged,
    super.key,
  });

  final WalletDetailTab selectedTab;
  final ValueChanged<WalletDetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in WalletDetailTab.values)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(tab),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      tab.label,
                      style: TextStyle(
                        color: selectedTab == tab
                            ? _Dark.yellow
                            : _Dark.textSecondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    color: selectedTab == tab
                        ? _Dark.yellow
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ChangePill extends StatelessWidget {
  const ChangePill({required this.percent, super.key});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final positive = percent >= 0;
    final color = positive ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '${positive ? '+' : '-'}${percent.abs().toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AssetRow extends StatelessWidget {
  const AssetRow({required this.asset, super.key});

  final WalletAsset asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          WalletAvatar(
            chain: asset.chain,
            seed: asset.symbol.hashCode,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${asset.symbol} ${_formatNative(asset.quantity)}',
                  style: _Dark.assetTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${asset.displayNetwork}  •  ${asset.valueUsd == null ? 'Value unavailable' : formatCompactUsd(asset.valueUsd!)}',
                  style: _Dark.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              formatPercent(asset.changePercent24h),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: asset.changePercent24h >= 0
                    ? AppColors.green
                    : AppColors.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              asset.priceUsd == null ? '-' : formatPrice(asset.priceUsd!),
              style: _Dark.assetTitle,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.tx, required this.onTap, super.key});

  final WalletTransaction tx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = tx.type == WalletTransactionType.received;
    final color = positive ? AppColors.green : AppColors.red;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                tx.symbol.isEmpty ? '?' : tx.symbol.substring(0, 1),
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.type.label, style: _Dark.assetTitle),
                  const SizedBox(height: 3),
                  Text(
                    tx.counterparty == null
                        ? tx.networkLabel
                        : '${positive ? 'from' : 'to'} ${shortWalletAddress(tx.counterparty!)}',
                    style: _Dark.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${positive ? '+' : '-'}${_formatNative(tx.amount)} ${tx.symbol}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                Text(
                  tx.valueUsd == null ? '' : formatPrice(tx.valueUsd!),
                  style: _Dark.sub,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WalletInfoNotice extends StatelessWidget {
  const WalletInfoNotice({
    required this.message,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final String message;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Dark.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: _Dark.notice),
    );
  }
}

enum WalletDetailTab {
  assets('ASSETS'),
  history('HISTORY');

  const WalletDetailTab(this.label);
  final String label;
}

enum WalletHistoryFilter {
  all('All'),
  received('Received'),
  sent('Sent'),
  executed('Contract'),
  token('Token');

  const WalletHistoryFilter(this.label);
  final String label;
}

Map<String, List<WalletTransaction>> _groupByDay(
  List<WalletTransaction> items,
) {
  final formatter = DateFormat('MMM dd, yyyy');
  final groups = <String, List<WalletTransaction>>{};
  for (final item in items) {
    final key = formatter.format(item.timestamp);
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups;
}

void _showTransactionSheet(BuildContext context, WalletTransaction tx) {
  final explorer = _transactionExplorerUrl(tx);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _Dark.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(tx.type.label, style: _Dark.sectionTitle),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: _Dark.textSecondary,
              ),
            ],
          ),
          _DetailRow('Amount', '${_formatNative(tx.amount)} ${tx.symbol}'),
          _DetailRow(
            'Value',
            tx.valueUsd == null ? 'Unavailable' : formatPrice(tx.valueUsd!),
          ),
          _DetailRow(
            'Time',
            DateFormat('MMM dd, yyyy HH:mm').format(tx.timestamp),
          ),
          _DetailRow('Tx hash', shortWalletAddress(tx.id)),
          _DetailRow(
            'Counterparty',
            tx.counterparty == null
                ? 'Unavailable'
                : shortWalletAddress(tx.counterparty!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: tx.id)),
                  child: const Text('Copy Hash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: tx.counterparty == null
                      ? null
                      : () => Clipboard.setData(
                          ClipboardData(text: tx.counterparty!),
                        ),
                  child: const Text('Copy Address'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: explorer == null
                  ? null
                  : () => unawaited(launchUrl(Uri.parse(explorer))),
              style: FilledButton.styleFrom(
                backgroundColor: _Dark.yellow,
                foregroundColor: const Color(0xFF1A1400),
              ),
              child: const Text('Open Explorer'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: _Dark.sub),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: _Dark.body.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String? _transactionExplorerUrl(WalletTransaction tx) {
  if (tx.id.startsWith('fallback_') || tx.id.isEmpty) return null;
  final base = switch (tx.networkLabel.toLowerCase()) {
    'ethereum' => 'https://etherscan.io/tx/',
    'polygon' => 'https://polygonscan.com/tx/',
    'bnb chain' => 'https://bscscan.com/tx/',
    _ => null,
  };
  return base == null ? null : '$base${tx.id}';
}

String _formatNative(double value) {
  if (value >= 1) {
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  if (value > 0) return value.toStringAsPrecision(4);
  return '0';
}

extension on WalletTransactionType {
  String get label => switch (this) {
    WalletTransactionType.received => 'Received',
    WalletTransactionType.sent => 'Sent',
    WalletTransactionType.executed => 'Contract',
  };
}

class _Dark {
  static const background = Color(0xFF050607);
  static const surface = Color(0xFF111112);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const border = Color(0xFF2D3035);
  static const divider = Color(0xFF24262A);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const yellow = Color(0xFFF0B90B);

  static const sectionTitle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const rowTitle = TextStyle(
    color: textPrimary,
    fontSize: 19,
    fontWeight: FontWeight.w900,
  );
  static const rowValue = TextStyle(fontSize: 16, fontWeight: FontWeight.w900);
  static const body = TextStyle(color: textPrimary, fontSize: 14);
  static const sub = TextStyle(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const notice = TextStyle(
    color: textSecondary,
    fontSize: 12,
    height: 1.35,
  );
  static const topCurrency = TextStyle(
    color: textSecondary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const topAddress = TextStyle(
    color: textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static const chainLabel = TextStyle(
    color: textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static const heroValue = TextStyle(
    color: textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w900,
  );
  static const columnHeader = TextStyle(
    color: textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const assetTitle = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );
  static const dayHeader = TextStyle(
    color: textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}
