import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/market/domain/kline.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_stats_widgets.dart';

class ChartPanel extends StatelessWidget {
  const ChartPanel({
    required this.chartFuture,
    required this.showCandles,
    required this.intervals,
    required this.selected,
    required this.onSelected,
    super.key,
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
                style: TextStyle(color: CoinDetailColors.textSecondary),
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
            color: CoinDetailColors.panelAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 42,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                color: CoinDetailColors.panelAlt,
                child: IntervalSelector(
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
      ..color = CoinDetailColors.divider.withValues(alpha: 0.55)
      ..strokeWidth = 0.7;
    final labelStyle = const TextStyle(
      color: CoinDetailColors.textTertiary,
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
          ..color = CoinDetailColors.green
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
      final color = up ? CoinDetailColors.green : CoinDetailColors.red;
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
