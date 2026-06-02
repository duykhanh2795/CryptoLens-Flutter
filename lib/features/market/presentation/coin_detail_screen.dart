import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/market/domain/coin.dart';
import 'package:cryptolens_flutter/features/market/domain/kline.dart';
import 'package:cryptolens_flutter/features/news/domain/news_item.dart';
import 'package:cryptolens_flutter/features/news/data/news_api.dart';
import 'package:cryptolens_flutter/features/market/data/market_api.dart';
import 'package:cryptolens_flutter/features/portfolio/data/portfolio_store.dart';
import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/alerts/presentation/alerts_screen.dart';
import 'package:cryptolens_flutter/features/news/presentation/news_screen.dart';
import 'package:cryptolens_flutter/features/portfolio/presentation/portfolio_screen.dart';
import 'market_controller.dart';

class _DetailColors {
  static const background = Color(0xFF252629);
  static const panel = Color(0xFF252629);
  static const panelAlt = Color(0xFF252629);
  static const selected = Color(0xFF202124);
  static const divider = Color(0xFF26272A);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const green = Color(0xFF00C087);
  static const red = Color(0xFFFF7182);
}

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
  late Future<_CoinHolding?> _holdingFuture;
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
      backgroundColor: _DetailColors.background,
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError && detail == null) {
                    return _DetailError(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }
                  _activeCoin = coin;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 44, 14, 110),
                    children: [
                      _PriceHeader(
                        coin: coin,
                        showCandles: _showCandles,
                        spotSelected: _spotSelected,
                        onToggleMarket: _toggleMarketType,
                        onToggleChart: () =>
                            setState(() => _showCandles = !_showCandles),
                      ),
                      const SizedBox(height: 8),
                      _ChartPanel(
                        chartFuture: _chartFuture,
                        showCandles: _showCandles,
                        intervals: _intervals,
                        selected: _interval,
                        onSelected: _setInterval,
                      ),
                      _PerformanceRow(coin: coin),
                      const SizedBox(height: 10),
                      _QuickStatsRow(coin: coin),
                      FutureBuilder<_CoinHolding?>(
                        future: _holdingFuture,
                        builder: (context, holdingSnapshot) {
                          final holding = holdingSnapshot.data;
                          if (holding == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: _YourHoldingSection(
                              holding: holding.withPrice(coin.currentPrice),
                              onOpenPortfolio: _openPortfolio,
                            ),
                          );
                        },
                      ),
                      if (!_spotSelected) ...[
                        const SizedBox(height: 16),
                        _FuturesMetricsPanel(future: _futuresMetricsFuture),
                      ],
                      const SizedBox(height: 18),
                      if (detail != null)
                        _MarketInfoSection(coin: coin, detail: detail),
                      const SizedBox(height: 24),
                      _CoinNewsSection(
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
                        _AboutSection(detail: detail),
                    ],
                  );
                },
              ),
            ),
            _TopChrome(
              coin: _activeCoin,
              controller: widget.controller,
              onRefresh: _refresh,
              onAlert: () => _showAlertTypePicker(context, widget.coin),
              onWatchlistToggle: _toggleWatchlist,
            ),
            _BuySellBar(onOpenPortfolio: _openPortfolio),
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

  Future<_CoinHolding?> _loadHolding(Coin activeCoin) async {
    final transactions = await _portfolioStore.load(
      coinResolver: (coinId, symbol, name, imageUrl) {
        return widget.controller.coins.firstWhere(
          (coin) => coin.id == coinId,
          orElse: () => Coin(
            id: coinId,
            symbol: symbol,
            name: name,
            imageUrl: imageUrl,
            currentPrice: activeCoin.currentPrice,
            priceChangePercent24h: 0,
            priceChange24h: 0,
            marketCap: 0,
            volume24h: 0,
            high24h: 0,
            low24h: 0,
            circulatingSupply: 0,
            rank: 0,
            lastUpdated: DateTime.now(),
          ),
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
    return _CoinHolding(
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
      backgroundColor: _DetailColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _AlertTypePickerSheet(
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

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.coin,
    required this.controller,
    required this.onRefresh,
    required this.onAlert,
    required this.onWatchlistToggle,
  });

  final Coin coin;
  final MarketController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onAlert;
  final VoidCallback onWatchlistToggle;

  @override
  Widget build(BuildContext context) {
    final watchlisted = controller.watchlistedIds.contains(coin.id);
    return Positioned(
      left: 4,
      right: 4,
      top: 0,
      child: Container(
        height: 44,
        color: _DetailColors.background,
        child: Row(
          children: [
            _TopIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _TopIconButton(icon: Icons.refresh_rounded, onTap: onRefresh),
            _TopIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: onAlert,
            ),
            _TopIconButton(
              icon: watchlisted
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: watchlisted
                  ? _DetailColors.textPrimary
                  : _DetailColors.textSecondary,
              onTap: onWatchlistToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.color = _DetailColors.textSecondary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _AlertTypePickerSheet extends StatelessWidget {
  const _AlertTypePickerSheet({required this.coin, required this.onSelected});

  final Coin coin;
  final ValueChanged<AlertMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: _DetailColors.textTertiary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Create ${coin.symbol} alert',
              style: const TextStyle(
                color: _DetailColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _AlertTypeSheetRow(
              title: 'Price Limit',
              subtitle: 'Notify when price crosses your target',
              icon: Icons.attach_money_rounded,
              onTap: () => onSelected(AlertMetric.price),
            ),
            _AlertTypeSheetRow(
              title: 'Volume',
              subtitle: 'Track unusual 24h trading volume changes',
              icon: Icons.bar_chart_rounded,
              onTap: () => onSelected(AlertMetric.volume),
            ),
            _AlertTypeSheetRow(
              title: 'Market Cap',
              subtitle: 'Watch valuation moves by number or percent',
              icon: Icons.pie_chart_rounded,
              onTap: () => onSelected(AlertMetric.marketCap),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTypeSheetRow extends StatelessWidget {
  const _AlertTypeSheetRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _DetailColors.selected,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _DetailColors.textPrimary.withValues(
                  alpha: 0.10,
                ),
                child: Icon(icon, color: _DetailColors.textPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _DetailColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _DetailColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _DetailColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinHolding {
  const _CoinHolding({
    required this.coin,
    required this.quantity,
    required this.costBasis,
    required this.realizedPnl,
    required this.totalPortfolioValue,
  });

  final Coin coin;
  final double quantity;
  final double costBasis;
  final double realizedPnl;
  final double totalPortfolioValue;

  double get averagePrice => quantity <= 0 ? 0 : costBasis / quantity;
  double get currentValue => quantity * coin.currentPrice;
  double get unrealizedPnl => currentValue - costBasis;
  double get profitLoss => unrealizedPnl + realizedPnl;
  double get profitLossPercent =>
      costBasis <= 0 ? 0 : profitLoss / costBasis * 100;
  double get allocationPercent =>
      totalPortfolioValue <= 0 ? 0 : currentValue / totalPortfolioValue * 100;

  _CoinHolding withPrice(double price) {
    return _CoinHolding(
      coin: Coin(
        id: coin.id,
        symbol: coin.symbol,
        name: coin.name,
        imageUrl: coin.imageUrl,
        currentPrice: price,
        priceChangePercent24h: coin.priceChangePercent24h,
        priceChange24h: coin.priceChange24h,
        marketCap: coin.marketCap,
        volume24h: coin.volume24h,
        high24h: coin.high24h,
        low24h: coin.low24h,
        circulatingSupply: coin.circulatingSupply,
        rank: coin.rank,
        lastUpdated: coin.lastUpdated,
      ),
      quantity: quantity,
      costBasis: costBasis,
      realizedPnl: realizedPnl,
      totalPortfolioValue: totalPortfolioValue,
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({
    required this.coin,
    required this.showCandles,
    required this.spotSelected,
    required this.onToggleMarket,
    required this.onToggleChart,
  });

  final Coin coin;
  final bool showCandles;
  final bool spotSelected;
  final VoidCallback onToggleMarket;
  final VoidCallback onToggleChart;

  @override
  Widget build(BuildContext context) {
    final positive = coin.priceChangePercent24h >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                coin.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _DetailColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              coin.symbol,
              style: const TextStyle(
                color: _DetailColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            CircleAvatar(radius: 3, backgroundColor: _DetailColors.green),
            SizedBox(width: 4),
            Text(
              'LIVE',
              style: TextStyle(
                color: _DetailColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatPrice(coin.currentPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DetailColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPercent(coin.priceChangePercent24h),
                    style: TextStyle(
                      color: positive ? _DetailColors.green : _DetailColors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _TinyToggle(
                    label: r'$',
                    selected: spotSelected,
                    onTap: onToggleMarket,
                  ),
                  const SizedBox(width: 3),
                  _TinyToggle(
                    glyph: _TinyToggleGlyph.futures,
                    selected: !spotSelected,
                    onTap: onToggleMarket,
                  ),
                  const SizedBox(width: 3),
                  _TinyToggle(
                    glyph: _TinyToggleGlyph.candles,
                    selected: showCandles,
                    onTap: onToggleChart,
                  ),
                  const SizedBox(width: 3),
                  _TinyToggle(
                    glyph: _TinyToggleGlyph.line,
                    selected: !showCandles,
                    onTap: onToggleChart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TinyToggle extends StatelessWidget {
  const _TinyToggle({
    required this.selected,
    required this.onTap,
    this.label,
    this.glyph,
  });

  final bool selected;
  final VoidCallback onTap;
  final String? label;
  final _TinyToggleGlyph? glyph;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _DetailColors.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: glyph == null
            ? Text(
                label ?? '',
                style: TextStyle(
                  color: selected
                      ? _DetailColors.textPrimary
                      : _DetailColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              )
            : CustomPaint(
                size: const Size.square(15),
                painter: _TinyToggleGlyphPainter(
                  glyph: glyph!,
                  color: selected
                      ? _DetailColors.textPrimary
                      : _DetailColors.textTertiary,
                ),
              ),
      ),
    );
  }
}

enum _TinyToggleGlyph { futures, candles, line }

class _TinyToggleGlyphPainter extends CustomPainter {
  const _TinyToggleGlyphPainter({required this.glyph, required this.color});

  final _TinyToggleGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.35
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (glyph) {
      case _TinyToggleGlyph.futures:
        canvas.drawLine(
          Offset(size.width * 0.18, size.height * 0.36),
          Offset(size.width * 0.68, size.height * 0.36),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.56, size.height * 0.23),
          Offset(size.width * 0.70, size.height * 0.36),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.56, size.height * 0.49),
          Offset(size.width * 0.70, size.height * 0.36),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.82, size.height * 0.64),
          Offset(size.width * 0.32, size.height * 0.64),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.44, size.height * 0.51),
          Offset(size.width * 0.30, size.height * 0.64),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.44, size.height * 0.77),
          Offset(size.width * 0.30, size.height * 0.64),
          paint,
        );
      case _TinyToggleGlyph.candles:
        _drawCandle(canvas, paint, size, 0.25, 0.52, 0.30);
        _drawCandle(canvas, paint, size, 0.50, 0.38, 0.48);
        _drawCandle(canvas, paint, size, 0.75, 0.66, 0.24);
      case _TinyToggleGlyph.line:
        final path = Path()
          ..moveTo(size.width * 0.12, size.height * 0.70)
          ..lineTo(size.width * 0.34, size.height * 0.56)
          ..lineTo(size.width * 0.53, size.height * 0.62)
          ..lineTo(size.width * 0.76, size.height * 0.34)
          ..lineTo(size.width * 0.90, size.height * 0.42);
        canvas.drawPath(path, paint);
    }
  }

  void _drawCandle(
    Canvas canvas,
    Paint paint,
    Size size,
    double xFactor,
    double centerFactor,
    double bodyFactor,
  ) {
    final x = size.width * xFactor;
    final bodyHeight = size.height * bodyFactor;
    final centerY = size.height * centerFactor;
    canvas.drawLine(
      Offset(x, centerY - bodyHeight * 0.95),
      Offset(x, centerY + bodyHeight * 0.95),
      paint,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, centerY),
        width: size.width * 0.10,
        height: bodyHeight,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _TinyToggleGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.chartFuture,
    required this.showCandles,
    required this.intervals,
    required this.selected,
    required this.onSelected,
  });

  final Future<List<Kline>> chartFuture;
  final bool showCandles;
  final Map<String, String> intervals;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Kline>>(
      future: chartFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          child = const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Chart data is unavailable for this market.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _DetailColors.textSecondary),
              ),
            ),
          );
        } else {
          child = CustomPaint(
            painter: _KlineChartPainter(
              klines: snapshot.data!,
              showCandles: showCandles,
            ),
          );
        }

        return Container(
          height: 280,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _DetailColors.panelAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 42,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                color: _DetailColors.panelAlt,
                child: _IntervalSelector(
                  intervals: intervals,
                  selected: selected,
                  onSelected: onSelected,
                  compact: true,
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _KlineChartPainter extends CustomPainter {
  const _KlineChartPainter({required this.klines, required this.showCandles});

  final List<Kline> klines;
  final bool showCandles;

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty || size.isEmpty) return;
    final visible = klines.length > 64
        ? klines.sublist(klines.length - 64)
        : klines;
    final priceTop = 18.0;
    final priceHeight = size.height * 0.68;
    final volumeTop = priceTop + priceHeight + 10;
    final volumeHeight = size.height - volumeTop - 12;

    final minPrice = visible
        .map((kline) => kline.low)
        .reduce((a, b) => math.min(a, b));
    final maxPrice = visible
        .map((kline) => kline.high)
        .reduce((a, b) => math.max(a, b));
    final maxVolume = visible
        .map((kline) => kline.volume)
        .reduce((a, b) => math.max(a, b));
    final priceRange = math.max(maxPrice - minPrice, 0.000001);
    final step = size.width / visible.length;
    final candleWidth = math.max(2.0, step * 0.5);

    final gridPaint = Paint()
      ..color = _DetailColors.divider.withValues(alpha: 0.55)
      ..strokeWidth = 0.7;
    final labelStyle = const TextStyle(
      color: _DetailColors.textTertiary,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );
    for (final fraction in [0.16, 0.5, 0.84]) {
      final y = priceTop + priceHeight * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final value = maxPrice - priceRange * fraction;
      _drawText(
        canvas,
        formatPrice(value),
        Offset(size.width - 58, y - 6),
        labelStyle,
      );
    }

    if (!showCandles) {
      final path = Path();
      for (var i = 0; i < visible.length; i++) {
        final x = step * i + step / 2;
        final y =
            priceTop +
            (1 - (visible[i].close - minPrice) / priceRange) * priceHeight;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _DetailColors.green
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < visible.length; i++) {
      final kline = visible[i];
      final x = step * i + step / 2;
      final up = kline.close >= kline.open;
      final color = up ? _DetailColors.green : _DetailColors.red;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;
      final highY =
          priceTop + (1 - (kline.high - minPrice) / priceRange) * priceHeight;
      final lowY =
          priceTop + (1 - (kline.low - minPrice) / priceRange) * priceHeight;
      final openY =
          priceTop + (1 - (kline.open - minPrice) / priceRange) * priceHeight;
      final closeY =
          priceTop + (1 - (kline.close - minPrice) / priceRange) * priceHeight;

      if (showCandles) {
        canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);
        final rect = Rect.fromLTRB(
          x - candleWidth / 2,
          math.min(openY, closeY),
          x + candleWidth / 2,
          math
              .max(openY, closeY)
              .clamp(math.min(openY, closeY) + 1, size.height),
        );
        canvas.drawRect(rect, paint);
      }

      final volume = maxVolume <= 0 ? 0.0 : kline.volume / maxVolume;
      final volumeHeightPx = volume * volumeHeight;
      canvas.drawRect(
        Rect.fromLTWH(
          x - candleWidth / 2,
          volumeTop + volumeHeight - volumeHeightPx,
          candleWidth,
          volumeHeightPx,
        ),
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 64);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _KlineChartPainter oldDelegate) {
    return oldDelegate.klines != klines ||
        oldDelegate.showCandles != showCandles;
  }
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.intervals,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  final Map<String, String> intervals;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: compact ? 0 : 9),
      child: Row(
        children: [
          for (final entry in intervals.entries)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(entry.key),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  height: compact ? 30 : 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == entry.key
                        ? _DetailColors.selected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: selected == entry.key
                          ? _DetailColors.textPrimary
                          : _DetailColors.textTertiary,
                      fontSize: 10,
                      fontWeight: selected == entry.key
                          ? FontWeight.w500
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: _QuickStat(
              label: '24h High',
              value: formatPrice(coin.high24h),
              color: _DetailColors.green,
            ),
          ),
          const SizedBox(
            height: 38,
            child: VerticalDivider(color: _DetailColors.divider),
          ),
          Expanded(
            child: _QuickStat(
              label: '24h Low',
              value: formatPrice(coin.low24h),
              color: _DetailColors.red,
            ),
          ),
          const SizedBox(
            height: 38,
            child: VerticalDivider(color: _DetailColors.divider),
          ),
          Expanded(
            child: _QuickStat(
              label: 'Volume',
              value: formatCompactUsd(coin.volume24h).replaceFirst(r'$', ''),
              color: _DetailColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final today = coin.priceChangePercent24h;
    final items = [
      ('Today', today),
      ('7 days', today * 2.4),
      ('30 days', today * 4.8),
      ('90 days', today * -3.2),
      ('180 days', today * 8.4),
      ('1 year', today * -12.0),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 9, 2, 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _DetailColors.divider, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DetailColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPercent(item.$2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.$2 >= 0
                          ? _DetailColors.green.withValues(alpha: 0.78)
                          : _DetailColors.red.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _YourHoldingSection extends StatelessWidget {
  const _YourHoldingSection({
    required this.holding,
    required this.onOpenPortfolio,
  });

  final _CoinHolding holding;
  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    final profit = holding.profitLoss >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DetailColors.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Holdings',
                  style: TextStyle(
                    color: _DetailColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenPortfolio,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Portfolio',
                      style: TextStyle(
                        color: _DetailColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _DetailColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HoldingMetric(
                  label: 'Value',
                  value: formatCompactUsd(holding.currentValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoldingMetric(
                  label: 'Quantity',
                  value:
                      '${_trimHolding(holding.quantity)} ${holding.coin.symbol}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HoldingMetric(
                  label: 'Avg Buy',
                  value: formatPrice(holding.averagePrice),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoldingMetric(
                  label: 'P&L',
                  value:
                      '${holding.profitLoss >= 0 ? '+' : '-'}${formatCompactUsd(holding.profitLoss.abs())} (${holding.profitLossPercent.abs().toStringAsFixed(2)}%)',
                  valueColor: profit ? _DetailColors.green : _DetailColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HoldingMetric(
            label: 'Portfolio Allocation',
            value: '${holding.allocationPercent.toStringAsFixed(2)}%',
          ),
        ],
      ),
    );
  }
}

class _HoldingMetric extends StatelessWidget {
  const _HoldingMetric({
    required this.label,
    required this.value,
    this.valueColor = _DetailColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _DetailColors.selected,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _DetailColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuySellBar extends StatelessWidget {
  const _BuySellBar({required this.onOpenPortfolio});

  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          MediaQuery.paddingOf(context).bottom + 10,
        ),
        color: _DetailColors.background,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: onOpenPortfolio,
                  style: FilledButton.styleFrom(
                    backgroundColor: _DetailColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Track Buy',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: onOpenPortfolio,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DetailColors.red,
                    backgroundColor: _DetailColors.panel,
                    side: const BorderSide(color: _DetailColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  label: const Text(
                    'Track Sell',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _DetailColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FuturesMetricsPanel extends StatelessWidget {
  const _FuturesMetricsPanel({required this.future});

  final Future<FuturesMetrics>? future;

  @override
  Widget build(BuildContext context) {
    final metricsFuture = future;
    if (metricsFuture == null) return const SizedBox.shrink();
    return FutureBuilder<FuturesMetrics>(
      future: metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DetailColors.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Futures metrics unavailable for this symbol.',
              style: TextStyle(
                color: _DetailColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DetailColors.panel,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Futures',
                style: TextStyle(
                  color: _DetailColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickStat(
                      label: 'Mark',
                      value: formatPrice(data.markPrice),
                      color: _DetailColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _QuickStat(
                      label: 'Funding',
                      value: '${data.fundingPercent.toStringAsFixed(4)}%',
                      color: data.fundingPercent >= 0
                          ? _DetailColors.green
                          : _DetailColors.red,
                    ),
                  ),
                  Expanded(
                    child: _QuickStat(
                      label: 'Open Interest',
                      value: formatCompactNumber(data.openInterest),
                      color: _DetailColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (data.nextFundingTime != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Next funding: ${data.nextFundingTime}',
                  style: const TextStyle(
                    color: _DetailColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MarketInfoSection extends StatelessWidget {
  const _MarketInfoSection({required this.coin, required this.detail});

  final Coin coin;
  final CoinDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <_MarketInfoRowData>[
      _MarketInfoRowData(
        'Market Cap Rank',
        coin.rank > 0 ? 'NO.${coin.rank}' : 'N/A',
      ),
      _MarketInfoRowData(
        'Market Cap',
        formatCompactUsd(coin.marketCap),
        subValue: '≈${formatCompactUsd(coin.marketCap)}',
      ),
      _MarketInfoRowData('24h Volume', formatCompactUsd(coin.volume24h)),
      _MarketInfoRowData('24h High', formatPrice(coin.high24h)),
      _MarketInfoRowData('24h Low', formatPrice(coin.low24h)),
      _MarketInfoRowData(
        'All Time High',
        formatPrice(detail.allTimeHigh),
        subValue: [
          '≈${formatPrice(detail.allTimeHigh)}',
          if (_dateOnly(detail.allTimeHighDate).isNotEmpty)
            _dateOnly(detail.allTimeHighDate),
        ].join('\n'),
      ),
      _MarketInfoRowData(
        'All Time Low',
        formatPrice(detail.allTimeLow),
        subValue: [
          '≈${formatPrice(detail.allTimeLow)}',
          if (_dateOnly(detail.allTimeLowDate).isNotEmpty)
            _dateOnly(detail.allTimeLowDate),
        ].join('\n'),
      ),
      _MarketInfoRowData(
        'Circulating Supply',
        '${formatCompactNumber(coin.circulatingSupply)} ${coin.symbol}',
      ),
      _MarketInfoRowData(
        'Total Supply',
        '${formatCompactNumber(detail.totalSupply)} ${coin.symbol}',
      ),
      if (detail.maxSupply > 0)
        _MarketInfoRowData(
          'Max Supply',
          '${formatCompactNumber(detail.maxSupply)} ${coin.symbol}',
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${coin.symbol}',
            style: const TextStyle(
              color: _DetailColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < rows.length; i++) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: _InfoRow(row: rows[i]),
            ),
            if (i != rows.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}

class _MarketInfoRowData {
  const _MarketInfoRowData(this.label, this.value, {this.subValue});

  final String label;
  final String value;
  final String? subValue;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.row});

  final _MarketInfoRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            row.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DetailColors.textTertiary,
              fontSize: 14,
              height: 1.18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 154,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: _DetailColors.textPrimary,
                  fontSize: 14,
                  height: 1.18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (row.subValue != null && row.subValue!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  row.subValue!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _DetailColors.textTertiary,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _dateOnly(String raw) {
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw;
}

class _CoinNewsSection extends StatelessWidget {
  const _CoinNewsSection({
    required this.symbol,
    required this.future,
    required this.onSeeAll,
  });

  final String symbol;
  final Future<List<NewsItem>> future;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: _DetailColors.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$symbol News',
                  style: const TextStyle(
                    color: _DetailColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('More')),
            ],
          ),
          FutureBuilder<List<NewsItem>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final news = snapshot.data ?? const <NewsItem>[];
              if (snapshot.hasError || news.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Related news is unavailable right now.',
                      style: TextStyle(color: _DetailColors.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final item in news)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _DetailColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.detail});

  final CoinDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DetailColors.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${detail.coin.name}',
            style: const TextStyle(
              color: _DetailColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            detail.description,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DetailColors.textSecondary,
              height: 1.45,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.error_outline_rounded,
          size: 46,
          color: _DetailColors.red,
        ),
        const SizedBox(height: 14),
        const Text(
          'Unable to load coin detail',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _DetailColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _DetailColors.textSecondary),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

String _trimHolding(double value) {
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
