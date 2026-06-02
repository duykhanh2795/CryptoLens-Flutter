import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/news/domain/news_item.dart';
import 'package:cryptolens_flutter/features/news/presentation/widgets/news_helpers.dart';

class SentimentBadge extends StatelessWidget {
  const SentimentBadge({required this.sentiment, super.key});

  final NewsSentiment sentiment;

  @override
  Widget build(BuildContext context) {
    final color = switch (sentiment) {
      NewsSentiment.bullish => AppColors.green,
      NewsSentiment.bearish => AppColors.red,
      NewsSentiment.important => NewsColors.yellow,
      NewsSentiment.neutral => NewsColors.textSecondary,
    };
    final background = switch (sentiment) {
      NewsSentiment.bullish => AppColors.greenSurface,
      NewsSentiment.bearish => AppColors.redSurface,
      NewsSentiment.important => NewsColors.yellow.withValues(alpha: 0.14),
      NewsSentiment.neutral => NewsColors.surfaceVariant,
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

class NewsError extends StatelessWidget {
  const NewsError({required this.message, required this.onRetry, super.key});

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
              style: const TextStyle(color: NewsColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class EmptyNews extends StatelessWidget {
  const EmptyNews({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No news matches this filter.',
        style: TextStyle(color: NewsColors.textSecondary),
      ),
    );
  }
}
