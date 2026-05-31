import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/news_item.dart';
import '../../core/services/news_api.dart';
import '../../core/theme/app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({this.coinId, this.symbol, super.key});

  final String? coinId;
  final String? symbol;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _api = NewsApi();
  final _query = TextEditingController();
  NewsFilter _filter = NewsFilter.all;
  late Future<List<NewsItem>> _future = _load();

  @override
  void dispose() {
    _query.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<List<NewsItem>> _load() {
    return _api.fetchNews(
      filter: _filter,
      coinId: widget.coinId,
      symbol: widget.symbol,
      limit: 40,
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.symbol == null
        ? 'Crypto News'
        : '${widget.symbol} News';
    return Scaffold(
      backgroundColor: _NewsColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _NewsColors.surfaceElevated,
        foregroundColor: _NewsColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh news',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: _NewsColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search news',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final filter = NewsFilter.values[index];
                return FilterChip(
                  selected: _filter == filter,
                  label: Text(filter.label),
                  onSelected: (_) {
                    setState(() {
                      _filter = filter;
                      _future = _load();
                    });
                  },
                  selectedColor: _NewsColors.yellow.withValues(alpha: 0.18),
                  checkmarkColor: _NewsColors.yellow,
                  labelStyle: TextStyle(
                    color: _filter == filter
                        ? _NewsColors.yellow
                        : _NewsColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                  backgroundColor: _NewsColors.surfaceVariant,
                  side: BorderSide.none,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: NewsFilter.values.length,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NewsItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: _NewsColors.yellow),
                  );
                }
                if (snapshot.hasError) {
                  return _NewsError(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                final query = _query.text.trim().toLowerCase();
                final news = (snapshot.data ?? const <NewsItem>[])
                    .where(
                      (item) =>
                          query.isEmpty ||
                          item.title.toLowerCase().contains(query) ||
                          item.sourceTitle.toLowerCase().contains(query) ||
                          item.currencies.any(
                            (symbol) => symbol.toLowerCase().contains(query),
                          ),
                    )
                    .toList();
                if (news.isEmpty) return const _EmptyNews();
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 10, bottom: 28),
                    itemBuilder: (context, index) =>
                        NewsRow(item: news[index], compact: false, dark: true),
                    separatorBuilder: (_, _) => const Divider(
                      color: _NewsColors.divider,
                      height: 1,
                      indent: 70,
                    ),
                    itemCount: news.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final news = snapshot.data ?? const <NewsItem>[];
              if (snapshot.hasError || news.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 18),
                  child: Text(
                    'News is unavailable right now.',
                    style: TextStyle(color: AppColors.textSecondary),
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
    final primary = dark ? _NewsColors.textPrimary : AppColors.textPrimary;
    final secondary = dark
        ? _NewsColors.textSecondary
        : AppColors.textSecondary;
    final tertiary = dark ? _NewsColors.textTertiary : AppColors.textTertiary;
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
                  ? _NewsColors.surfaceVariant
                  : AppColors.surfaceVariant,
              child: const Icon(
                Icons.newspaper_rounded,
                color: _NewsColors.yellow,
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
                        '  •  ${_relativeTime(item.publishedAt)}',
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
            _SentimentBadge(sentiment: item.sentiment),
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

String _relativeTime(DateTime date) {
  final delta = DateTime.now().difference(date);
  if (delta.inMinutes < 1) return 'now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return '${(delta.inDays / 7).floor()}w ago';
}

extension on Iterable<String> {
  String joinToString(String separator) => join(separator);
}

class _NewsColors {
  static const background = Color(0xFF050607);
  static const surfaceElevated = Color(0xFF121419);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const divider = Color(0xFF222831);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
}
