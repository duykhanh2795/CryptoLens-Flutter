import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/news/data/news_api.dart';
import 'package:cryptolens_flutter/features/news/domain/news_item.dart';
import 'package:cryptolens_flutter/features/news/presentation/widgets/news_common_widgets.dart';
import 'package:cryptolens_flutter/features/news/presentation/widgets/news_helpers.dart';

class NewsPreviewSection extends StatefulWidget {
  const NewsPreviewSection({required this.onSeeAll, super.key});

  final VoidCallback onSeeAll;

  @override
  State<NewsPreviewSection> createState() => _NewsPreviewSectionState();
}

class _NewsPreviewSectionState extends State<NewsPreviewSection> {
  final _api = NewsApi();
  late final Future<List<NewsItem>> _future = _api.fetchNews(limit: 5);

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'News Feed',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onSeeAll,
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  label: const Text('See All'),
                ),
              ],
            ),
          ),
          FutureBuilder<List<NewsItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const AppLoadingState(height: 72, strokeWidth: 2);
              }
              final news = snapshot.data ?? const <NewsItem>[];
              if (snapshot.hasError || news.isEmpty) {
                return const AppAsyncMessage(
                  message: 'News is unavailable right now.',
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 18),
                  alignment: Alignment.centerLeft,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < news.length; index++) ...[
                    NewsRow(item: news[index], compact: true),
                    if (index != news.length - 1)
                      const Divider(
                        color: AppColors.divider,
                        height: 1,
                        indent: 62,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class NewsRow extends StatelessWidget {
  const NewsRow({
    required this.item,
    required this.compact,
    this.dark = false,
    super.key,
  });

  final NewsItem item;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? NewsColors.textPrimary : AppColors.textPrimary;
    final secondary = dark ? NewsColors.textSecondary : AppColors.textSecondary;
    final tertiary = dark ? NewsColors.textTertiary : AppColors.textTertiary;
    return InkWell(
      onTap: () => _openUrl(context, item.url),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 10 : 14,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: compact ? 18 : 21,
              backgroundColor: dark
                  ? NewsColors.surfaceVariant
                  : AppColors.surfaceVariant,
              child: const Icon(
                Icons.newspaper_rounded,
                color: NewsColors.yellow,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primary,
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.sourceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '  Ã¢â‚¬Â¢  ${relativeTime(item.publishedAt)}',
                        style: TextStyle(
                          color: tertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (!compact && item.currencies.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.currencies.take(4).joinToString('  '),
                      style: TextStyle(
                        color: tertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            SentimentBadge(sentiment: item.sentiment),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open article.')));
    }
  }
}
