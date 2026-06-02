import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/wallet/data/wallet_indexer_service.dart';
import 'package:cryptolens_flutter/features/wallet/data/wallet_store.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/state/wallet_detail_state.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/trending_wallet_list_widgets.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_colors.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_detail_widgets.dart';

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
      backgroundColor: WalletColors.background,
      body: SafeArea(
        child: Column(
          children: [
            TrendingTopBar(
              query: _query,
              onBack: () => Navigator.of(context).maybePop(),
              onRefresh: () => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trending Addresses',
                  style: WalletColors.sectionTitle,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return TrendingWalletRow(
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
      backgroundColor: WalletColors.background,
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
                WalletDetailHero(
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
                    WalletDetailTab.assets => WalletAssetsTab(detail: detail),
                    WalletDetailTab.history => WalletHistoryTab(
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
