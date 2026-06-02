part of '../screens/coin_detail_screen.dart';

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
