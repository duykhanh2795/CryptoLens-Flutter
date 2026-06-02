part of '../screens/coin_detail_screen.dart';

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
