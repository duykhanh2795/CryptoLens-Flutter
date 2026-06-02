class Coin {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.currentPrice,
    required this.priceChangePercent24h,
    required this.priceChange24h,
    required this.marketCap,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.circulatingSupply,
    required this.rank,
    required this.lastUpdated,
  });

  final String id;
  final String symbol;
  final String name;
  final String imageUrl;
  final double currentPrice;
  final double priceChangePercent24h;
  final double priceChange24h;
  final double marketCap;
  final double volume24h;
  final double high24h;
  final double low24h;
  final double circulatingSupply;
  final int rank;
  final DateTime lastUpdated;

  bool get isPositive => priceChangePercent24h >= 0;
  String get spotSymbol => '${symbol.toUpperCase()}USDT';

  factory Coin.fromCoinGecko(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] as String? ?? '',
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      name: json['name'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      currentPrice: _number(json['current_price']),
      priceChangePercent24h: _number(json['price_change_percentage_24h']),
      priceChange24h: _number(json['price_change_24h']),
      marketCap: _number(json['market_cap']),
      volume24h: _number(json['total_volume']),
      high24h: _number(json['high_24h']),
      low24h: _number(json['low_24h']),
      circulatingSupply: _number(json['circulating_supply']),
      rank: (json['market_cap_rank'] as num?)?.toInt() ?? 0,
      lastUpdated:
          DateTime.tryParse(json['last_updated'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Coin applyTicker(PriceTicker ticker) {
    if (ticker.price <= 0) return this;
    return Coin(
      id: id,
      symbol: symbol,
      name: name,
      imageUrl: imageUrl,
      currentPrice: ticker.price,
      priceChangePercent24h: ticker.priceChangePercent,
      priceChange24h: priceChange24h,
      marketCap: marketCap,
      volume24h: ticker.volume,
      high24h: ticker.high,
      low24h: ticker.low,
      circulatingSupply: circulatingSupply,
      rank: rank,
      lastUpdated: DateTime.now(),
    );
  }
}

class PriceTicker {
  const PriceTicker({
    required this.symbol,
    required this.price,
    required this.priceChangePercent,
    required this.volume,
    required this.high,
    required this.low,
  });

  final String symbol;
  final double price;
  final double priceChangePercent;
  final double volume;
  final double high;
  final double low;

  factory PriceTicker.fromBinance(Map<String, dynamic> json) {
    return PriceTicker(
      symbol: json['symbol'] as String? ?? '',
      price: _number(json['lastPrice']),
      priceChangePercent: _number(json['priceChangePercent']),
      volume: _number(json['quoteVolume']),
      high: _number(json['highPrice']),
      low: _number(json['lowPrice']),
    );
  }
}

class CoinDetail {
  const CoinDetail({
    required this.coin,
    required this.description,
    required this.homepageUrl,
    required this.githubUrl,
    required this.allTimeHigh,
    required this.allTimeHighDate,
    required this.allTimeLow,
    required this.allTimeLowDate,
    required this.totalSupply,
    required this.maxSupply,
  });

  final Coin coin;
  final String description;
  final String homepageUrl;
  final String githubUrl;
  final double allTimeHigh;
  final String allTimeHighDate;
  final double allTimeLow;
  final String allTimeLowDate;
  final double totalSupply;
  final double maxSupply;

  factory CoinDetail.fromCoinGecko(Map<String, dynamic> json) {
    final marketData = json['market_data'] as Map<String, dynamic>? ?? {};
    final image = json['image'] as Map<String, dynamic>? ?? {};
    final links = json['links'] as Map<String, dynamic>? ?? {};
    final reposUrl = links['repos_url'] as Map<String, dynamic>? ?? {};
    final description = json['description'] as Map<String, dynamic>? ?? {};

    double usd(String key) {
      final values = marketData[key] as Map<String, dynamic>? ?? {};
      return _number(values['usd']);
    }

    String usdDate(String key) {
      final values = marketData[key] as Map<String, dynamic>? ?? {};
      return values['usd'] as String? ?? '';
    }

    final coin = Coin(
      id: json['id'] as String? ?? '',
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      name: json['name'] as String? ?? '',
      imageUrl: image['large'] as String? ?? '',
      currentPrice: usd('current_price'),
      priceChangePercent24h: _number(marketData['price_change_percentage_24h']),
      priceChange24h: 0,
      marketCap: usd('market_cap'),
      volume24h: usd('total_volume'),
      high24h: usd('high_24h'),
      low24h: usd('low_24h'),
      circulatingSupply: _number(marketData['circulating_supply']),
      rank: (json['market_cap_rank'] as num?)?.toInt() ?? 0,
      lastUpdated: DateTime.now(),
    );

    return CoinDetail(
      coin: coin,
      description: _stripHtml(description['en'] as String? ?? ''),
      homepageUrl: _firstString(links['homepage']),
      githubUrl: _firstString(reposUrl['github']),
      allTimeHigh: usd('ath'),
      allTimeHighDate: usdDate('ath_date'),
      allTimeLow: usd('atl'),
      allTimeLowDate: usdDate('atl_date'),
      totalSupply: _number(marketData['total_supply']),
      maxSupply: _number(marketData['max_supply']),
    );
  }
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String _firstString(Object? value) {
  if (value is List && value.isNotEmpty) {
    return value.whereType<String>().firstWhere(
      (item) => item.trim().isNotEmpty,
      orElse: () => '',
    );
  }
  return '';
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
