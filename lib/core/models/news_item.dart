enum NewsSentiment { bullish, bearish, important, neutral }

enum NewsFilter { all, bullish, bearish, important, hot }

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.url,
    required this.sourceTitle,
    required this.sourceDomain,
    required this.publishedAt,
    required this.currencies,
    required this.sentiment,
    required this.positiveVotes,
    required this.negativeVotes,
    required this.importantVotes,
  });

  final String id;
  final String title;
  final String url;
  final String sourceTitle;
  final String sourceDomain;
  final DateTime publishedAt;
  final List<String> currencies;
  final NewsSentiment sentiment;
  final int positiveVotes;
  final int negativeVotes;
  final int importantVotes;
}

extension NewsSentimentLabel on NewsSentiment {
  String get label => switch (this) {
    NewsSentiment.bullish => 'Bullish',
    NewsSentiment.bearish => 'Bearish',
    NewsSentiment.important => 'Important',
    NewsSentiment.neutral => 'Neutral',
  };
}

extension NewsFilterLabel on NewsFilter {
  String get label => switch (this) {
    NewsFilter.all => 'All',
    NewsFilter.bullish => 'Bullish',
    NewsFilter.bearish => 'Bearish',
    NewsFilter.important => 'Important',
    NewsFilter.hot => 'Hot',
  };
}
