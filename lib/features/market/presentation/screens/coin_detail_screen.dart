import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_resolver.dart';
import 'package:cryptolens_flutter/features/market/domain/coin_holding.dart';
import 'package:cryptolens_flutter/features/market/domain/kline.dart';
import 'package:cryptolens_flutter/features/news/domain/news_item.dart';
import 'package:cryptolens_flutter/features/news/data/news_api.dart';
import 'package:cryptolens_flutter/features/market/data/market_api.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/features/portfolio/domain/portfolio_transaction.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:cryptolens_flutter/features/news/presentation/screens/news_screen.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/screens/portfolio_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_alert_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_chart_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_chrome_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_futures_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_header_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_holding_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_market_info_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_misc_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_news_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_stats_widgets.dart';
import '../market_controller.dart';

class CoinDetailScreen extends StatefulWidget {
  const CoinDetailScreen({
    required this.controller,
    required this.coin,
    super.key,
  });

  final MarketController controller;
  final Coin coin;

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  static const _intervals = <String, String>{
    '1h': '1H',
    '4h': '4H',
    '1d': '1D',
    '1w': '1W',
    '1M': '1M',
    '3M': '3M',
  };

  final _newsApi = NewsApi();
  final _portfolioStore = PortfolioStore();
  late Future<CoinDetail> _detailFuture;
  late Future<List<Kline>> _chartFuture;
  late Future<List<NewsItem>> _newsFuture;
  late Future<CoinHolding?> _holdingFuture;
  Future<FuturesMetrics>? _futuresMetricsFuture;
  String _interval = '1d';
  bool _showCandles = true;
  bool _spotSelected = true;
  late Coin _activeCoin = widget.coin;

  @override
  void initState() {
    super.initState();
    _detailFuture = widget.controller.loadCoinDetail(widget.coin);
    _chartFuture = _loadChart(_interval);
    _newsFuture = _newsApi.fetchNews(
      coinId: widget.coin.id,
      symbol: widget.coin.symbol,
      limit: 3,
    );
    _holdingFuture = _loadHolding(widget.coin);
  }

  @override
  void dispose() {
    _newsApi.dispose();
    super.dispose();
  }

  Future<List<Kline>> _loadChart(String interval) {
    final apiInterval = interval == '3M' ? '1M' : interval;
    return _spotSelected
        ? widget.controller.loadChartForInterval(widget.coin, apiInterval)
        : widget.controller.loadFuturesChartForInterval(
            widget.coin,
            apiInterval,
          );
  }

