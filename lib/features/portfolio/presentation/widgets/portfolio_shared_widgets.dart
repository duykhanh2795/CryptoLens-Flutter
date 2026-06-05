import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';

class PortfolioEmptyState extends StatelessWidget {
  const PortfolioEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.height = 260,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.textTertiary, size: 64),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioChartPainter extends CustomPainter {
  const PortfolioChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 0.01);
    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          size.height -
              ((values[i] - minValue) / range * size.height * 0.72) -
              28,
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant PortfolioChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
