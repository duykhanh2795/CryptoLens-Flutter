part of '../screens/news_screen.dart';

class _SentimentBadge extends StatelessWidget {
  const _SentimentBadge({required this.sentiment});

  final NewsSentiment sentiment;

  @override
  Widget build(BuildContext context) {
    final color = switch (sentiment) {
      NewsSentiment.bullish => AppColors.green,
      NewsSentiment.bearish => AppColors.red,
      NewsSentiment.important => _NewsColors.yellow,
      NewsSentiment.neutral => _NewsColors.textSecondary,
    };
    final background = switch (sentiment) {
      NewsSentiment.bullish => AppColors.greenSurface,
      NewsSentiment.bearish => AppColors.redSurface,
      NewsSentiment.important => _NewsColors.yellow.withValues(alpha: 0.14),
      NewsSentiment.neutral => _NewsColors.surfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        sentiment.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NewsError extends StatelessWidget {
  const _NewsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _NewsColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyNews extends StatelessWidget {
  const _EmptyNews();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No news matches this filter.',
        style: TextStyle(color: _NewsColors.textSecondary),
      ),
    );
  }
}