  void _setInterval(String interval) {
    if (_interval == interval) return;
    setState(() {
      _interval = interval;
      _chartFuture = _loadChart(interval);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _detailFuture = widget.controller.loadCoinDetail(widget.coin);
      _chartFuture = _loadChart(_interval);
      _futuresMetricsFuture = _spotSelected
          ? null
          : widget.controller.loadFuturesMetrics(widget.coin);
      _newsFuture = _newsApi.fetchNews(
        coinId: widget.coin.id,
        symbol: widget.coin.symbol,
        limit: 3,
      );
      _holdingFuture = _loadHolding(widget.coin);
    });
    await Future.wait<Object>([
      _detailFuture,
      _chartFuture,
      _newsFuture.catchError((_) => const <NewsItem>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoinDetailColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<CoinDetail>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  final detail = snapshot.data;
                  final coin = detail?.coin ?? widget.coin;
                  if (snapshot.connectionState != ConnectionState.done &&
                      detail == null) {
                    return const AppLoadingState(
                      height: 520,
                      color: CoinDetailColors.textSecondary,
                    );
                  }
                  if (snapshot.hasError && detail == null) {
                    return CoinDetailError(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }
                  _activeCoin = coin;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 44, 14, 110),
                    children: [
                      PriceHeader(
                        coin: coin,
                        showCandles: _showCandles,
                        spotSelected: _spotSelected,
                        onToggleMarket: _toggleMarketType,
                        onToggleChart: () =>
                            setState(() => _showCandles = !_showCandles),
                      ),
                      const SizedBox(height: 8),
                      ChartPanel(
                        chartFuture: _chartFuture,
                        showCandles: _showCandles,
                        intervals: _intervals,
                        selected: _interval,
                        onSelected: _setInterval,
                      ),
                      PerformanceRow(coin: coin),
                      const SizedBox(height: 10),
                      QuickStatsRow(coin: coin),
                      FutureBuilder<CoinHolding?>(
                        future: _holdingFuture,
                        builder: (context, holdingSnapshot) {
                          final holding = holdingSnapshot.data;
                          if (holding == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: YourHoldingSection(
                              holding: holding.withPrice(coin.currentPrice),
                              onOpenPortfolio: _openPortfolio,
                            ),
                          );
                        },
                      ),
                      if (!_spotSelected) ...[
                        const SizedBox(height: 16),
                        FuturesMetricsPanel(future: _futuresMetricsFuture),
                      ],
                      const SizedBox(height: 18),
                      if (detail != null)
                        MarketInfoSection(coin: coin, detail: detail),
                      const SizedBox(height: 24),
                      CoinNewsSection(
                        symbol: coin.symbol,
                        future: _newsFuture,
                        onSeeAll: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NewsScreen(
                              coinId: coin.id,
                              symbol: coin.symbol,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (detail != null && detail.description.isNotEmpty)
                        AboutSection(detail: detail),
                    ],
                  );
                },
              ),
            ),
            TopChrome(
              coin: _activeCoin,
              controller: widget.controller,
              onRefresh: _refresh,
              onAlert: () => _showAlertTypePicker(context, widget.coin),
              onWatchlistToggle: _toggleWatchlist,
            ),
            BuySellBar(onOpenPortfolio: _openPortfolio),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWatchlist() async {
    await widget.controller.toggleWatchlist(widget.coin.id);
    if (mounted) setState(() {});
  }

  void _toggleMarketType() {
    setState(() {
      _spotSelected = !_spotSelected;
      _chartFuture = _loadChart(_interval);
      _futuresMetricsFuture = _spotSelected
          ? null
          : widget.controller.loadFuturesMetrics(widget.coin);
    });
  }

  void _openPortfolio() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PortfolioScreen(controller: widget.controller),
      ),
    );
  }

  Future<CoinHolding?> _loadHolding(Coin activeCoin) async {
    final transactions = await _portfolioStore.load(
      coinResolver: (coinId, symbol, name, imageUrl) {
        return CoinResolver(widget.controller.coins).resolveSnapshot(
          coinId: coinId,
          symbol: symbol,
          name: name,
          imageUrl: imageUrl,
          currentPrice: activeCoin.currentPrice,
        );
      },
    );
    final coinTransactions =
        transactions.where((tx) => tx.coin.id == activeCoin.id).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (coinTransactions.isEmpty) return null;

    var quantity = 0.0;
    var costBasis = 0.0;
    var realized = 0.0;
    for (final tx in coinTransactions) {
      if (tx.type == PortfolioTransactionType.buy) {
        quantity += tx.quantity;
        costBasis += tx.quantity * tx.price + tx.fee;
      } else {
        final average = quantity <= 0 ? 0.0 : costBasis / quantity;
        final sold = math.min(quantity, tx.quantity);
        realized += sold * (tx.price - average) - tx.fee;
        quantity -= sold;
        costBasis -= average * sold;
      }
    }
    if (quantity <= 0.00000001) return null;
    final totalValue = await _loadPortfolioTotalValue(transactions);
    return CoinHolding(
      coin: activeCoin,
      quantity: quantity,
      costBasis: costBasis,
      realizedPnl: realized,
      totalPortfolioValue: totalValue,
    );
  }

  Future<double> _loadPortfolioTotalValue(
    List<PortfolioTransaction> transactions,
  ) async {
    final byCoin = <String, List<PortfolioTransaction>>{};
    for (final tx in transactions) {
      byCoin.putIfAbsent(tx.coin.id, () => []).add(tx);
    }
    var total = 0.0;
    for (final entry in byCoin.entries) {
      final liveCoin = widget.controller.coins.firstWhere(
        (coin) => coin.id == entry.key,
        orElse: () => entry.value.last.coin,
      );
      var quantity = 0.0;
      var costBasis = 0.0;
      final txs = [...entry.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final tx in txs) {
        if (tx.type == PortfolioTransactionType.buy) {
          quantity += tx.quantity;
          costBasis += tx.quantity * tx.price + tx.fee;
        } else {
          final average = quantity <= 0 ? 0.0 : costBasis / quantity;
          final sold = math.min(quantity, tx.quantity);
          quantity -= sold;
          costBasis -= average * sold;
        }
      }
      if (quantity > 0) total += quantity * liveCoin.currentPrice;
    }
    return total;
  }

  void _showAlertTypePicker(BuildContext context, Coin coin) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CoinDetailColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AlertTypePickerSheet(
        coin: coin,
        onSelected: (metric) {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlertsScreen(
                controller: widget.controller,
                prefill: AlertCoinPrefill(coin: coin, metric: metric),
              ),
            ),
          );
        },
      ),
    );
  }
}
