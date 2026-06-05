import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/news/domain/news_item.dart';
import 'package:cryptolens_flutter/features/market/presentation/widgets/coin_detail_colors.dart';

class CoinNewsSection extends StatelessWidget {
  const CoinNewsSection({
    required this.symbol,
    required this.future,
    required this.onSeeAll,
    super.key,
  });

  final String symbol;
  final Future<List<NewsItem>> future;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: CoinDetailColors.panel,
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
                    color: CoinDetailColors.textPrimary,
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
                return const AppLoadingState(
                  height: 48,
                  strokeWidth: 2,
                  color: CoinDetailColors.textSecondary,
                );
              }
              final news = snapshot.data ?? const <NewsItem>[];
              if (snapshot.hasError || news.isEmpty) {
                return const AppAsyncMessage(
                  message: 'Related news is unavailable right now.',
                  padding: EdgeInsets.only(bottom: 12),
                  alignment: Alignment.centerLeft,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: CoinDetailColors.textSecondary,
                    fontWeight: FontWeight.w700,
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
                            color: CoinDetailColors.textSecondary,
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
