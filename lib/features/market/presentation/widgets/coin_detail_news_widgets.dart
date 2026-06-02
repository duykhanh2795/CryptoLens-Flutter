part of '../screens/coin_detail_screen.dart';

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
