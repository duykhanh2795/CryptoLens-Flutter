part of '../screens/home_screen.dart';

class _AiInsightBanner extends StatelessWidget {
  const _AiInsightBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accentContainer,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Market Insight',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Get AI-powered Buy/Sell signals in Vietnamese',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.red)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.000001);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = (1 - (values[i] - minValue) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

List<double> _sparklineValues(Coin coin) {
  final base = coin.currentPrice <= 0 ? 1.0 : coin.currentPrice;
  final direction = coin.isPositive ? 1.0 : -1.0;
  final amplitude = (coin.priceChangePercent24h.abs() / 100).clamp(
    0.009,
    0.055,
  );
  final seed = coin.id.hashCode.abs();
  return List.generate(18, (index) {
    final progress = index / 17.0;
    final wave = math.sin((index + seed % 5) * 1.18) * 0.46;
    final counter = math.cos(index * 1.73 + seed % 9) * 0.24;
    final jitter = (((seed >> (index % 12)) & 7) - 3) / 15.0;
    final trend = (progress - 0.5) * direction * 0.95;
    return base * (1.0 + (wave + counter + jitter + trend) * amplitude);
  });
}

String _formatSignedPriceDelta(double value) {
  final absolute = value.abs();
  final formatted = absolute >= 1
      ? formatPrice(absolute)
      : formatPrice(absolute);
  return '${value >= 0 ? '+' : '-'}${formatted.replaceFirst(r'$', r'$')}';
}
