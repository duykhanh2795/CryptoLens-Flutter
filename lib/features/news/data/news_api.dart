import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import 'package:cryptolens_flutter/core/config/app_config.dart';
import 'package:cryptolens_flutter/core/network/api_client.dart';
import 'package:cryptolens_flutter/core/network/network_config.dart';
import 'package:cryptolens_flutter/core/utils/json_readers.dart';
import 'package:cryptolens_flutter/features/news/domain/news_item.dart';

class NewsApi {
  NewsApi({http.Client? client}) : _client = ApiClient(client: client);

  static const _coinGeckoApiKey = AppConfig.coinGeckoProApiKey;

  static final Uri _coinGeckoNewsBase = NetworkConfig.coinGeckoNewsBase;

  static final _rssSources = <_RssSource>[
    _RssSource(
      title: 'Cointelegraph',
      url: Uri.parse('https://cointelegraph.com/rss'),
    ),
    _RssSource(title: 'Decrypt', url: Uri.parse('https://decrypt.co/feed')),
    _RssSource(
      title: 'CoinDesk',
      url: Uri.parse('https://www.coindesk.com/arc/outboundfeeds/rss/'),
    ),
  ];

  final ApiClient _client;

  Future<List<NewsItem>> fetchNews({
    NewsFilter filter = NewsFilter.all,
    String? coinId,
    String? symbol,
    int limit = 40,
  }) async {
    final news = _coinGeckoApiKey.trim().isNotEmpty
        ? await _fetchCoinGeckoNews(coinId: coinId, limit: limit)
        : await _fetchRssNews(symbol: symbol, coinId: coinId, limit: limit);

    return _applyFilters(news, filter, symbol, coinId).take(limit).toList();
  }

  Future<List<NewsItem>> _fetchCoinGeckoNews({
    required String? coinId,
    required int limit,
  }) async {
    final uri = _coinGeckoNewsBase.replace(
      queryParameters: {
        'page': '1',
        'per_page': '${limit.clamp(1, 20)}',
        'type': 'news',
        'locale': 'en',
        if (coinId != null && coinId.isNotEmpty) 'coin_id': coinId,
      },
    );
    final decoded = (await _client.getJson(
      uri,
      label: 'CoinGecko news',
      headers: {'x-cg-pro-api-key': _coinGeckoApiKey},
    )).data;
    final items = decoded is List
        ? decoded
        : decoded is Map<String, dynamic> && decoded['data'] is List
        ? decoded['data'] as List
        : const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(_fromCoinGeckoNews)
        .where((item) => item.title.isNotEmpty && item.url.isNotEmpty)
        .toList();
  }

  Future<List<NewsItem>> _fetchRssNews({
    required String? symbol,
    required String? coinId,
    required int limit,
  }) async {
    final results = <NewsItem>[];
    for (final source in _rssSources) {
      try {
        final response = await _client.get(
          source.url,
          label: source.title,
          timeout: NetworkConfig.rssTimeout,
          throwOnHttpError: false,
        );
        if (!ApiClient.isSuccessStatus(response.statusCode)) continue;
        results.addAll(_parseFeed(response.data, source));
      } catch (_) {
        continue;
      }
    }
    results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return results.take(limit * 2).toList();
  }

  List<NewsItem> _parseFeed(String xmlBody, _RssSource source) {
    final document = XmlDocument.parse(xmlBody);
    final rssItems = document.findAllElements('item').map((node) {
      final title = _childText(node, 'title');
      final url = _childText(node, 'link');
      return _fromFeedItem(
        title: title,
        url: url,
        source: source,
        publishedAt: _parseDate(
          _childText(node, 'pubDate').ifEmpty(_childText(node, 'published')),
        ),
        categories: node.findElements('category').map((e) => e.innerText),
      );
    });
    final atomItems = document.findAllElements('entry').map((node) {
      final link = _first(node.findElements('link'));
      return _fromFeedItem(
        title: _childText(node, 'title'),
        url: link?.getAttribute('href') ?? _childText(node, 'link'),
        source: source,
        publishedAt: _parseDate(
          _childText(node, 'updated').ifEmpty(_childText(node, 'published')),
        ),
        categories: node
            .findElements('category')
            .map((e) => e.getAttribute('term') ?? e.innerText),
      );
    });
    return [
      ...rssItems,
      ...atomItems,
    ].where((item) => item.title.isNotEmpty && item.url.isNotEmpty).toList();
  }

