import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cryptolens_flutter/features/news/domain/news_item.dart';
import 'package:cryptolens_flutter/features/news/data/news_api.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';

part '../widgets/news_preview_section.dart';
part '../widgets/news_common_widgets.dart';
part '../widgets/news_helpers.dart';

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