  NewsItem _fromCoinGeckoNews(Map<String, dynamic> json) {
    final title = readString(json['title']);
    final url = readString(json['url']);
    final relatedCoins =
        (json['related_coin_ids'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    return NewsItem(
      id: (json['id'] ?? url.hashCode).toString(),
      title: title,
      url: url,
      sourceTitle: readString(json['source_name'])
          .ifEmpty(readString(json['author']))
          .ifEmpty(Uri.tryParse(url)?.host ?? 'CoinGecko News'),
      sourceDomain: Uri.tryParse(url)?.host ?? '',
      publishedAt: readDateTime(json['posted_at']),
      currencies: relatedCoins.map((value) => value.toUpperCase()).toList(),
      sentiment: _inferSentiment(title),
      positiveVotes: 0,
      negativeVotes: 0,
      importantVotes: 0,
    );
  }

  NewsItem _fromFeedItem({
    required String title,
    required String url,
    required _RssSource source,
    required DateTime publishedAt,
    required Iterable<String> categories,
  }) {
    final currencies = _extractCurrencies('$title ${categories.join(' ')}');
    return NewsItem(
      id: '$url-${publishedAt.millisecondsSinceEpoch}',
      title: title.trim(),
      url: url.trim(),
      sourceTitle: source.title,
      sourceDomain: source.url.host,
      publishedAt: publishedAt,
      currencies: currencies,
      sentiment: _inferSentiment(title),
      positiveVotes: _score(title, _positiveWords),
      negativeVotes: _score(title, _negativeWords),
      importantVotes: _score(title, _importantWords),
    );
  }

  List<NewsItem> _applyFilters(
    List<NewsItem> news,
    NewsFilter filter,
    String? symbol,
    String? coinId,
  ) {
    var result = news;
    final cleanSymbol = symbol?.trim().toUpperCase();
    final cleanCoinId = coinId?.trim().toLowerCase();
    if (cleanSymbol != null && cleanSymbol.isNotEmpty) {
      result = result
          .where(
            (item) =>
                item.title.toUpperCase().contains(cleanSymbol) ||
                item.currencies.contains(cleanSymbol) ||
                (cleanCoinId != null &&
                    item.title.toLowerCase().contains(cleanCoinId)),
          )
          .toList();
    }
    return switch (filter) {
      NewsFilter.all => result,
      NewsFilter.bullish =>
        result
            .where((item) => item.sentiment == NewsSentiment.bullish)
            .toList(),
      NewsFilter.bearish =>
        result
            .where((item) => item.sentiment == NewsSentiment.bearish)
            .toList(),
      NewsFilter.important =>
        result
            .where((item) => item.sentiment == NewsSentiment.important)
            .toList(),
      NewsFilter.hot =>
        result
            .where(
              (item) => item.importantVotes > 0 || item.currencies.length > 1,
            )
            .toList(),
    };
  }

  void dispose() => _client.close();

  static String _childText(XmlElement node, String name) {
    final child = _first(node.findElements(name));
    return child?.innerText.trim() ?? '';
  }

  static DateTime _parseDate(String value) {
    if (value.trim().isEmpty) return DateTime.now();
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    for (final pattern in _datePatterns) {
      try {
        return DateFormat(pattern, 'en_US').parseUtc(value).toLocal();
      } catch (_) {
        continue;
      }
    }
    return DateTime.now();
  }

  static NewsSentiment _inferSentiment(String title) {
    final text = title.toLowerCase();
    final important = _score(text, _importantWords);
    final positive = _score(text, _positiveWords);
    final negative = _score(text, _negativeWords);
    if (important > positive && important > negative) {
      return NewsSentiment.important;
    }
    if (positive > negative) return NewsSentiment.bullish;
    if (negative > positive) return NewsSentiment.bearish;
    return NewsSentiment.neutral;
  }

  static int _score(String text, Set<String> words) {
    final lower = text.toLowerCase();
    return words.where(lower.contains).length;
  }

  static List<String> _extractCurrencies(String text) {
    final upper = text.toUpperCase();
    const symbols = {
      'BTC',
      'ETH',
      'BNB',
      'SOL',
      'XRP',
      'DOGE',
      'ADA',
      'AVAX',
      'LINK',
      'DOT',
      'MATIC',
      'TRX',
      'TON',
      'SHIB',
      'LTC',
      'BCH',
      'UNI',
      'APT',
      'ARB',
      'OP',
    };
    return [
      for (final symbol in symbols)
        if (upper.contains(RegExp('\\b$symbol\\b'))) symbol,
    ];
  }

  static T? _first<T>(Iterable<T> values) {
    final iterator = values.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class _RssSource {
  const _RssSource({required this.title, required this.url});

  final String title;
  final Uri url;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

const _positiveWords = {
  'surge',
  'rally',
  'gain',
  'gains',
  'record',
  'breakout',
  'approve',
  'approval',
  'adoption',
  'bull',
  'bullish',
  'jump',
  'soar',
  'up',
};

const _negativeWords = {
  'fall',
  'falls',
  'drop',
  'drops',
  'crash',
  'plunge',
  'hack',
  'exploit',
  'lawsuit',
  'ban',
  'bear',
  'bearish',
  'liquidation',
  'down',
  'fraud',
};

const _importantWords = {
  'sec',
  'fed',
  'etf',
  'court',
  'regulator',
  'regulation',
  'treasury',
  'white house',
  'congress',
  'hack',
  'exploit',
  'lawsuit',
};

const _datePatterns = [
  'EEE, dd MMM yyyy HH:mm:ss Z',
  'dd MMM yyyy HH:mm:ss Z',
  'EEE, dd MMM yyyy HH:mm:ss z',
];
